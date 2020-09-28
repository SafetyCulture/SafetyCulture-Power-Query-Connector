section iAuditor;

BaseUrl = "https://api.safetyculture.io";

// Data Source Kind description
iAuditor = [
    Authentication = [
        Key = [
            Label = Extension.LoadString("TokenLabel")
        ]
    ],
    Label = Extension.LoadString("DataSourceLabel")
];

// Data Source UI publishing description
iAuditor.Publish = [
    Beta = true,
    Category = "Other",
    ButtonText = { Extension.LoadString("ButtonTitle"), Extension.LoadString("ButtonHelp") },
    LearnMoreUrl = "https://github.com/SafetyCulture/iAuditor-Power-Query-Connector",
    SourceImage = iAuditor.Icons,
    SourceTypeImage = iAuditor.Icons
];

iAuditor.Icons = [
    Icon16 = { Extension.Contents("iAuditor16.png"), Extension.Contents("iAuditor20.png"), Extension.Contents("iAuditor24.png"), Extension.Contents("iAuditor32.png") },
    Icon32 = { Extension.Contents("iAuditor32.png"), Extension.Contents("iAuditor40.png"), Extension.Contents("iAuditor48.png"), Extension.Contents("iAuditor64.png") }
];

GroupType = type table [
    name = text,
    id = text
];

UserType = type table [
    id = text,
    email = text,
    organisation_id = text,
    firstname = text,
    lastname = text,
    active = logical
];

GroupUserType = type table [
    user_id = text,
    group_id = text
];

TemplateType = type table [
    id = text,
    archived = logical,
    name = text,
    description = nullable text,
    created_at = datetimezone,
    modified_at = datetimezone,
    owner_name = nullable text,
    owner_id = nullable text,
    author_name = nullable text,
    author_id = nullable text
];

InspectionType = type table [
    id = text,
    name = text,
    archived = logical,
    owner_name = text,
    owner_id = text,
    author_name = text,
    author_id = text,
    score = nullable number,
    max_score = nullable number,
    score_percentage = nullable number,
    duration = nullable number,
    site_id = nullable text,
    template_id = text,
    date_started = nullable datetimezone,
    date_completed = nullable datetimezone,
    date_modified = nullable datetimezone,
    created_at = datetimezone,
    modified_at = datetimezone,
    latitude = nullable number,
    longitude = text,
    document_no = nullable text,
    prepared_by = nullable text,
    location = nullable text,
    conducted_on = nullable datetimezone,
    personnel = nullable text,
    client_site = nullable text
];

InspectionItemType = type table [
    id = text,
    item_id = text,
    audit_id = text,
    template_id = text,
    parent_id = nullable text,
    created_at = datetimezone,
    modified_at = datetimezone,
    type = text,
    category = nullable text,
    category_id = nullable text,
    parent_ids = nullable text,
    label = text,
    response = text,
    response_id = text,
    response_set_id = text,
    is_failed_response = logical,
    comment = nullable text,
    media_hypertext_reference = text,
    score = nullable number,
    max_score = nullable number,
    score_percentage = nullable number,
    mandatory = logical,
    inactive = logical,
    location_latitude = nullable number,
    location_longitude = nullable number
];

SiteType = type table [
    id = text,
    name = text,
    creator_id = text,
    organisation_id = text
];


SchemaTable = #table({"Entity", "Type"}, {
    {"users", UserType },
    {"groups", GroupType },
    {"group_users", GroupUserType },
    {"templates", TemplateType },
    {"inspections", InspectionType },
    {"inspection_items", InspectionItemType },
    {"sites", SiteType }
});
        
GetSchemaForEntity = (entity as text) as type => try SchemaTable{[Entity=entity]}[Type] otherwise error "Couldn't find entity: '" & entity &"'";

[DataSource.Kind="iAuditor", Publish="iAuditor.Publish"]
shared iAuditor.Contents = Value.ReplaceType(iAuditorImpl, iAuditorType);

iAuditorType = type function (
    orgName as (type text meta [
        Documentation.FieldCaption = "Organization name",
        Documentation.FieldDescription = "Name of your organization",
        Documentation.SampleValues = {"ACME"}
    ]))
    as table meta [
        Documentation.Name = "iAuditor by SafetyCulture"
    ];

