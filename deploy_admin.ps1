# deploy_admin.ps1
#
# Safely builds the Flutter Admin Web panel and deploys directly to Vercel
# WITHOUT committing the compiled output (and the embedded API key) to GitHub.
#
# Usage:
#   1. Set the GEMINI_API_KEY environment variable in a SECURE way:
#      $env:GEMINI_API_KEY = "your_key_here"
#   2. Run this script:
#      .\deploy_admin.ps1
#
# Prerequisites:
#   - Flutter SDK installed
#   - Vercel CLI installed: npm install -g vercel
#   - Vercel account linked: vercel login && vercel link --cwd build/web
#   - GEMINI_API_KEY environment variable set

param(
    [switch]$SkipBuild  # Pass -SkipBuild to redeploy existing build/web without rebuilding
)

$ErrorActionPreference = "Stop"

# ------------------------------------------------------------------
# Validate the API key
# ------------------------------------------------------------------
if (-not $env:GEMINI_API_KEY) {
    Write-Error "ERROR: GEMINI_API_KEY environment variable is not set."
    Write-Host "Set it first (in this terminal session only):"
    Write-Host '  $env:GEMINI_API_KEY = "your_api_key_here"'
    exit 1
}

if ($env:GEMINI_API_KEY -eq "YOUR_KEY_HERE") {
    Write-Error "ERROR: GEMINI_API_KEY is still the placeholder. Set your real key."
    exit 1
}

Write-Host "✓ GEMINI_API_KEY is set (length: $($env:GEMINI_API_KEY.Length) chars)" -ForegroundColor Green

# ------------------------------------------------------------------
# Build (unless -SkipBuild)
# ------------------------------------------------------------------
if (-not $SkipBuild) {
    Write-Host ""
    Write-Host "Building Flutter Admin Web..." -ForegroundColor Cyan
    flutter build web --release -t lib/main_admin.dart "--dart-define=GEMINI_API_KEY=$env:GEMINI_API_KEY"
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Flutter build failed."
        exit 1
    }
    Write-Host "✓ Build complete" -ForegroundColor Green
} else {
    Write-Host "(Skipping build — using existing build/web)" -ForegroundColor Yellow
}

# ------------------------------------------------------------------
# Deploy to Vercel
# ------------------------------------------------------------------
Write-Host ""
Write-Host "Deploying to Vercel production..." -ForegroundColor Cyan
vercel deploy build/web --prod --yes
if ($LASTEXITCODE -ne 0) {
    Write-Error "Vercel deployment failed."
    exit 1
}

Write-Host ""
Write-Host "✓ Deployment complete! Gemini AI is now live in production." -ForegroundColor Green
Write-Host ""
Write-Host "SECURITY REMINDER:" -ForegroundColor Yellow
Write-Host "  - build/web is excluded from .gitignore (key stays off GitHub)"
Write-Host "  - The key is compiled into main.dart.js and visible in browser DevTools"
Write-Host "  - Only share the admin URL with trusted administrators"
