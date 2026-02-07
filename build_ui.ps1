$ErrorActionPreference = "Stop"

Write-Host "🎨 Building Anti-Gravity Power&Water UI..." -ForegroundColor Cyan

# Check for Node.js
if (!(Get-Command node -ErrorAction SilentlyContinue)) {
    Write-Error "Node.js is not installed or not in your PATH. Please install Node.js LTS from nodejs.org."
    exit 1
}

# Define Paths
$RepoRoot = "C:\Users\timos\antigravity projekte\Anti-Gravity"
$AppDir = "$RepoRoot\app"
$ResourceWebDir = "$RepoRoot\ag_powerwater\web"

# 1. Build React App
Write-Host "📦 Building React App in $AppDir..."
Push-Location $AppDir

if (!(Test-Path "node_modules")) {
    Write-Host "Installing dependencies..."
    npm install
}

npm run build

if ($LASTEXITCODE -ne 0) {
    Write-Error "Build failed!"
    Pop-Location
    exit 1
}

Pop-Location

# 2. Deploy to Resource
Write-Host "🚀 Deploying to $ResourceWebDir..."

# Ensure target directory exists
if (!(Test-Path $ResourceWebDir)) {
    New-Item -ItemType Directory -Force -Path $ResourceWebDir | Out-Null
}

# Clean old files (optional, but good for hashes)
# Remove-Item "$ResourceWebDir\*" -Recurse -Force -ErrorAction SilentlyContinue

# Copy Build Artifacts
Copy-Item "$AppDir\dist\*" -Destination $ResourceWebDir -Recurse -Force

Write-Host "✅ UI Deployed Successfully!" -ForegroundColor Green
Write-Host "Please restart the 'ag_powerwater' resource in FiveM."
