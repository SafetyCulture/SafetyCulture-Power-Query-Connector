section SafetyCulture;

// Base API Url
BaseUrl = "https://api.safetyculture.io";

// OAuth values
OAuthClientID = "2b7ZjQFAKzWubEChzMIDcVfDdjocrfzv";
OAuthBaseUrl = "https://api.safetyculture.com/authorization/global/v1";
OAuthLogoutUrl = "http://auth.safetyculture.com/v2/logout";
OAuthRedirectUrl = "https://oauth.powerbi.com/views/oauthredirect.html";

// Crypto functions for Authorization Code + PKCE
GenerateRandomBytes = (count as number) =>
    let
        RandomBit = () => Number.Round(Number.RandomBetween(0, 255)),
        list = List.Generate(
            () => [x = RandomBit(), y = {}], each List.Count([y]) < count, each [x = RandomBit(), y = [y] & {x}],
            each
                [x]
        ),
        binary = Binary.FromList(list)
    in
        binary;

Base64Encode = (str as binary) =>
    let
        unescaped = Binary.ToText(str, BinaryEncoding.Base64),
        text = Text.Replace(Text.Replace(Text.Replace(unescaped, "+", "-"), "/", "_"), "=", "")
    in
        text;

StartLogin = (resourceUrl, state, display) =>
    let
        codeVerifier = Base64Encode(GenerateRandomBytes(32)),
        codeChallenge = Base64Encode(
            Crypto.CreateHash(CryptoAlgorithm.SHA256, Text.ToBinary(codeVerifier, TextEncoding.Ascii))
        ),
        AuthorizeUrl = OAuthBaseUrl
            & "/auth/authorize?"
            & Uri.BuildQueryString(
                [
                    client_id = OAuthClientID,
                    response_type = "code",
                    code_challenge_method = "S256",
                    code_challenge = codeChallenge,
                    state = state,
                    redirect_uri = OAuthRedirectUrl
                ]
            )
    in
        [
            LoginUri = AuthorizeUrl,
            CallbackUri = OAuthRedirectUrl,
            WindowHeight = 740,
            WindowWidth = 760,
            // Need to roundtrip this value to FinishLogin
            Context = codeVerifier
        ];

// The code verifier will be passed in through the context parameter.
FinishLogin = (context, callbackUri, state) =>
    let
        Parts = Uri.Parts(callbackUri)[Query]
    in
        TokenMethod(Parts[code], "authorization_code", context);

Refresh = (resourceUrl, refresh_token) => TokenMethod(refresh_token, "refresh_token");

Logout = (accessToken) => OAuthLogoutUrl;

// Verifier is optional to support both the original FinishLogin call
// (which has a verifier) and the Refresh call (which does not).
TokenMethod = (code, grant_type, optional verifier) =>
    let
        codeVerifier = if (verifier <> null) then [code_verifier = verifier] else [],
        codeParameter = if (grant_type = "authorization_code") then [code = code] else [refresh_token = code],
        query = codeVerifier
            & codeParameter
            & [
                client_id = OAuthClientID,
                grant_type = grant_type,
                redirect_uri = OAuthRedirectUrl
            ],
        // Set this if your API returns a non-2xx status for login failures
        ManualHandlingStatusCodes = {400, 403},
        Response = Web.Contents(
            OAuthBaseUrl & "/authorization:GetAccessToken",
            [
                Content = Json.FromValue(query),
                Headers = [
                    #"Content-type" = "application/json",
                    #"Accept" = "application/json"
                ],
                ManualStatusHandling = ManualHandlingStatusCodes
            ]
        ),
        Parts = Json.Document(Response)
    in
        // check for error in response
        if (Parts[error]? <> null) then
            error Error.Record(Parts[error], Parts[message]?)
        else
            Parts;

// Data Source Kind description
iAuditor = [
    TestConnection = (dataSourcePath) =>
        let
            json = Json.Document(dataSourcePath), orgName = json[orgName]
        in
            {"iAuditor.Contents", orgName},
    Authentication = [
        OAuth = [
            StartLogin = StartLogin,
            FinishLogin = FinishLogin,
            Refresh = Refresh,
            Logout = Logout,
            Label = "Log in to your account"
        ],
        Key = [
            Label = Extension.LoadString("TokenLabel")
        ]
    ],
    Label = Extension.LoadString("DataSourceLabel")
];