iAuditorImpl = (orgName as text) as table => iAuditorNavTable(Uri.Combine(BaseUrl, "/feed/"));

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
        // Add function to the table
        withFunction = Table.Combine({
            withIsLeaf,
            Table.FromRecords(
                {
                    [Name = "GetInspections", Data = Value.ReplaceType(GetInspections, GetInspectionsType), ItemKind = "Function", ItemName = "Function", IsLeaf = true],
                    [Name = "GetInspectionItems", Data = Value.ReplaceType(GetInspectionItems, GetInspectionItemsType), ItemKind = "Function", ItemName = "Function", IsLeaf = true]
                },
                type table[Name = Text.Type, Data = Function.Type, ItemKind = Text.Type, ItemName = Text.Type, IsLeaf = Logical.Type]
            )
        }),
        // Generate the nav table
        navTable = Table.ToNavigationTable(withFunction, {"Name"}, "Name", "Data", "ItemKind", "ItemName", "IsLeaf")
    in
        navTable;

GetEntity = (url as text, entity as text, optional query as record) as table => 
    let
        withQuery = if (query <> null) then entity & "?" & Uri.BuildQueryString(query) else entity,
        fullUrl = Uri.Combine(url, withQuery),
        schema = GetSchemaForEntity(entity),
        result = GetAllPagesByNextLink(fullUrl, schema),
        appliedSchema = Table.ChangeType(result, schema)
    in
        if (Type.Is(schema, UserType)) then
            Table.RenameColumns(appliedSchema,{{"id", "user_id"}})
        else if (Type.Is(schema, GroupType)) then
            Table.RenameColumns(appliedSchema,{{"id", "group_id"}})
        else if (Type.Is(schema, TemplateType)) then
            Table.RenameColumns(appliedSchema,{{"id", "template_id"}})
        else if (Type.Is(schema, InspectionType)) then
            Table.RenameColumns(appliedSchema,{{"id", "audit_id"}})
        else if (Type.Is(schema, SiteType)) then
            Table.RenameColumns(appliedSchema,{{"id", "site_id"}})
        else
            appliedSchema;

GetInspections = (optional templateIds as text, optional modifiedAfter as datetimezone, optional modifiedBefore as datetimezone, optional archived as text, optional completed as text) as table =>
    let
        query = [],
        withTemplateIds = if (templateIds <> null)  then Record.AddField(query, "template", Text.Split(templateIds, ",")) else query,
        withModifiedAfter = if (modifiedAfter <> null)  then Record.AddField(withTemplateIds, "modified_after", DateTimeZone.ToText(modifiedAfter, "yyyy-MM-ddTHH:mm:ssZ")) else withTemplateIds,
        withModifiedBefore = if (modifiedBefore <> null)  then Record.AddField(query, "modified_before", DateTimeZone.ToText(withModifiedAfter, "yyyy-MM-ddTHH:mm:ssZ")) else withModifiedAfter,
        withArchived = if (archived <> null) then Record.AddField(withModifiedBefore, "archived", archived) else withModifiedBefore,
        withCompleted = if (completed <> null) then Record.AddField(withArchived, "completed", completed) else withArchived,
        table = GetEntity(Uri.Combine(BaseUrl, "/feed/"), "inspections", withCompleted)
    in
        table;

GetInspectionItems = (optional templateIds as text, optional modifiedAfter as datetimezone, optional modifiedBefore as datetimezone, optional archived as text, optional completed as text, optional includeInactive as logical) as table =>
    let
        query = [],
        withTemplateIds = if (templateIds <> null)  then Record.AddField(query, "template", Text.Split(templateIds, ",")) else query,
        withModifiedAfter = if (modifiedAfter <> null)  then Record.AddField(withTemplateIds, "modified_after", DateTimeZone.ToText(modifiedAfter, "yyyy-MM-ddTHH:mm:ssZ")) else withTemplateIds,
        withModifiedBefore = if (modifiedBefore <> null)  then Record.AddField(query, "modified_before", DateTimeZone.ToText(withModifiedAfter, "yyyy-MM-ddTHH:mm:ssZ")) else withModifiedAfter,
        withArchived = if (archived <> null) then Record.AddField(withModifiedBefore, "archived", archived) else withModifiedBefore,
        withCompleted = if (completed <> null) then Record.AddField(withArchived, "completed", completed) else withArchived,
        withIncludeInactive = if (includeInactive <> null) then Record.AddField(withCompleted, "include_inactive", Logical.ToText(includeInactive)) else withCompleted,
        table = GetEntity(Uri.Combine(BaseUrl, "/feed/"), "inspection_items", withIncludeInactive)
    in
        table;

