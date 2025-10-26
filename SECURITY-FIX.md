# 🔐 GitHub Secret Protection - Fix Guide

## Problem

GitHub blocked your push because it detected a **Slack webhook URL** in your commit. This is a security feature to prevent credential leaks.

## ✅ What Was Fixed

1. **Removed hardcoded webhook URLs** from `contactpoints.yaml`
2. **Replaced with environment variable**: `${SLACK_WEBHOOK_URL}`
3. **Added webhook to `.env` file** (which is now gitignored)
4. **Created `.gitignore`** to prevent committing secrets

## 📁 Changes Made

### File: `grafana/provisioning/alerting/contactpoints.yaml`
```yaml
# Before (INSECURE):
url: https://hooks.slack.com/services/T****/B****/****

# After (SECURE):
url: ${SLACK_WEBHOOK_URL}
```

### File: `.env`
```bash
# Your actual webhook is now stored here (NOT committed to git)
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/YOUR_WORKSPACE/YOUR_CHANNEL/YOUR_TOKEN
```

### File: `.gitignore`
```
.env
.env.local
.env.*.local
```

## 🚀 How to Push to GitHub

### Step 1: Remove the Secret from Git History

Since the secret was already committed, you need to remove it from git history:

```bash
# Option A: Amend the last commit (if it's the most recent commit)
git add .
git commit --amend --no-edit

# Option B: Reset to previous commit (if you want to start fresh)
git reset --soft HEAD~1
git add .
git commit -m "Add Grafana alerting configuration (secrets in .env)"
```

### Step 2: Verify No Secrets in Files

```bash
# Check that contactpoints.yaml uses environment variables
grep -n "SLACK_WEBHOOK_URL" grafana/provisioning/alerting/contactpoints.yaml

# Should show: url: ${SLACK_WEBHOOK_URL}
```

### Step 3: Ensure .env is Gitignored

```bash
# Check .gitignore exists
cat .gitignore | grep .env

# Verify .env won't be committed
git status
# .env should NOT appear in the list
```

### Step 4: Push to GitHub

```bash
git push origin main
```

## 🔄 Alternative: Allow the Secret (Not Recommended)

If you really want to push the webhook URL (NOT recommended for security), GitHub provides a bypass URL:

```
https://github.com/msellamiTN/Grafana-Stack/security/secret-scanning/unblock-secret/34M0ZoARk1wFVlIi3hb7qph3Waa
```

**⚠️ WARNING**: This exposes your webhook URL publicly. Anyone with access to your repository can use it to send messages to your Slack channel.

## 🎯 Recommended Workflow

### For Development

1. **Keep secrets in `.env`** (gitignored)
2. **Use placeholders in config files** (committed to git)
3. **Document required variables** in `.env.example`

### For Deployment

**Option 1: Manual substitution**
```bash
# Load .env and start services
source .env
docker compose up -d
```

**Option 2: Use envsubst**
```bash
# Substitute variables before starting
envsubst < grafana/provisioning/alerting/contactpoints.yaml.template > grafana/provisioning/alerting/contactpoints.yaml
docker compose up -d
```

**Option 3: Docker Compose environment**
Update `docker-compose.yml` to pass environment variables to Grafana:
```yaml
grafana:
  environment:
    - SLACK_WEBHOOK_URL=${SLACK_WEBHOOK_URL}
```

## 📋 Checklist

- [x] Removed hardcoded webhook URLs from `contactpoints.yaml`
- [x] Added webhook to `.env` file
- [x] Created `.gitignore` with `.env` entry
- [ ] Amend or reset the commit with secrets
- [ ] Verify `.env` is not tracked by git
- [ ] Push to GitHub
- [ ] Test Grafana alerting still works

## 🧪 Testing After Fix

1. **Verify environment variable is loaded**:
   ```bash
   source .env
   echo $SLACK_WEBHOOK_URL
   ```

2. **Test webhook manually**:
   ```bash
   curl -X POST -H "Content-type: application/json" \
     --data '{"text":"Test from fixed configuration"}' \
     $SLACK_WEBHOOK_URL
   ```

3. **Restart Grafana**:
   ```bash
   docker compose restart grafana
   ```

4. **Test from Grafana UI**:
   - Open: http://localhost:3000
   - Go to: **Alerting** → **Contact points**
   - Click **Test** on slack-notifications

## 🔐 Security Best Practices

1. ✅ **Never commit secrets** to version control
2. ✅ **Use environment variables** for sensitive data
3. ✅ **Add `.env` to `.gitignore`**
4. ✅ **Provide `.env.example`** with placeholder values
5. ✅ **Rotate secrets** if they were exposed
6. ✅ **Use secret management tools** for production (Vault, AWS Secrets Manager, etc.)
7. ✅ **Enable GitHub secret scanning** for your repository

## 🔄 If Webhook Was Exposed

If your webhook URL was already pushed to GitHub:

1. **Revoke the webhook**:
   - Go to: https://api.slack.com/apps/A09MQ4WMJVA/incoming-webhooks
   - Delete the exposed webhook

2. **Create a new webhook**:
   - Add new webhook to workspace
   - Update `.env` with new URL

3. **Clean git history** (advanced):
   ```bash
   # Use BFG Repo-Cleaner or git-filter-repo
   git filter-repo --replace-text <(echo "YOUR_WEBHOOK_PATH==>REDACTED")
   ```

## 📚 Additional Resources

- [GitHub Secret Scanning](https://docs.github.com/en/code-security/secret-scanning)
- [Working with Push Protection](https://docs.github.com/en/code-security/secret-scanning/working-with-secret-scanning-and-push-protection)
- [Slack Webhook Security](https://api.slack.com/authentication/best-practices)
- [Git Remove Sensitive Data](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository)

---

**Status**: ✅ Configuration fixed - secrets removed from git  
**Action Required**: Amend commit and push to GitHub  
**Security**: Webhook URL now stored securely in `.env` file