// Data Source UI publishing description
iAuditor.Publish = [
    Beta = false,
    Category = "Other",
    ButtonText = {Extension.LoadString("ButtonTitle"), Extension.LoadString("ButtonHelp")},
    LearnMoreUrl = "https://github.com/SafetyCulture/SafetyCulture-Power-Query-Connector",
    SourceImage = iAuditor.Icons,
    SourceTypeImage = iAuditor.Icons
];

iAuditor.Icons = [
    Icon16 = {
        Extension.Contents("SafetyCulture16.png"),
        Extension.Contents("SafetyCulture20.png"),
        Extension.Contents("SafetyCulture24.png"),
        Extension.Contents("SafetyCulture32.png")
    },
    Icon32 = {
        Extension.Contents("SafetyCulture32.png"),
        Extension.Contents("SafetyCulture40.png"),
        Extension.Contents("SafetyCulture48.png"),
        Extension.Contents("SafetyCulture64.png")
    }
];

GroupType = type table [name = text, id = text, organisation_id = text];

UserType = type table [
    id = text,
    email = text,
    organisation_id = text,
    firstname = text,
    lastname = text,
    active = logical,
    last_seen_at = nullable datetimezone,
    seat_type = text
];

GroupUserType = type table [user_id = text, group_id = text, organisation_id = text];

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
    author_id = nullable text,
    organisation_id = text
];

TemplatePermissionType = type table [
    id = text, template_id = text, permission = text, assignee_type = text, assignee_id = text, organisation_id = text
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
    template_name = text,
    organisation_id = text,
    date_started = nullable datetimezone,
    date_completed = nullable datetimezone,
    date_modified = nullable datetimezone,
    created_at = datetimezone,
    modified_at = datetimezone,
    latitude = nullable number,
    longitude = nullable text,
    document_no = nullable text,
    prepared_by = nullable text,
    location = nullable text,
    conducted_on = nullable datetimezone,
    personnel = nullable text,
    client_site = nullable text,
    web_report_link = nullable text,
    asset_id = nullable text
];

InspectionItemType = type table [
    id = text,
    item_id = text,
    audit_id = text,
    item_index = number,
    template_id = text,
    organisation_id = text,
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
    media_files = nullable text,
    media_ids = nullable text,
    media_hypertext_reference = nullable text,
    score = nullable number,
    max_score = nullable number,
    score_percentage = nullable number,
    combined_score = nullable number,
    combined_max_score = nullable number,
    combined_score_percentage = nullable number,
    mandatory = logical,
    inactive = logical,
    location_latitude = nullable number,
    location_longitude = nullable number,
    primeelement_id = nullable text,
    primeelement_index = nullable number
];

SiteType = type table [
    id = text,
    name = text,
    creator_id = text,
    organisation_id = text,
    deleted = logical,
    site_uuid = text,
    meta_label = text,
    parent_id = text
];

SiteMemberType = type table [site_id = text, member_id = text];

ScheduleType = type table [
    id = text,
    description = text,
    recurrence = text,
    duration = text,
    modified_at = datetimezone,
    from_date = datetimezone,
    to_date = nullable datetimezone,
    start_time_hour = number,
    start_time_minute = number,
    all_must_complete = logical,
    status = text,
    timezone = text,
    can_late_submit = logical,
    site_id = nullable text,
    template_id = nullable text,
    organisation_id = text,
    creator_user_id = nullable text,
    asset_id = nullable text
];

ScheduleAssigneeType = type table [
    id = text, schedule_id = text, assignee_id = text, organisation_id = text, type = text, name = text
];

ScheduleOccurrenceType = type table [
    id = text,
    schedule_id = text,
    occurrence_id = text,
    user_id = text,
    template_id = text,
    organisation_id = text,
    start_time = datetimezone,
    due_time = datetimezone,
    miss_time = datetimezone,
    occurrence_status = text,
    assignee_status = text,
    audit_id = nullable text,
    completed_at = nullable datetimezone,
    note = nullable text
];

