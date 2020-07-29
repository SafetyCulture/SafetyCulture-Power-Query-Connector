// This file contains your Data Connector logic
section iAuditor;

baseURL = "https://sandpit-api.safetyculture.io";
//baseURL = "https://thepub-api.scinfradev.com";

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

[DataSource.Kind="iAuditor", Publish="iAuditor.Publish"]
shared iAuditor.Contents = () => NavTable(Uri.Combine(baseURL, "/integration/bi_tables/")) as table;

shared iAuditor.Feed = (url as text) => GetAllPagesByNextLink(url) as table;

RootEntities = {
    "inspections",
    "templates",
    "sites",
    "users"
};

NavTable = (url as text) as table =>
    let
        entitiesAsTable = Table.FromList(RootEntities, Splitter.SplitByNothing()),
        rename = Table.RenameColumns(entitiesAsTable, {{"Column1", "Name"}}),
        // Add Data as a calculated column
        withData = Table.AddColumn(rename, "Data", each iAuditor.Feed(Uri.Combine(url, [Name])), type table),
        // Add ItemKind and ItemName as fixed text values
        withItemKind = Table.AddColumn(withData, "ItemKind", each "Table", type text),
        withItemName = Table.AddColumn(withItemKind, "ItemName", each "Table", type text),
        // Indicate that the node should not be expandable
        withIsLeaf = Table.AddColumn(withItemName, "IsLeaf", each true, type logical),
        // Generate the nav table
        navTable = Table.ToNavigationTable(withIsLeaf, {"Name"}, "Name", "Data", "ItemKind", "ItemName", "IsLeaf")
    in
        navTable;

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

// Diagnostics module contains multiple functions. We can take the ones we need.
Diagnostics = Extension.LoadFunction("Diagnostics.pqm");
Diagnostics.LogValue = Diagnostics[LogValue];
Diagnostics.LogFailure = Diagnostics[LogFailure];

makeRequest = (url as text) =>
    let
        accessToken = Extension.CurrentCredential()[Key],

        headers = [
            #"Accept" = "application/json",
            #"Accept-Encoding" = "gzip",
            #"Authorization" = "Bearer " & accessToken
        ],

        _url = Diagnostics.LogValue("Accessing URL", url),

        trace1 = Diagnostics.Trace(TraceLevel.Error, "Hitting iAuditor endpoint" & url),

        request = Json.Document(
            Web.Contents(
                url, 
                [ 
                    Headers = headers, 
                    Query = [ limit = "1000" ],
                    ManualCredentials = true 
                ]
            )
        )
    in
        request;

//
// Common functions
//
Table.ToNavigationTable = (
    table as table,
    keyColumns as list,
    nameColumn as text,
    dataColumn as text,
    itemKindColumn as text,
    itemNameColumn as text,
    isLeafColumn as text
) as table =>
    let
        tableType = Value.Type(table),
        newTableType = Type.AddTableKey(tableType, keyColumns, true) meta 
        [
            NavigationTable.NameColumn = nameColumn, 
            NavigationTable.DataColumn = dataColumn,
            NavigationTable.ItemKindColumn = itemKindColumn, 
            Preview.DelayColumn = itemNameColumn, 
            NavigationTable.IsLeafColumn = isLeafColumn
        ],
        navigationTable = Value.ReplaceType(table, newTableType)
    in
        navigationTable;

// The getNextPage function takes a single argument and is expected to return a nullable table
Table.GenerateByPage = (getNextPage as function) as table =>
    let        
        listOfPages = List.Generate(
            () => getNextPage(null),            // get the first page of data
            (lastPage) => lastPage <> null,     // stop when the function returns null
            (lastPage) => getNextPage(lastPage) // pass the previous page to the next function call
        ),
        // concatenate the pages together
        tableOfPages = Table.FromList(listOfPages, Splitter.SplitByNothing(), {"Column1"}),
        firstRow = tableOfPages{0}?
    in
        // if we didn't get back any pages of data, return an empty table
        // otherwise set the table type based on the columns of the first page
        if (firstRow = null) then
            Table.FromRows({})
        else        
            Value.ReplaceType(
                Table.ExpandTableColumn(tableOfPages, "Column1", Table.ColumnNames(firstRow[Column1])),
                Value.Type(firstRow[Column1])
            );

GetPage = (url as text) as table =>
    let
        body = makeRequest(url),
        nextLink = GetNextLink(body),
        data = Table.FromRecords(body[rows], null, MissingField.UseNull)
    in
        data meta [NextLink = nextLink];

// Read all pages of data.
// After every page, we check the "NextLink" record on the metadata of the previous request.
// Table.GenerateByPage will keep asking for more pages until we return null.
GetAllPagesByNextLink = (url as text) as table =>
    Table.GenerateByPage((previous) => 
        let
            // if previous is null, then this is our first page of data
            nextLink = if (previous = null) then url else Value.Metadata(previous)[NextLink]?,
            // if NextLink was set to null by the previous call, we know we have no more data
            page = if (nextLink <> null) then GetPage(nextLink) else null
        in
            page
    );

// In this implementation, 'response' will be the parsed body of the response after the call to Json.Document.
// We look for the 'nextPageLink' field and simply return null if it doesn't exist.
GetNextLink = (response) as nullable text => 
    let 
        nextPageLink = Record.FieldOrDefault(response, "nextPageLink"),

        link = if nextPageLink <> null then Uri.Combine(baseURL, nextPageLink) else null
    in
        link;