section SafetyCultureUnitTests;

shared SafetyCulture.UnitTest = [
    // Put any common variables here if you only want them to be evaluated once
    RootTable = SafetyCulture.Contents("acme"),
    Inspections = RootTable{[Name = "inspections"]}[Data],
    InspectionItems = RootTable{[Name = "inspection_items"]}[Data],
    Users = RootTable{[Name = "users"]}[Data],
    Groups = RootTable{[Name = "groups"]}[Data],
    GroupUsers = RootTable{[Name = "group_users"]}[Data],
    Templates = RootTable{[Name = "templates"]}[Data],
    TemplatePermissions = RootTable{[Name = "template_permissions"]}[Data],
    Sites = RootTable{[Name = "sites"]}[Data],
    GetInspections = RootTable{[Name = "GetInspections"]}[Data](null, null, null, null, null),
    GetSites = RootTable{[Name = "GetSites"]}[Data](null),
    ScheduleFolder = RootTable{[Name = "Schedule"]}[Data],
    Schedules = ScheduleFolder{[Name = "schedules"]}[Data],
    ScheduleAssignees = ScheduleFolder{[Name = "schedule_assignees"]}[Data],
    ScheduleOccurrences = ScheduleFolder{[Name = "schedule_occurrences"]}[Data],
    ActionsFolder = RootTable{[Name = "Actions"]}[Data],
    Actions = ActionsFolder{[Name = "actions"]}[Data],
    ActionAssignees = ActionsFolder{[Name = "action_assignees"]}[Data],
    ActionTimelineItems = ActionsFolder{[Name = "action_timeline_items"]}[Data],
    IssuesFolder = RootTable{[Name = "Issues"]}[Data],
    Issues = IssuesFolder{[Name = "issues"]}[Data],
    IssueTimelineItems = IssuesFolder{[Name = "issue_timeline_items"]}[Data],
    AssetsFolder = RootTable{[Name = "Assets"]}[Data],
    Assets = AssetsFolder{[Name = "assets"]}[Data],
    CourseProgresses = RootTable{[Name = "training-course-progress"]}[Data],
    IssueAssignees = RootTable{[Name = "issue_assignees"]}[Data],
    // Fact(<Name of the Test>, <Expected Value>, <Actual Value>)
    // <Expected Value> and <Actual Value> can be a literal or let statement
    facts = {
        Fact("Check that we have the correct number of entries in our nav table", 14, Table.RowCount(RootTable)),
        Fact("We have Inspections data?", true, not Table.IsEmpty(Inspections)),
        Fact("Inspections has 27 columns", 27, List.Count(Table.ColumnNames(Inspections))),
        Fact("We have Inspection Items data?", true, not Table.IsEmpty(InspectionItems)),
        Fact("Inspection Items has 27 columns", 27, List.Count(Table.ColumnNames(InspectionItems))),
        Fact("We have Users data?", true, not Table.IsEmpty(Users)),
        Fact("Users has 7 columns", 7, List.Count(Table.ColumnNames(Users))),
        Fact("We have Groups data?", true, not Table.IsEmpty(Groups)),
        Fact("Groups has 2 columns", 2, List.Count(Table.ColumnNames(Groups))),
        Fact("We have Group Users data?", true, not Table.IsEmpty(GroupUsers)),
        Fact("Group Users has 2 columns", 2, List.Count(Table.ColumnNames(GroupUsers))),
        Fact("We have Templates data?", true, not Table.IsEmpty(Templates)),
        Fact("Templates has 10 columns", 10, List.Count(Table.ColumnNames(Templates))),
        Fact("We have Template Permissions data?", true, not Table.IsEmpty(TemplatePermissions)),
        Fact("Template Permissions has 5 columns", 5, List.Count(Table.ColumnNames(TemplatePermissions))),
        Fact("We have Sites data?", true, not Table.IsEmpty(Sites)),
        Fact("Sites has 5 columns", 5, List.Count(Table.ColumnNames(Sites))),
        Fact("We have GetInspections data?", true, not Table.IsEmpty(GetInspections)),
        Fact("Inspections has 27 columns", 27, List.Count(Table.ColumnNames(GetInspections))),
        Fact("We have GetSites data?", true, not Table.IsEmpty(GetSites)),
        Fact("Inspections has 5 columns", 5, List.Count(Table.ColumnNames(GetSites))),
        Fact("We have Schedules data?", true, not Table.IsEmpty(Schedules)),
        Fact("Schedules has 16 columns", 16, List.Count(Table.ColumnNames(Schedules))),
        Fact("We have Schedule Assignees data?", true, not Table.IsEmpty(ScheduleAssignees)),
        Fact("Schedule Assignees has 5 columns", 5, List.Count(Table.ColumnNames(ScheduleAssignees))),
        Fact("We have Schedule Occurrences data?", true, not Table.IsEmpty(ScheduleOccurrences)),
        Fact("Schedule Occurrences has 14 columns", 14, List.Count(Table.ColumnNames(ScheduleOccurrences))),
        Fact("We have Actions data?", true, not Table.IsEmpty(Actions)),
        Fact("Schedules has 16 columns", 16, List.Count(Table.ColumnNames(Actions))),
        Fact("We have Action Assignees data?", true, not Table.IsEmpty(ActionAssignees)),
        Fact("Action Assignees has 5 columns", 5, List.Count(Table.ColumnNames(ActionAssignees))),
        Fact("We have Action Timeline Items data?", true, not Table.IsEmpty(ActionTimelineItems)),
        Fact("Action Timeline Items has 10 columns", 10, List.Count(Table.ColumnNames(ActionTimelineItems))),
        Fact("We have Issue data?", true, not Table.IsEmpty(Issues)),
        Fact("Actions has 17 columns", 17, List.Count(Table.ColumnNames(Issues))),
        Fact("We have Issue Timeline Items data?", true, not Table.IsEmpty(IssueTimelineItems)),
        Fact("Issue Timeline Items has 10 columns", 10, List.Count(Table.ColumnNames(IssueTimelineItems))),
        Fact("We have Asset data?", true, not Table.IsEmpty(Assets)),
        Fact("Assets has 9 columns", 9, List.Count(Table.ColumnNames(Assets))),
        Fact("Course Progresses has 15 columns", 15, List.Count(Table.ColumnNames(CourseProgresses)))
        Fact("We have Issue Assignees data?", true, not Table.IsEmpty(IssueAssignees)),
        Fact("Issue Assignees has 7 columns", 7, List.Count(Table.ColumnNames(IssueAssignees)))
    },
    report = Facts.Summarize(facts)
][report];