ActionType = type table [
    id = text,
    title = text,
    site_id = nullable text,
    description = nullable text,
    priority = text,
    status = text,
    organisation_id = text,
    due_date = nullable datetimezone,
    creator_user_id = nullable text,
    creator_user_name = nullable text,
    created_at = datetimezone,
    modified_at = datetimezone,
    template_id = nullable text,
    audit_id = nullable text,
    audit_title = nullable text,
    audit_item_id = nullable text,
    audit_item_label = nullable text,
    completed_at = nullable datetimezone,
    action_label = nullable text,
    asset_id = nullable text,
    unique_id = text
];

ActionAssigneeType = type table [
    id = text, action_id = text, assignee_id = text, name = nullable text, organisation_id = text, type = text
];

IssueAssigneesType = type table [
    id = text,
    issue_id = text,
    assignee_id = text,
    name = nullable text,
    organisation_id = text,
    modified_at = datetimezone,
    type = text
];

ActionTimelineItemType = type table [
    id = text,
    task_id = text,
    organisation_id = text,
    task_creator_id = text,
    task_creator_name = text,
    timestamp = datetimezone,
    creator_id = text,
    creator_name = text,
    item_type = text,
    item_data = text
];

IssueType = type table [
    id = text,
    title = nullable text,
    description = nullable text,
    creator_id = text,
    creator_user_name = nullable text,
    created_at = datetimezone,
    due_at = nullable datetimezone,
    priority = nullable text,
    status = nullable text,
    template_id = nullable text,
    inspection_id = nullable text,
    inspection_name = nullable text,
    site_id = nullable text,
    site_name = nullable text,
    location_name = nullable text,
    category_id = nullable text,
    category_label = nullable text,
    modified_at = nullable datetimezone,
    completed_at = nullable datetimezone,
    asset_id = nullable text,
    unique_id = nullable text
];

IssueTimelineItemType = type table [
    id = text,
    task_id = text,
    organisation_id = text,
    task_creator_id = text,
    task_creator_name = text,
    timestamp = datetimezone,
    creator_id = text,
    creator_name = text,
    item_type = text,
    item_data = text
];

AssetType = type table [
    id = text,
    code = text,
    type_id = text,
    type_name = text,
    fields = text,
    created_at = datetimezone,
    modified_at = datetimezone,
    site_id = nullable text,
    state = text
];

CourseProgressType = type table [
    opened_at = nullable datetimezone,
    completed_at = nullable datetimezone,
    total_lessons = number,
    completed_lessons = number,
    course_id = text,
    course_external_id = text,
    course_title = text,
    user_email = text,
    user_first_name = text,
    user_last_name = text,
    user_id = text,
    user_external_id = text,
    progress_percent = number,
    score = number,
    due_at = nullable datetimezone
];

SchemaTable = #table(
    {"Entity", "Type", "Group"},
    {
        {"users", UserType, ""},
        {"groups", GroupType, ""},
        {"group_users", GroupUserType, ""},
        {"templates", TemplateType, ""},
        {"template_permissions", TemplatePermissionType, ""},
        {"inspections", InspectionType, ""},
        {"inspection_items", InspectionItemType, ""},
        {"sites", SiteType, ""},
        {"site_members", SiteMemberType, ""},
        {"schedules", ScheduleType, "Schedule"},
        {"schedule_assignees", ScheduleAssigneeType, "Schedule"},
        {"schedule_occurrences", ScheduleOccurrenceType, "Schedule"},
        {"actions", ActionType, "Actions"},
        {"action_assignees", ActionAssigneeType, "Actions"},
        {"action_timeline_items", ActionTimelineItemType, "Actions"},
        {"issues", IssueType, "Issues"},
        {"issue_timeline_items", IssueTimelineItemType, "Issues"},
        {"assets", AssetType, "Assets"},
        {"training-course-progress", CourseProgressType, "Training"},
        {"issue_assignees", IssueAssigneesType, "Issues"}
    }
);

GetSchemaForEntity = (entity as text) as type =>
    try SchemaTable{[Entity = entity]}[Type] otherwise error "Couldn't find entity: '" & entity & "'";

[DataSource.Kind = "iAuditor", Publish = "iAuditor.Publish"]
shared iAuditor.Contents = Value.ReplaceType(SafetyCultureImpl, SafetyCultureType);

