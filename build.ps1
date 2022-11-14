# Create build directory
$rootFolder = Get-Location
$buildFolder = "$rootFolder\build"
New-Item -Path @rootFolder -Name "build" -ItemType "directory"

# Copy required items into the build folder
Copy-Item "$rootFolder\*.png","$rootFolder\*.pqm","$rootFolder\*.resx" -Destination "$buildFolder"

# Set the version inside Power Query file
(Get-Content "$rootFolder\SafetyCulture.pq") `
    -replace '(\"sc-integration-version\"\s=\s).+\"', "`$1`"$ENV:CUR_VER`"" |
  Out-File "$buildFolder\SafetyCulture.m"

# Compress files into an archive file
$compress = @{
  Path = "$buildFolder\*"
  CompressionLevel = "Fastest"
  DestinationPath = "$buildFolder\SafetyCulture.zip"
}
Compress-Archive @compress
Rename-Item -Path "$buildFolder\SafetyCulture.zip" -NewName "SafetyCulture.mez"

# Generate certificate file from the base64 secret data
$certFile = "$rootFolder\cert.pfx"
[IO.File]::WriteAllBytes("$certFile", [Convert]::FromBase64String($ENV:CERT_DATA))

# Download and extract MakePQX package
$pqxPackage = "$rootFolder\makepqx.zip"
Invoke-WebRequest https://aka.ms/makepqx -OutFile "$pqxPackage"
Expand-Archive "$pqxPackage" -DestinationPath "$rootFolder"
$pqx = "$rootFolder\MakePQX_Release\MakePQX.exe"

# Sign and verify the connector
& $pqx pack -mz "$buildFolder\SafetyCulture.mez" -t "$buildFolder\SafetyCultureSigned.pqx"
& $pqx sign "$buildFolder\SafetyCultureSigned.pqx" --certificate "$certFile" --password "$ENV:CERT_PASS"
& $pqx verify "$buildFolder\SafetyCultureSigned.pqx"