GetInspectionsType = type function (
    optional templateIds as (type text meta [
        Documentation.FieldCaption = "Template IDs",
        Documentation.FieldDescription = "Comma separated list of IDs of the template you want to load the inspections for",
        Documentation.SampleValues = {"template_123,template_345"}
    ]),
    optional modifiedAfter as (type datetimezone meta [
        Documentation.FieldCaption = "Modified After",
        Documentation.FieldDescription = "Inspections should be last modified after this date and time"
    ]),
    optional modifiedBefore as (type datetimezone meta [
        Documentation.FieldCaption = "Modified Before",
        Documentation.FieldDescription = "Inspections should be last modified before this date and time"
    ]),
    optional archived as (type text meta [
        Documentation.FieldCaption = "Archived",
        Documentation.FieldDescription = "Flag indicating should inspections be archived, non archived, or both",
        Documentation.AllowedValues = { "true", "false", "both" }
    ]),
    optional completed as (type text meta [
        Documentation.FieldCaption = "Completed",
        Documentation.FieldDescription = "Flag indicating should inspections be completed, non completed, or both",
        Documentation.AllowedValues = { "true", "false", "both" }
    ]))
    as table;

GetInspectionItemsType = type function (
    optional templateIds as (type text meta [
        Documentation.FieldCaption = "Template IDs",
        Documentation.FieldDescription = "Comma separated list of IDs of the template you want to load the inspections for",
        Documentation.SampleValues = {"template_123,template_345"}
    ]),
    optional modifiedAfter as (type datetimezone meta [
        Documentation.FieldCaption = "Modified After",
        Documentation.FieldDescription = "Inspections should be last modified after this date and time"
    ]),
    optional modifiedBefore as (type datetimezone meta [
        Documentation.FieldCaption = "Modified Before",
        Documentation.FieldDescription = "Inspections should be last modified before this date and time"
    ]),
    optional archived as (type text meta [
        Documentation.FieldCaption = "Archived",
        Documentation.FieldDescription = "Flag indicating should inspections be archived, non archived, or both",
        Documentation.AllowedValues = { "true", "false", "both" }
    ]),
    optional completed as (type text meta [
        Documentation.FieldCaption = "Completed",
        Documentation.FieldDescription = "Flag indicating should inspections be completed, non completed, or both",
        Documentation.AllowedValues = { "true", "false", "both" }
    ]),
    optional includeInactive as (type logical meta [
        Documentation.FieldCaption = "Include Inactive",
        Documentation.FieldDescription = "Flag indicating should inactive inspection be included, or not",
        Documentation.AllowedValues = { true, false }
    ]))
    as table;

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
        limit = if (Type.Is(schema, InspectionItemType)) then 100 else 1000,
        body = MakeRequest(url, limit),
        nextLink = GetNextLink(body[metadata]),
        bodyData = if (Record.HasFields(body, "data")) then body[data] else {},

        // If we have no schema, use Table.FromRecords() instead
        // (and hope that our results all have the same fields).
        // If we have a schema, expand the record using its field names
        data =
            if (schema = null) then
                Table.FromRecords(bodyData)
            else
                let
                    // convert the list of records into a table (single column of records)
                    asTable = Table.FromList(bodyData, Splitter.SplitByNothing(), {"Column1"}),
                    fields = Record.FieldNames(Type.RecordFields(Type.TableRow(schema))),
                    expanded = Table.ExpandRecordColumn(asTable, "Column1", fields)
                in
                    expanded
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


MakeRequest = (url as text, limit as number) =>
    let
        accessToken = Extension.CurrentCredential()[Key],

        headers = [
            Accept = "application/json",
            Authorization = "Bearer " & accessToken,
            #"sc-integration-id" = "app-integrations-powerbi",
            #"sc-integration-version" = "1.0"
        ],

        failStatusCodes = {500, 502, 503, 504, 429},

        waitForResult = Value.WaitFor(
            (iteration) =>
                let
                     _url = Diagnostics.LogValue("Accessing URL", url),
                    result = Web.Contents(
                        _url, 
                        [
                            Headers = headers,
                            Query = [ limit = Number.ToText(limit) ],
                            ManualCredentials = true,
                            ManualStatusHandling = failStatusCodes
                        ]
                    ), 
                    buffered = Binary.Buffer(result),
                    status = Value.Metadata(result)[Response.Status],
                    _status = Diagnostics.LogValue("Request finished with status", status),
                    actualResult = if List.Contains(failStatusCodes, _status) then null else buffered
                in
                    actualResult,
            (iteration) => #duration(0, 0, 0, Number.Power(2, iteration)*2),
            6), // retry after 4, 8, 16 and 32 seconds

        request = Json.Document(waitForResult)
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
Value.WaitFor = Extension.LoadFunction("Value.WaitFor.pqm");

// Diagnostics module contains multiple functions. We can take the ones we need.
Diagnostics = Extension.LoadFunction("Diagnostics.pqm");
Diagnostics.LogValue = Diagnostics[LogValue];
Diagnostics.LogFailure = Diagnostics[LogFailure];
