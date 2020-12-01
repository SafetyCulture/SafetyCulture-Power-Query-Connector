$version = "1.0-beta5"
$rootFolder = Get-Location
$buildFolder = "$rootFolder\build"
Remove-Item $buildFolder -Recurse
New-Item -Path @rootFolder -Name "build" -ItemType "directory"
Copy-Item "$rootFolder\*.png","$rootFolder\*.pqm","$rootFolder\*.resx" -Destination "$buildFolder"

(Get-Content "$rootFolder\iAuditor.pq") `
    -replace '(\"sc-integration-version\"\s=\s).+\"', "`$1`"$version`"" |
  Out-File "$buildFolder\iAuditor.m"

$compress = @{
  Path = "$buildFolder\*"
  CompressionLevel = "Fastest"
  DestinationPath = "$buildFolder\iAuditor.zip"
}
Compress-Archive @compress
Rename-Item -Path "$buildFolder\iAuditor.zip" -NewName "iAuditor.mez"

$certFile = "$rootFolder\cert.pfx"
[IO.File]::WriteAllBytes("$certFile", [Convert]::FromBase64String($ENV:CERT_DATA))

$pqxPackage = "$rootFolder\makepqx.zip"
Invoke-WebRequest https://aka.ms/makepqx -OutFile "$pqxPackage"
Expand-Archive "$pqxPackage" -DestinationPath "$rootFolder"

$pqx = "$rootFolder\MakePQX_Release\MakePQX.exe"
& $pqx pack -mz "$buildFolder\iAuditor.mez" -t "$buildFolder\iAuditorSigned.pqx"
& $pqx sign "$buildFolder\iAuditorSigned.pqx" --certificate "$certFile" --password "$ENV:CERT_PASS"
& $pqx verify "$buildFolder\iAuditorSigned.pqx"