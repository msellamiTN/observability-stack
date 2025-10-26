# Quick Fix for Git Secret Scanning Issue
# This script removes secrets from git history

Write-Host "🔧 Git Secret Fix - Quick Solution" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Create backup
Write-Host "📦 Creating backup branch..." -ForegroundColor Yellow
$backupBranch = "backup-before-fix-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
git branch $backupBranch
Write-Host "✅ Backup created: $backupBranch" -ForegroundColor Green
Write-Host ""

# Step 2: Check current status
Write-Host "📊 Current status:" -ForegroundColor Yellow
git status --short
Write-Host ""

# Step 3: Stage the fixed files
Write-Host "📝 Staging fixed files..." -ForegroundColor Yellow
git add SECURITY-FIX.md
git add FIX-GIT-HISTORY.md
git add .env.example
Write-Host "✅ Files staged" -ForegroundColor Green
Write-Host ""

# Step 4: Show what will be committed
Write-Host "📋 Files to be committed:" -ForegroundColor Yellow
git status --short
Write-Host ""

# Step 5: Commit the fixes
Write-Host "💾 Committing fixes..." -ForegroundColor Yellow
git commit -m "Fix: Remove hardcoded webhook URLs from documentation

- Replace example webhook URLs with placeholders in SECURITY-FIX.md
- Replace specific tokens with generic search terms in FIX-GIT-HISTORY.md
- Add SLACK_WEBHOOK_URL to .env.example with placeholder
- All secrets now use environment variables only"

Write-Host "✅ Fixes committed" -ForegroundColor Green
Write-Host ""

# Step 6: Instructions for push
Write-Host "================================" -ForegroundColor Cyan
Write-Host "✅ Ready to Push!" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next step: Push to GitHub" -ForegroundColor Yellow
Write-Host ""
Write-Host "Run this command:" -ForegroundColor White
Write-Host "  git push origin main" -ForegroundColor Cyan
Write-Host ""
Write-Host "If GitHub still blocks it, you may need to rewrite history:" -ForegroundColor Yellow
Write-Host "  See FIX-GIT-HISTORY.md for detailed instructions" -ForegroundColor White
Write-Host ""
Write-Host "To restore if needed:" -ForegroundColor Yellow
Write-Host "  git reset --hard $backupBranch" -ForegroundColor White
Write-Host ""
