section iAuditor;

BaseUrl = "https://api.safetyculture.io";

// Data Source Kind description
iAuditor = [
    Authentication = [
        Key = [
            Label = "iAuditor API Token"
        ]
    ],
    Label = Extension.LoadString("DataSourceLabel")
];

// Data Source UI publishing description
iAuditor.Publish = [
    Beta = true,
    Category = "Other",
    ButtonText = { Extension.LoadString("ButtonTitle"), Extension.LoadString("ButtonHelp") },
    LearnMoreUrl = "https://powerbi.microsoft.com/",
    SourceImage = iAuditor.Icons,
    SourceTypeImage = iAuditor.Icons
];

iAuditor.Icons = [
    Icon16 = { Extension.Contents("iAuditor16.png"), Extension.Contents("iAuditor20.png"), Extension.Contents("iAuditor24.png"), Extension.Contents("iAuditor32.png") },
    Icon32 = { Extension.Contents("iAuditor32.png"), Extension.Contents("iAuditor40.png"), Extension.Contents("iAuditor48.png"), Extension.Contents("iAuditor64.png") }
];

AuditType = type table [
    Id = text,
    ItemType = text,
    Label = text,
    Response = text,
    Comment = nullable text,
    MediaHypertextReference = text,
    Latitude = number,
    Longitude = number,
    ItemScore = nullable number,
    ItemMaxScore = nullable number,
    ItemScorePercentage = nullable number,
    Mandatory = logical,
    FailedResponse = text,
    Inactive = logical,
    ItemID = text,
    ResponseID = nullable text,
    ParentID = nullable text,
    AuditOwner = text,
    AuditAuthor = text,
    AuditName = text,
    AuditScore = number,
    AuditMaxScore = number,
    AuditScorePercentage = number,
    AuditDuration = number,
    DateStarted = datetimezone,
    DateCompleted = datetimezone,
    DateModified = datetimezone,
    ModifiedAt = datetimezone,
    CreatedAt = datetimezone,
    AuditID = text,
    TemplateID = text,
    TemplateName = text,
    TemplateAuthor = text,
    ItemCategory = nullable text,
    DocumentNo = nullable text,
    ConductedOn = datetimezone,
    PreparedBy = text,
    Location = text,
    Personnel = nullable text,
    ClientSite = nullable text
];

SchemaTable = #table({"Entity", "Type"}, {
    {"scAudits", AuditType }   
});
        
GetSchemaForEntity = (entity as text) as type => try SchemaTable{[Entity=entity]}[Type] otherwise error "Couldn't find entity: '" & entity &"'";

[DataSource.Kind="iAuditor"]
shared iAuditor.Feed = () => GetPage(Uri.Combine(BaseUrl & "/feed/", "scAudits"));

[DataSource.Kind="iAuditor", Publish="iAuditor.Publish"]
shared iAuditor.Contents = () => iAuditorNavTable(Uri.Combine(BaseUrl, "/feed/"));

iAuditorNavTable = (url as text) as table =>
    let
        entities = Table.SelectColumns(SchemaTable, {"Entity"}),
        rename = Table.RenameColumns(entities, {{"Entity", "Name"}}),
        // Add Data as a calculated column
        withData = Table.AddColumn(rename, "Data", each GetEntity(url, [Name]), type table),
        // Add ItemKind and ItemName as fixed text values
        withItemKind = Table.AddColumn(withData, "ItemKind", each "Table", type text),
        withItemName = Table.AddColumn(withItemKind, "ItemName", each "Table", type text),
        // Indicate that the node should not be expandable
        withIsLeaf = Table.AddColumn(withItemName, "IsLeaf", each true, type logical),
        // Generate the nav table
        navTable = Table.ToNavigationTable(withIsLeaf, {"Name"}, "Name", "Data", "ItemKind", "ItemName", "IsLeaf")
    in
        navTable;

GetEntity = (url as text, entity as text) as table => 
    let
        fullUrl = Uri.Combine(url, entity),
        schema = GetSchemaForEntity(entity),
        result = GetAllPagesByNextLink(fullUrl, schema),
        appliedSchema = Table.ChangeType(result, schema)
    in
        appliedSchema;

// Read all pages of data.
// After every page, we check the "NextLink" record on the metadata of the previous request.
// Table.GenerateByPage will keep asking for more pages until we return null.
GetAllPagesByNextLink = (url as text, optional schema as type) as table =>
    Table.GenerateByPage((previous) => 
        let
            // if previous is null, then this is our first page of data
            nextLink = if (previous = null) then url else Value.Metadata(previous)[NextLink]?,
            // if NextLink was set to null by the previous call, we know we have no more data
            page = if (nextLink <> null) then GetPage(nextLink, schema) else null
        in
            page
    );

GetPage = (url as text, optional schema as type) as table =>
    let
        body = MakeRequest(url),
        nextLink = GetNextLink(body[metadata]),
        data = Table.FromRecords(body[data], null, MissingField.UseNull)
    in
        data meta [NextLink = nextLink];


// In this implementation, 'response' will be the parsed metadata of the response.
// We look for the 'next_page' field and simply return null if it doesn't exist.
GetNextLink = (response) as nullable text => 
    let 
        nextPageLink = Record.FieldOrDefault(response, "next_page"),

        link = if nextPageLink <> null then Uri.Combine(BaseUrl, nextPageLink) else null
    in
        link;


MakeRequest = (url as text) =>
    let
        _url = Diagnostics.LogValue("Accessing URL", url),

        accessToken = Extension.CurrentCredential()[Key],

        headers = [
            Accept = "application/json",
            Authorization = "Bearer " & accessToken
        ],

       
        _headers = Diagnostics.LogValue("headers are", headers),

        request = Json.Document(
            Web.Contents(
                _url, 
                [ 
                    Headers = _headers, 
                    Query = [ limit = "100" ],
                    ManualCredentials = true
                ]
            )
        )
    in
        request;

// 
// Load common library functions
// 
// TEMPORARY WORKAROUND until we're able to reference other M modules
Extension.LoadFunction = (name as text) =>
    let
        binary = Extension.Contents(name),
        asText = Text.FromBinary(binary)
    in
        Expression.Evaluate(asText, #shared);

Table.ChangeType = Extension.LoadFunction("Table.ChangeType.pqm");
Table.GenerateByPage = Extension.LoadFunction("Table.GenerateByPage.pqm");
Table.ToNavigationTable = Extension.LoadFunction("Table.ToNavigationTable.pqm");

// Diagnostics module contains multiple functions. We can take the ones we need.
Diagnostics = Extension.LoadFunction("Diagnostics.pqm");
Diagnostics.LogValue = Diagnostics[LogValue];
Diagnostics.LogFailure = Diagnostics[LogFailure];