/// COMMON UNIT TESTING CODE
Fact = (_subject as text, _expected, _actual) as record =>
    [
        expected = try _expected,
        safeExpected = if expected[HasError] then "Expected : " & @ValueToText(expected[Error]) else expected[Value],
        actual = try _actual,
        safeActual = if actual[HasError] then "Actual : " & @ValueToText(actual[Error]) else actual[Value],
        attempt = try safeExpected = safeActual,
        result = if attempt[HasError] or not attempt[Value] then "Failure ⛔" else "Success ✓",
        resultOp = if result = "Success ✓" then " = " else " <> ",
        addendumEvalAttempt = if attempt[HasError] then @ValueToText(attempt[Error]) else "",
        addendumEvalExpected = try @ValueToText(safeExpected) otherwise "...",
        addendumEvalActual = try @ValueToText(safeActual) otherwise "...",
        fact = [
            Result = result & " " & addendumEvalAttempt,
            Notes = _subject,
            Details = " (" & addendumEvalExpected & resultOp & addendumEvalActual & ")"
        ]
    ][fact];

Facts = (_subject as text, _predicates as list) => List.Transform(_predicates, each Fact(_subject, _{0}, _{1}));

Facts.Summarize = (_facts as list) as table =>
    [
        Fact.CountSuccesses = (count, i) =>
            [
                result = try i[Result],
                sum = if result[HasError] or not Text.StartsWith(result[Value], "Success") then count else count + 1
            ][sum],
        passed = List.Accumulate(_facts, 0, Fact.CountSuccesses),
        total = List.Count(_facts),
        format = if passed = total then "All #{0} Passed !!! ✓" else "#{0} Passed ☺  #{1} Failed ☹",
        result = if passed = total then "Success" else "⛔",
        rate = Number.IntegerDivide(100 * passed, total),
        header = [
            Result = result,
            Notes = Text.Format(format, {passed, total - passed}),
            Details = Text.Format("#{0}% success rate", {rate})
        ],
        report = Table.FromRecords(List.Combine({{header}, _facts}))
    ][report];

