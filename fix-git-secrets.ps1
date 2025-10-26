# PowerShell Script to Fix Git Secrets Issue
# This script helps remove secrets from git history

param(
    [switch]$DryRun = $false
)

$ErrorActionPreference = "Stop"

Write-Host "🔧 Git Secrets Fix Script" -ForegroundColor Cyan
Write-Host "=========================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Check current status
Write-Host "📊 Checking current git status..." -ForegroundColor Yellow
git status

Write-Host ""
Write-Host "📝 Recent commits:" -ForegroundColor Yellow
git log --oneline -5

Write-Host ""

# Step 2: Verify .gitignore
Write-Host "🔍 Verifying .gitignore..." -ForegroundColor Yellow
if (Test-Path ".gitignore") {
    $gitignoreContent = Get-Content ".gitignore"
    if ($gitignoreContent -match "^\.env$") {
        Write-Host "✅ .env is in .gitignore" -ForegroundColor Green
    } else {
        Write-Host "❌ .env is NOT in .gitignore" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "❌ .gitignore file not found" -ForegroundColor Red
    exit 1
}

# Step 3: Check if .env is tracked
Write-Host ""
Write-Host "🔍 Checking if .env is tracked by git..." -ForegroundColor Yellow
$trackedFiles = git ls-files
if ($trackedFiles -match "\.env$") {
    Write-Host "⚠️  .env is currently tracked by git" -ForegroundColor Yellow
    Write-Host "   We'll remove it from tracking..." -ForegroundColor Yellow
} else {
    Write-Host "✅ .env is not tracked" -ForegroundColor Green
}

Write-Host ""
Write-Host "================================" -ForegroundColor Cyan
Write-Host "🎯 Recommended Fix Strategy" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Option 1: Reset and Recommit (Easiest)" -ForegroundColor Green
Write-Host "  - Resets last few commits" -ForegroundColor Gray
Write-Host "  - Creates clean commit without secrets" -ForegroundColor Gray
Write-Host "  - Requires force push" -ForegroundColor Gray
Write-Host ""
Write-Host "Option 2: Amend Last Commit" -ForegroundColor Yellow
Write-Host "  - Only if secret is in last commit" -ForegroundColor Gray
Write-Host "  - Quick fix" -ForegroundColor Gray
Write-Host "  - Requires force push" -ForegroundColor Gray
Write-Host ""

if (-not $DryRun) {
    Write-Host "⚠️  This is a DRY RUN. Use -DryRun:`$false to execute changes" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "To proceed with the fix, run:" -ForegroundColor Cyan
    Write-Host "  .\fix-git-secrets.ps1 -DryRun:`$false" -ForegroundColor White
    Write-Host ""
    Write-Host "Or follow the manual steps in FIX-GIT-HISTORY.md" -ForegroundColor Cyan
    exit 0
}

Write-Host ""
Write-Host "🚀 Executing Fix..." -ForegroundColor Green
Write-Host ""

# Create backup branch
Write-Host "📦 Creating backup branch..." -ForegroundColor Yellow
git branch backup-before-fix-$(Get-Date -Format "yyyyMMdd-HHmmss")
Write-Host "✅ Backup created" -ForegroundColor Green

# Remove .env from tracking if it exists
Write-Host ""
Write-Host "🗑️  Removing .env from git tracking..." -ForegroundColor Yellow
try {
    git rm --cached .env 2>$null
    Write-Host "✅ .env removed from tracking" -ForegroundColor Green
} catch {
    Write-Host "ℹ️  .env was not tracked" -ForegroundColor Gray
}

# Stage .gitignore
Write-Host ""
Write-Host "📝 Staging .gitignore..." -ForegroundColor Yellow
git add .gitignore

Write-Host ""
Write-Host "================================" -ForegroundColor Cyan
Write-Host "✅ Preparation Complete!" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Review staged changes: git status" -ForegroundColor White
Write-Host "2. Reset to clean state: git reset --soft HEAD~3" -ForegroundColor White
Write-Host "3. Stage files (except .env): git add ." -ForegroundColor White
Write-Host "4. Unstage .env: git reset HEAD .env" -ForegroundColor White
Write-Host "5. Commit: git commit -m 'Add alerting configuration'" -ForegroundColor White
Write-Host "6. Push: git push origin main --force-with-lease" -ForegroundColor White
Write-Host ""
Write-Host "Or run the commands from FIX-GIT-HISTORY.md" -ForegroundColor Cyan