SafetyCultureType = type function (
    orgName as (
        type text meta [
            Documentation.FieldCaption = "Organization name",
            Documentation.FieldDescription = "Name of your organization",
            Documentation.SampleValues = {"ACME"}
        ]
    )
) as table meta [
    Documentation.Name = "SafetyCulture"
];

SafetyCultureImpl = (orgName as text) as table => SafetyCultureNavTable();

SafetyCultureNavTable = () as table =>
    let
        groups = Table.Column(SchemaTable, "Group"),
        distinctGroups = List.Distinct(groups),
        nonEmptyGroups = List.Select(distinctGroups, each _ <> ""),
        rename = Table.FromList(nonEmptyGroups, null, {"Name"}),
        withData = Table.AddColumn(rename, "Data", each CreateNavTable([Name]), type table),
        withItemKind = Table.AddColumn(withData, "ItemKind", each "Folder", type text),
        withItemName = Table.AddColumn(withItemKind, "ItemName", each "Folder", type text),
        withIsLeaf = Table.AddColumn(withItemName, "IsLeaf", each false, type logical),
        withNoGroups = Table.Combine({withIsLeaf, CreateNavTable("")}),
        navTable = Table.ToNavigationTable(withNoGroups, {"Name"}, "Name", "Data", "ItemKind", "ItemName", "IsLeaf")
    in
        navTable;

CreateNavTable = (group as text) as table =>
    let
        entities = Table.SelectRows(SchemaTable, each [Group] = group),
        entityNames = Table.SelectColumns(entities, {"Entity"}),
        rename = Table.RenameColumns(entityNames, {{"Entity", "Name"}}),
        withURI = if (group = "Training") then "/training/v1/feed/" else "/feed/",
        // Add Data as a calculated column
        withData = Table.AddColumn(
            rename, "Data", each GetEntity(Uri.Combine(BaseUrl, withURI), [Name]), type table
        ),
        // Add ItemKind and ItemName as fixed text values
        withItemKind = Table.AddColumn(withData, "ItemKind", each "Table", type text),
        withItemName = Table.AddColumn(withItemKind, "ItemName", each "Table", type text),
        // Indicate that the node should not be expandable
        withIsLeaf = Table.AddColumn(withItemName, "IsLeaf", each true, type logical),
        // Add function to the table
        withFunction =
            if (group = "") then
                Table.Combine(
                    {
                        withIsLeaf,
                        Table.FromRecords(
                            {
                                [
                                    Name = "GetInspections",
                                    Data = Value.ReplaceType(GetInspections, GetInspectionsType),
                                    ItemKind = "Function",
                                    ItemName = "Function",
                                    IsLeaf = true
                                ],
                                [
                                    Name = "GetInspectionItems",
                                    Data = Value.ReplaceType(GetInspectionItems, GetInspectionItemsType),
                                    ItemKind = "Function",
                                    ItemName = "Function",
                                    IsLeaf = true
                                ],
                                [
                                    Name = "GetSites",
                                    Data = Value.ReplaceType(GetSites, GetSitesType),
                                    ItemKind = "Function",
                                    ItemName = "Function",
                                    IsLeaf = true
                                ],
                                [
                                    Name = "GetScheduleOccurrences",
                                    Data = Value.ReplaceType(GetScheduleOccurrences, GetScheduleOccurrencesType),
                                    ItemKind = "Function",
                                    ItemName = "Function",
                                    IsLeaf = true
                                ]
                            },
                            type table [
                                Name = Text.Type,
                                Data = Function.Type,
                                ItemKind = Text.Type,
                                ItemName = Text.Type,
                                IsLeaf = Logical.Type
                            ]
                        )
                    }
                )
            else
                withIsLeaf,
        // Generate the nav table
        navTable = Table.ToNavigationTable(withFunction, {"Name"}, "Name", "Data", "ItemKind", "ItemName", "IsLeaf")
    in
        navTable;

