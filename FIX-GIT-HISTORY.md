# 🔧 Complete Git History Fix

## Problem
The Slack webhook URL exists in multiple commits in git history. Even though we've removed it from current files, GitHub still blocks the push because it scans the entire history.

## ✅ Solution: Rewrite Git History

### Option 1: Interactive Rebase (Recommended for Recent Commits)

This will let you edit/remove the problematic commits:

```bash
# 1. Check how many commits contain the secret
git log --oneline --all --grep="alerting" -10

# 2. Start interactive rebase (adjust number based on commits)
git rebase -i HEAD~5

# 3. In the editor, change 'pick' to 'drop' for commits with secrets
#    Or change 'pick' to 'edit' to modify them
#    Save and close

# 4. If you chose 'edit', make changes and continue:
git add .
git rebase --continue

# 5. Force push (CAREFUL!)
git push origin main --force-with-lease
```

### Option 2: Reset and Recommit (Easiest)

Start fresh from a clean state:

```bash
# 1. Backup your current work
git branch backup-before-reset

# 2. Find the last good commit (before adding alerting)
git log --oneline -20

# 3. Reset to that commit (e.g., if it's 5 commits back)
git reset --soft HEAD~5

# 4. Unstage .env file
git reset HEAD .env

# 5. Verify .env is not staged
git status
# .env should appear under "Untracked files"

# 6. Stage only the files you want
git add .gitignore
git add grafana/
git add SECURITY-FIX.md
git add ALERTING-README.md
# ... add other files EXCEPT .env

# 7. Verify .env is NOT staged
git status | grep .env
# Should show: .env (untracked)

# 8. Commit without secrets
git commit -m "Add Grafana alerting configuration with Slack and Gmail support

- Configure Slack webhook via environment variable
- Configure Gmail SMTP via environment variable
- Add comprehensive alerting documentation
- Add sample alert rules for monitoring
- Secrets stored in .env (gitignored)"

# 9. Push to GitHub
git push origin main --force-with-lease
```

### Option 3: Filter-Repo (Most Thorough)

Remove the secret from entire git history:

```bash
# 1. Install git-filter-repo
# Windows (via pip):
pip install git-filter-repo

# 2. Create a file with text to replace
echo "YOUR_WEBHOOK_TOKEN==>REDACTED_WEBHOOK" > replacements.txt

# 3. Run filter-repo
git filter-repo --replace-text replacements.txt

# 4. Force push
git push origin main --force
```

## 🎯 Recommended Steps (Step by Step)

### Step 1: Verify Current State

```bash
# Check what's staged
git status

# Check recent commits
git log --oneline -5

# Verify .env is gitignored
git check-ignore .env
# Should output: .env
```

### Step 2: Remove .env from Git Tracking

```bash
# If .env is already tracked, remove it
git rm --cached .env

# Add to commit
git add .gitignore
git commit -m "Remove .env from git tracking"
```

### Step 3: Clean Up Commits with Secrets

Choose ONE of these approaches:

**Approach A: Squash Recent Commits**
```bash
# Squash last 3 commits into one
git reset --soft HEAD~3

# Stage files (EXCEPT .env)
git add .
git reset HEAD .env

# Create new clean commit
git commit -m "Add Grafana alerting with environment-based configuration"

# Force push
git push origin main --force-with-lease
```

**Approach B: Amend Last Commit**
```bash
# If secret is only in the last commit
git add .
git reset HEAD .env
git commit --amend --no-edit

# Force push
git push origin main --force-with-lease
```

### Step 4: Verify No Secrets

```bash
# Search for webhook in tracked files
git grep "hooks.slack.com" HEAD
# Should return nothing

# Check .env is not tracked
git ls-files | grep .env
# Should return nothing (or only .env.example)

# Verify .gitignore is working
git status
# .env should NOT appear in staged/tracked files
```

### Step 5: Push to GitHub

```bash
git push origin main --force-with-lease
```

## 🔐 After Successful Push

### 1. Verify on GitHub
- Go to: https://github.com/msellamiTN/Grafana-Stack
- Check that `.env` is not in the repository
- Verify `contactpoints.yaml` uses `${SLACK_WEBHOOK_URL}`

### 2. Enable Secret Scanning (Recommended)
- Go to: https://github.com/msellamiTN/Grafana-Stack/settings/security_analysis
- Enable "Secret scanning"
- Enable "Push protection"

### 3. Rotate the Webhook (Optional but Recommended)
Since the webhook was exposed in git history:
1. Go to: https://api.slack.com/apps/A09MQ4WMJVA/incoming-webhooks
2. Delete the old webhook
3. Create a new webhook
4. Update `.env` with new URL

## ⚠️ Important Notes

1. **Force Push Warning**: `--force-with-lease` is safer than `--force` as it checks if someone else pushed changes
2. **Backup**: Always create a backup branch before rewriting history
3. **Team Coordination**: If others are working on this repo, coordinate the force push
4. **Local .env**: Keep your `.env` file locally - it won't be pushed anymore

## 🧪 Testing After Fix

```bash
# 1. Verify .env is ignored
git status
# .env should not appear

# 2. Try to add .env (should fail or be ignored)
git add .env
git status
# Should show nothing staged or "The following paths are ignored"

# 3. Test webhook still works
source .env
curl -X POST -H "Content-type: application/json" \
  --data '{"text":"Test after git fix"}' \
  $SLACK_WEBHOOK_URL

# 4. Restart Grafana
docker compose restart grafana
```

## 📋 Checklist

- [ ] Backup current branch: `git branch backup-before-reset`
- [ ] Verify .gitignore includes `.env`
- [ ] Remove .env from git: `git rm --cached .env`
- [ ] Rewrite history (choose one method above)
- [ ] Verify no secrets in git: `git grep "hooks.slack.com" HEAD`
- [ ] Verify .env not tracked: `git ls-files | grep .env`
- [ ] Force push: `git push origin main --force-with-lease`
- [ ] Verify on GitHub: Check repository doesn't contain .env
- [ ] Test Grafana alerting still works
- [ ] (Optional) Rotate webhook for extra security

## 🆘 If Something Goes Wrong

```bash
# Restore from backup
git reset --hard backup-before-reset

# Or restore from remote
git fetch origin
git reset --hard origin/main

# Or restore specific file
git checkout HEAD~1 -- path/to/file
```

## 📚 Resources

- [Git Filter-Repo](https://github.com/newren/git-filter-repo)
- [Removing Sensitive Data](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository)
- [Git Rebase Interactive](https://git-scm.com/book/en/v2/Git-Tools-Rewriting-History)

---

**Status**: Ready to fix git history  
**Risk Level**: Medium (requires force push)  
**Estimated Time**: 5-10 minutes
