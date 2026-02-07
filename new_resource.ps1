param (
    [Parameter(Mandatory=$true)]
    [string]$Name
)

$TemplatePath = ".\ag_template"
$NewPath = ".\$Name"

if (Test-Path $NewPath) {
    Write-Host "Error: Resource '$Name' already exists!" -ForegroundColor Red
    exit
}

# Copy Template
Copy-Item -Path $TemplatePath -Destination $NewPath -Recurse
Write-Host "Created '$Name' from template." -ForegroundColor Green

# Function to Replace Text in File
function Replace-InFile {
    param ($FilePath, $Find, $Replace)
    if (Test-Path $FilePath) {
        $Content = Get-Content $FilePath -Raw
        $NewContent = $Content -replace $Find, $Replace
        Set-Content $FilePath $NewContent
    }
}

# Rename internals
$FilesToUpdate = @(
    "$NewPath\fxmanifest.lua",
    "$NewPath\client\main.lua",
    "$NewPath\server\main.lua",
    "$NewPath\server\storage.lua",
    "$NewPath\web\script.js",
    "$NewPath\config.lua"
)

foreach ($File in $FilesToUpdate) {
    Replace-InFile -FilePath $File -Find "ag_template" -Replace $Name
}

# Rename Config Table if needed (Optional, keeping consistent for now)
# Replace-InFile -FilePath "$NewPath\config.lua" -Find "ag_data" -Replace "${Name}_data"

Write-Host "Updated internal references to '$Name'." -ForegroundColor Cyan
Write-Host "Ready to develop! Folder: $NewPath" -ForegroundColor Green