GetEntity = (url as text, entity as text, optional query as record) as table =>
    let
        now = DateTimeZone.ToText(DateTimeZone.UtcNow(), "yyyy-MM-ddTHH:mm:ss"),
        withQuery = 
            if (query <> null) 
                then entity & "?" & Uri.BuildQueryString(query)
            else if (query = null and entity = "training-course-progress")
                then entity & "?completion_status=COMPLETION_STATUS_COMPLETED&limit=100"
            else if (query = null and entity = "inspection_items")
                then entity & "?modified_before="&now&"Z"                
            else entity,
        
        fullUrl = Uri.Combine(url, withQuery),
        schema = GetSchemaForEntity(entity),
        result = GetAllPagesByNextLink(fullUrl, schema),
        appliedSchema = Table.ChangeType(result, schema)
    in
        if (Type.Is(schema, UserType)) then
            Table.RenameColumns(appliedSchema, {{"id", "user_id"}})
        else if (Type.Is(schema, GroupType)) then
            Table.RenameColumns(appliedSchema, {{"id", "group_id"}})
        else if (Type.Is(schema, TemplateType)) then
            Table.RenameColumns(appliedSchema, {{"id", "template_id"}})
        else if (Type.Is(schema, InspectionType)) then
            Table.RenameColumns(appliedSchema, {{"id", "audit_id"}})
        else if (Type.Is(schema, SiteType)) then
            Table.RenameColumns(appliedSchema, {{"id", "site_id"}})
        else if (Type.Is(schema, ScheduleType)) then
            Table.RenameColumns(appliedSchema, {{"id", "schedule_id"}})
        else if (Type.Is(schema, ActionType)) then
            Table.RenameColumns(appliedSchema, {{"id", "action_id"}})
        else if (Type.Is(schema, ActionTimelineItemType)) then
            Table.RenameColumns(appliedSchema, {{"id", "item_id"}})
        else if (Type.Is(schema, IssueType)) then
            Table.RenameColumns(appliedSchema, {{"id", "issue_id"}})
        else if (Type.Is(schema, IssueTimelineItemType)) then
            Table.RenameColumns(appliedSchema, {{"id", "item_id"}})
        else if (Type.Is(schema, AssetType)) then
            Table.RenameColumns(appliedSchema, {{"id", "asset_id"}})

        else
            appliedSchema;

GetInspections = (
    optional templateIds as text,
    optional modifiedAfter as datetimezone,
    optional modifiedBefore as datetimezone,
    optional archived as text,
    optional completed as text
) as table =>
    let
        query = [],
        withTemplateIds =
            if (templateIds <> null) then
                Record.AddField(query, "template", Text.Split(templateIds, ","))
            else
                query,
        withModifiedAfter =
            if (modifiedAfter <> null) then
                Record.AddField(
                    withTemplateIds, "modified_after", DateTimeZone.ToText(modifiedAfter, "yyyy-MM-ddTHH:mm:ssZ")
                )
            else
                withTemplateIds,
        withModifiedBefore =
            if (modifiedBefore <> null) then
                Record.AddField(
                    withModifiedAfter, "modified_before", DateTimeZone.ToText(modifiedBefore, "yyyy-MM-ddTHH:mm:ssZ")
                )
            else
                withModifiedAfter,
        withArchived =
            if (archived <> null) then
                Record.AddField(withModifiedBefore, "archived", archived)
            else
                withModifiedBefore,
        withCompleted =
            if (completed <> null) then
                Record.AddField(withArchived, "completed", completed)
            else
                withArchived,
        table = GetEntity(Uri.Combine(BaseUrl, "/feed/"), "inspections", withCompleted)
    in
        table;

GetInspectionItems = (
    optional templateIds as text,
    optional modifiedAfter as datetimezone,
    optional modifiedBefore as datetimezone,
    optional archived as text,
    optional completed as text,
    optional includeInactive as logical
) as table =>
    let
        query = [],
        withTemplateIds =
            if (templateIds <> null) then
                Record.AddField(query, "template", Text.Split(templateIds, ","))
            else
                query,
        withModifiedAfter =
            if (modifiedAfter <> null) then
                Record.AddField(
                    withTemplateIds, "modified_after", DateTimeZone.ToText(modifiedAfter, "yyyy-MM-ddTHH:mm:ssZ")
                )
            else
                withTemplateIds,
        withModifiedBefore =
            if (modifiedBefore <> null) then
                Record.AddField(
                    withModifiedAfter, "modified_before", DateTimeZone.ToText(modifiedBefore, "yyyy-MM-ddTHH:mm:ssZ")
                )
            else
                withModifiedAfter,
        withArchived =
            if (archived <> null) then
                Record.AddField(withModifiedBefore, "archived", archived)
            else
                withModifiedBefore,
        withCompleted =
            if (completed <> null) then
                Record.AddField(withArchived, "completed", completed)
            else
                withArchived,
        withIncludeInactive =
            if (includeInactive <> null) then
                Record.AddField(withCompleted, "include_inactive", Logical.ToText(includeInactive))
            else
                withCompleted,
        table = GetEntity(Uri.Combine(BaseUrl, "/feed/"), "inspection_items", withIncludeInactive)
    in
        table;

