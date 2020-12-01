# Create build directory
$rootFolder = Get-Location
$buildFolder = "$rootFolder\build"
New-Item -Path @rootFolder -Name "build" -ItemType "directory"

# Copy required items into the build folder
Copy-Item "$rootFolder\*.png","$rootFolder\*.pqm","$rootFolder\*.resx" -Destination "$buildFolder"

# Set the version inside Power Query file
(Get-Content "$rootFolder\iAuditor.pq") `
    -replace '(\"sc-integration-version\"\s=\s).+\"', "`$1`"$ENV:CUR_VER`"" |
  Out-File "$buildFolder\iAuditor.m"

# Compress files into a compressed archive
$compress = @{
  Path = "$buildFolder\*"
  CompressionLevel = "Fastest"
  DestinationPath = "$buildFolder\iAuditor.zip"
}
Compress-Archive @compress
Rename-Item -Path "$buildFolder\iAuditor.zip" -NewName "iAuditor.mez"

# Generate certificate file from the base64 secret data
$certFile = "$rootFolder\cert.pfx"
[IO.File]::WriteAllBytes("$certFile", [Convert]::FromBase64String($ENV:CERT_DATA))

# Download and extrac Make PQX package
$pqxPackage = "$rootFolder\makepqx.zip"
Invoke-WebRequest https://aka.ms/makepqx -OutFile "$pqxPackage"
Expand-Archive "$pqxPackage" -DestinationPath "$rootFolder"
$pqx = "$rootFolder\MakePQX_Release\MakePQX.exe"

# Sign and verify the package
& $pqx pack -mz "$buildFolder\iAuditor.mez" -t "$buildFolder\iAuditorSigned.pqx"
& $pqx sign "$buildFolder\iAuditorSigned.pqx" --certificate "$certFile" --password "$ENV:CERT_PASS"
& $pqx verify "$buildFolder\iAuditorSigned.pqx"