// Use this file to write queries to test your data connector
let
    source = iAuditor.Contents(),
    data = source{[Name="inspections"]}[Data]
in
    data