GetSites = (optional includeDeleted as logical, optional includeFullHierarchy as logical) as table =>
    let
        query = [],
        withIncludeDeleted =
            if (includeDeleted <> null) then
                Record.AddField(query, "include_deleted", Logical.ToText(includeDeleted))
            else
                query,
        withIncludeFullHierarchy =
            if (includeFullHierarchy <> null) then
                Record.AddField(
                    withIncludeDeleted, "show_only_leaf_nodes", Logical.ToText(includeFullHierarchy <> true)
                )
            else
                withIncludeDeleted,
        table = GetEntity(Uri.Combine(BaseUrl, "/feed/"), "sites", withIncludeFullHierarchy)
    in
        table;

GetIssues = () as table => let query = [], table = GetEntity(Uri.Combine(BaseUrl, "/feed/"), "issues") in table;

GetAssets = () as table => let query = [], table = GetEntity(Uri.Combine(BaseUrl, "/feed/"), "assets") in table;

GetActionTimelineItems = () as table => let query = [], table = GetEntity(
    Uri.Combine(BaseUrl, "/feed/"), "action_timeline_items") in table;

GetIssueTimelineItems = () as table => let query = [], table = GetEntity(
    Uri.Combine(BaseUrl, "/feed/"), "issue_timeline_items") in table;

GetIssueAssigneesItems = () as table => let query = [], table = GetEntity(
    Uri.Combine(BaseUrl, "/feed/"), "issue_assignees") in table;

GetScheduleOccurrences = (
    optional templateIds as text, optional startDate as datetimezone, optional endDate as datetimezone
) as table =>
    let
        query = [],
        withTemplateIds =
            if (templateIds <> null) then
                Record.AddField(query, "template", Text.Split(templateIds, ","))
            else
                query,
        withStartDate =
            if (startDate <> null) then
                Record.AddField(
                    withTemplateIds, "start_date", DateTimeZone.ToText(startDate, "yyyy-MM-ddTHH:mm:ssZ")
                )
            else
                withTemplateIds,
        withEndDate =
            if (endDate <> null) then
                Record.AddField(withStartDate, "end_date", DateTimeZone.ToText(endDate, "yyyy-MM-ddTHH:mm:ssZ"))
            else
                withStartDate,
        table = GetEntity(Uri.Combine(BaseUrl, "/feed/"), "schedule_occurrences", withEndDate)
    in
        table;

GetInspectionsType = type function (
    optional templateIds as (
        type text meta [
            Documentation.FieldCaption = "Template IDs",
            Documentation.FieldDescription = "Comma separated list of IDs of the template you want to load the inspections for",
            Documentation.SampleValues = {"template_123,template_345"}
        ]
    ),
    optional modifiedAfter as (
        type datetimezone meta [
            Documentation.FieldCaption = "Modified After",
            Documentation.FieldDescription = "Inspections should be last modified after this date and time"
        ]
    ),
    optional modifiedBefore as (
        type datetimezone meta [
            Documentation.FieldCaption = "Modified Before",
            Documentation.FieldDescription = "Inspections should be last modified before this date and time"
        ]
    ),
    optional archived as (
        type text meta [
            Documentation.FieldCaption = "Archived",
            Documentation.FieldDescription = "Flag indicating should inspections be archived, non archived, or both",
            Documentation.AllowedValues = {"true", "false", "both"}
        ]
    ),
    optional completed as (
        type text meta [
            Documentation.FieldCaption = "Completed",
            Documentation.FieldDescription = "Flag indicating should inspections be completed, non completed, or both",
            Documentation.AllowedValues = {"true", "false", "both"}
        ]
    )
) as table;