ValueToText = (value, optional depth) =>
    let
        _canBeIdentifier = (x) =>
            let
                keywords = {
                    "and",
                    "as",
                    "each",
                    "else",
                    "error",
                    "false",
                    "if",
                    "in",
                    "is",
                    "let",
                    "meta",
                    "not",
                    "otherwise",
                    "or",
                    "section",
                    "shared",
                    "then",
                    "true",
                    "try",
                    "type"
                },
                charAlpha = (c as number) => (c >= 65 and c <= 90) or (c >= 97 and c <= 122) or c = 95,
                charDigit = (c as number) => c >= 48 and c <= 57
            in
                try
                    charAlpha(Character.ToNumber(Text.At(x, 0)))
                    and List.MatchesAll(
                        Text.ToList(x), (c) => let num = Character.ToNumber(c) in charAlpha(num) or charDigit(num)
                    )
                    and not List.MatchesAny(keywords, (li) => li = x) otherwise false,
        Serialize.Binary = (x) => "#binary(" & Serialize(Binary.ToList(x)) & ") ",
        Serialize.Date = (x) =>
            "#date(" & Text.From(Date.Year(x)) & ", " & Text.From(Date.Month(x)) & ", " & Text.From(Date.Day(x)) & ") ",
        Serialize.Datetime = (x) =>
            "#datetime("
                & Text.From(Date.Year(DateTime.Date(x)))
                & ", "
                & Text.From(Date.Month(DateTime.Date(x)))
                & ", "
                & Text.From(Date.Day(DateTime.Date(x)))
                & ", "
                & Text.From(Time.Hour(DateTime.Time(x)))
                & ", "
                & Text.From(Time.Minute(DateTime.Time(x)))
                & ", "
                & Text.From(Time.Second(DateTime.Time(x)))
                & ") ",
        Serialize.Datetimezone = (x) =>
            let
                dtz = DateTimeZone.ToRecord(x)
            in
                "#datetimezone("
                    & Text.From(dtz[Year])
                    & ", "
                    & Text.From(dtz[Month])
                    & ", "
                    & Text.From(dtz[Day])
                    & ", "
                    & Text.From(dtz[Hour])
                    & ", "
                    & Text.From(dtz[Minute])
                    & ", "
                    & Text.From(dtz[Second])
                    & ", "
                    & Text.From(dtz[ZoneHours])
                    & ", "
                    & Text.From(dtz[ZoneMinutes])
                    & ") ",
        Serialize.Duration = (x) =>
            let
                dur = Duration.ToRecord(x)
            in
                "#duration("
                    & Text.From(dur[Days])
                    & ", "
                    & Text.From(dur[Hours])
                    & ", "
                    & Text.From(dur[Minutes])
                    & ", "
                    & Text.From(dur[Seconds])
                    & ") ",
        Serialize.Function = (x) =>
            _serialize_function_param_type(
                Type.FunctionParameters(Value.Type(x)), Type.FunctionRequiredParameters(Value.Type(x))
            )
                & " as "
                & _serialize_function_return_type(Value.Type(x))
                & " => (...) ",
        Serialize.List = (x) =>
            "{"
                & List.Accumulate(
                    x, "", (seed, item) => if seed = "" then Serialize(item) else seed & ", " & Serialize(item)
                )
                & "} ",
        Serialize.Logical = (x) => Text.From(x),
        Serialize.Null = (x) => "null",
        Serialize.Number = (x) =>
            let
                Text.From = (i as number) as text =>
                    if Number.IsNaN(i) then
                        "#nan"
                    else if i = Number.PositiveInfinity then
                        "#infinity"
                    else if i = Number.NegativeInfinity then
                        "-#infinity"
                    else
                        Text.From(i)
            in
                Text.From(x),
        Serialize.Record = (x) =>
            "[ "
                & List.Accumulate(
                    Record.FieldNames(x),
                    "",
                    (seed, item) =>
                        (if seed = "" then Serialize.Identifier(item) else seed & ", " & Serialize.Identifier(item))
                            & " = "
                            & Serialize(Record.Field(x, item))
                )
                & " ] ",
        Serialize.Table = (x) =>
            "#table( type " & _serialize_table_type(Value.Type(x)) & ", " & Serialize(Table.ToRows(x)) & ") ",
        Serialize.Text = (x) => """" & _serialize_text_content(x) & """",
        _serialize_text_content = (x) =>
            let
                escapeText = (n as number) as text =>
                    "#(#)(" & Text.PadStart(Number.ToText(n, "X", "en-US"), 4, "0") & ")"
            in
                List.Accumulate(
                    List.Transform(
                        Text.ToList(x),
                        (c) =>
                            let
                                n = Character.ToNumber(c)
                            in
                                if n = 9 then
                                    "#(#)(tab)"
                                else if n = 10 then
                                    "#(#)(lf)"
                                else if n = 13 then
                                    "#(#)(cr)"
                                else if n = 34 then
                                    """"""
                                else if n = 35 then
                                    "#(#)(#)"
                                else if n < 32 then
                                    escapeText(n)
                                else if n < 127 then
                                    Character.FromNumber(n)
                                else
                                    escapeText(n)
                    ),
                    "",
                    (s, i) => s & i
                ),
        Serialize.Identifier = (x) => if _canBeIdentifier(x) then x else "#""" & _serialize_text_content(x) & """",
        Serialize.Time = (x) =>
            "#time(" & Text.From(Time.Hour(x)) & ", " & Text.From(Time.Minute(x)) & ", " & Text.From(Time.Second(x))
                & ") ",
        Serialize.Type = (x) => "type " & _serialize_typename(x),
        _serialize_typename = (x, optional funtype as logical) =>
            /* Optional parameter: Is this being used as part of a function signature? */ let
                isFunctionType = (x as type) =>
                    try if Type.FunctionReturn(x) is type then true else false otherwise false,
                isTableType = (x as type) => try if Type.TableSchema(x) is table then true else false otherwise false,
                isRecordType = (x as type) => try if Type.ClosedRecord(x) is type then true else false
            otherwise
                false,
                isListType = (x as type) => try if Type.ListItem(x) is type then true else false otherwise false
            in
                if funtype = null and isTableType(x) then
                    _serialize_table_type(x)
                else if funtype = null and isListType(x) then
                    "{ " & @_serialize_typename(Type.ListItem(x)) & " }"
                else if funtype = null and isFunctionType(x) then
                    "function " & _serialize_function_type(x)
                else if funtype = null and isRecordType(x) then
                    _serialize_record_type(x)
                else if x = type any then
                    "any"
                else
                    let
                        base = Type.NonNullable(x)
                    in
                        (if Type.IsNullable(x) then "nullable " else "")
                            & (
                                if base = type anynonnull then
                                    "anynonnull"
                                else if base = type binary then
                                    "binary"
                                else if base = type date then
                                    "date"
                                else if base = type datetime then
                                    "datetime"
                                else if base = type datetimezone then
                                    "datetimezone"
                                else if base = type duration then
                                    "duration"
                                else if base = type logical then
                                    "logical"
                                else if base = type none then
                                    "none"
                                else if base = type null then
                                    "null"
                                else if base = type number then
                                    "number"
                                else if base = type text then
                                    "text"
                                else if base = type time then
                                    "time"
                                else if base = type type then
                                    "type"
                                else /* Abstract types: */ if base = type function then
                                    "function"
                                else if base = type table then
                                    "table"
                                else if base = type record then
                                    "record"
                                else if base = type list then
                                    "list"
                                else
                                    "any /*Actually unknown type*/"
                            ),
        _serialize_table_type = (x) =>
            let
                schema = Type.TableSchema(x)
            in
                "table "
                    & (
                        if Table.IsEmpty(schema) then
                            ""
                        else
                            "["
                                & List.Accumulate(
                                    List.Transform(
                                        Table.ToRecords(Table.Sort(schema, "Position")),
                                        each Serialize.Identifier(_[Name]) & " = " & _[Kind]
                                    ),
                                    "",
                                    (seed, item) => (if seed = "" then item else seed & ", " & item)
                                )
                                & "] "
                    ),
        _serialize_record_type = (x) =>
            let
                flds = Type.RecordFields(x)
            in
                if Record.FieldCount(flds) = 0 then
                    "record"
                else
                    "["
                        & List.Accumulate(
                            Record.FieldNames(flds),
                            "",
                            (seed, item) =>
                                seed
                                    & (if seed <> "" then ", " else "")
                                    & (
                                        Serialize.Identifier(item)
                                            & "="
                                            & _serialize_typename(Record.Field(flds, item)[Type])
                                    )
                        )
                        & (if Type.IsOpenRecord(x) then ",..." else "")
                        & "]",
        _serialize_function_type = (x) =>
            _serialize_function_param_type(Type.FunctionParameters(x), Type.FunctionRequiredParameters(x))
                & " as "
                & _serialize_function_return_type(x),
        _serialize_function_param_type = (t, n) =>
            let
                funsig = Table.ToRecords(
                    Table.TransformColumns(
                        Table.AddIndexColumn(Record.ToTable(t), "isOptional", 1), {"isOptional", (x) => x > n}
                    )
                )
            in
                "("
                    & List.Accumulate(
                        funsig,
                        "",
                        (seed, item) =>
                            (if seed = "" then "" else seed & ", ")
                                & (if item[isOptional] then "optional " else "")
                                & Serialize.Identifier(item[Name])
                                & " as "
                                & _serialize_typename(item[Value], true)
                    )
                    & ")",
        _serialize_function_return_type = (x) => _serialize_typename(Type.FunctionReturn(x), true),
        Serialize = (x) as text =>
            if x is binary then
                try Serialize.Binary(x) otherwise "null /*serialize failed*/"
            else if x is date then
                try Serialize.Date(x) otherwise "null /*serialize failed*/"
            else if x is datetime then
                try Serialize.Datetime(x) otherwise "null /*serialize failed*/"
            else if x is datetimezone then
                try Serialize.Datetimezone(x) otherwise "null /*serialize failed*/"
            else if x is duration then
                try Serialize.Duration(x) otherwise "null /*serialize failed*/"
            else if x is function then
                try Serialize.Function(x) otherwise "null /*serialize failed*/"
            else if x is list then
                try Serialize.List(x) otherwise "null /*serialize failed*/"
            else if x is logical then
                try Serialize.Logical(x) otherwise "null /*serialize failed*/"
            else if x is null then
                try Serialize.Null(x) otherwise "null /*serialize failed*/"
            else if x is number then
                try Serialize.Number(x) otherwise "null /*serialize failed*/"
            else if x is record then
                try Serialize.Record(x) otherwise "null /*serialize failed*/"
            else if x is table then
                try Serialize.Table(x) otherwise "null /*serialize failed*/"
            else if x is text then
                try Serialize.Text(x) otherwise "null /*serialize failed*/"
            else if x is time then
                try Serialize.Time(x) otherwise "null /*serialize failed*/"
            else if x is type then
                try Serialize.Type(x) otherwise "null /*serialize failed*/"
            else
                "[#_unable_to_serialize_#]"
    in
        try Serialize(value) otherwise "<serialization failed>";