GetInspectionItemsType = type function (
    optional templateIds as (
        type text meta [
            Documentation.FieldCaption = "Template IDs",
            Documentation.FieldDescription = "Comma separated list of IDs of the template you want to load the inspections for",
            Documentation.SampleValues = {"template_123,template_345"}
        ]
    ),
    optional modifiedAfter as (
        type datetimezone meta [
            Documentation.FieldCaption = "Modified After",
            Documentation.FieldDescription = "Inspections should be last modified after this date and time"
        ]
    ),
    optional modifiedBefore as (
        type datetimezone meta [
            Documentation.FieldCaption = "Modified Before",
            Documentation.FieldDescription = "Inspections should be last modified before this date and time"
        ]
    ),
    optional archived as (
        type text meta [
            Documentation.FieldCaption = "Archived",
            Documentation.FieldDescription = "Flag indicating should inspections be archived, non archived, or both",
            Documentation.AllowedValues = {"true", "false", "both"}
        ]
    ),
    optional completed as (
        type text meta [
            Documentation.FieldCaption = "Completed",
            Documentation.FieldDescription = "Flag indicating should inspections be completed, non completed, or both",
            Documentation.AllowedValues = {"true", "false", "both"}
        ]
    ),
    optional includeInactive as (
        type logical meta [
            Documentation.FieldCaption = "Include Inactive",
            Documentation.FieldDescription = "Flag indicating should inactive inspection be included, or not",
            Documentation.AllowedValues = {true, false}
        ]
    )
) as table;

GetSitesType = type function (
    optional includeDeleted as (
        type logical meta [
            Documentation.FieldCaption = "Include Deleted",
            Documentation.FieldDescription = "Flag indicating should deleted sites be included, or not",
            Documentation.AllowedValues = {true, false}
        ]
    ),
    optional includeFullHierarchy as (
        type logical meta [
            Documentation.FieldCaption = "Include Full Hierarchy",
            Documentation.FieldDescription = "Flag indicating whether to include full sites hierarchy, e.g. Areas, Regions, etc.",
            Documentation.AllowedValues = {true, false}
        ]
    )
) as table;

GetScheduleOccurrencesType = type function (
    optional templateIds as (
        type text meta [
            Documentation.FieldCaption = "Template IDs",
            Documentation.FieldDescription = "Comma separated list of IDs of the template you want to load the schedule occurrences for",
            Documentation.SampleValues = {"template_123,template_345"}
        ]
    ),
    optional startDate as (
        type datetimezone meta [
            Documentation.FieldCaption = "Start Date",
            Documentation.FieldDescription = "Schedule occurrences have happened after this date (date range cannot exceed 6 months)"
        ]
    ),
    optional endDate as (
        type datetimezone meta [
            Documentation.FieldCaption = "End Date",
            Documentation.FieldDescription = "Schedule occurrences have happened before this date (date range cannot exceed 6 months)"
        ]
    )
) as table;

GetIssuesType = type function () as table;

GetAssetsType = type function () as table;

GetActionTimelineItemsType = type function () as table;

GetIssueTimelineItemsType = type function () as table;

GetIssueAssigneesType = type function () as table;

// Read all pages of data.
// After every page, we check the "NextLink" record on the metadata of the previous request.
// Table.GenerateByPage will keep asking for more pages until we return null.
GetAllPagesByNextLink = (url as text, optional schema as type) as table =>
    Table.GenerateByPage(
        (previous) =>
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

MakeRequest = (url as text) =>
    let
        currentCredential = Extension.CurrentCredential(),
        accessToken =
            if (currentCredential[AuthenticationKind] = "OAuth") then
                currentCredential[access_token]
            else
                currentCredential[Key],
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
                            Query = [],
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
            (iteration) => #duration(0, 0, 0, Number.Power(2, iteration) * 2),
            6
        ),
        // retry after 4, 8, 16 and 32 seconds
        request = Json.Document(waitForResult)
    in
        request;

//
// Load common library functions
//
// TEMPORARY WORKAROUND until we're able to reference other M modules
Extension.LoadFunction = (name as text) =>
    let
        binary = Extension.Contents(name), asText = Text.FromBinary(binary)
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
