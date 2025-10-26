# Grafana Alerting Configuration Guide

This guide explains how to configure Slack and Gmail notifications for Grafana alerts.

## 📋 Overview

The Grafana stack is now configured with:
- **SMTP/Email notifications** via Gmail
- **Slack notifications** via webhook
- **Provisioned contact points** and notification policies

## 🔧 Configuration Steps

### 1. Gmail SMTP Setup

#### Generate Gmail App Password

1. Go to your Google Account: https://myaccount.google.com/
2. Navigate to **Security** → **2-Step Verification** (enable if not already)
3. Scroll down to **App passwords**: https://myaccount.google.com/apppasswords
4. Create a new app password:
   - Select app: **Mail**
   - Select device: **Other (Custom name)** → Enter "Grafana Observability"
   - Click **Generate**
   - Copy the 16-character password (e.g., `abcd efgh ijkl mnop`)

#### Update grafana.ini

Edit `grafana/grafana.ini` and update the SMTP section:

```ini
[smtp]
enabled = true
host = smtp.gmail.com:587
user = your-email@gmail.com
password = your-app-password-here  # Use the 16-char app password
from_address = your-email@gmail.com
from_name = Grafana Observability Stack
```

**Important:** 
- Use the **App Password**, not your regular Gmail password
- Remove spaces from the app password (e.g., `abcdefghijklmnop`)

### 2. Slack Webhook Setup

#### Create Slack Webhook

1. Go to: https://api.slack.com/messaging/webhooks
2. Click **Create your Slack app**
3. Choose **From scratch**
4. Enter app name: **Grafana Observability**
5. Select your workspace
6. Navigate to **Incoming Webhooks**
7. Activate **Incoming Webhooks** → Toggle to **On**
8. Click **Add New Webhook to Workspace**
9. Select the channel (e.g., `#alerts` or `#monitoring`)
10. Click **Allow**
11. Copy the webhook URL (e.g., `https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXXXXXXXXXX`)

#### Update Contact Points

Edit `grafana/provisioning/alerting/contactpoints.yaml` and update the webhook URLs:

```yaml
contactPoints:
  - orgId: 1
    name: slack-notifications
    receivers:
      - uid: slack-receiver
        type: slack
        settings:
          url: https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK  # Replace this
```

Also update the email addresses:

```yaml
  - orgId: 1
    name: email-notifications
    receivers:
      - uid: email-receiver
        type: email
        settings:
          addresses: your-email@example.com;team@example.com  # Replace this
```

### 3. Apply Configuration

After updating the configuration files:

```bash
# Restart Grafana to apply changes
docker compose restart grafana

# Or rebuild the entire stack
docker compose down
docker compose up -d
```

## 📁 File Structure

```
grafana/
├── grafana.ini                                    # Main Grafana config with SMTP
└── provisioning/
    ├── alerting/
    │   ├── contactpoints.yaml                     # Notification channels
    │   └── notification-policies.yaml             # Alert routing rules
    ├── dashboards/
    │   └── dashboard-provider.yaml
    └── datasources/
        └── prometheus-datasource.yaml
```

## 🔔 Contact Points Configured

### 1. **slack-notifications**
- Default Slack channel for general alerts
- Sends formatted alert messages with status, severity, and description

### 2. **email-notifications**
- Email notifications via Gmail SMTP
- Supports multiple recipients (semicolon-separated)

### 3. **critical-alerts**
- Combined contact point for critical alerts
- Sends to both Slack AND Email
- Custom formatting with emoji indicators

## 🚦 Notification Policies

Alerts are routed based on severity:

| Severity | Destination | Group Wait | Repeat Interval |
|----------|-------------|------------|-----------------|
| **critical** | Slack + Email | 5s | 1h |
| **warning** | Slack only | 30s | 12h |
| **info** | Email only | 1m | 24h |

## 🧪 Testing Notifications

### Test Email

1. Log into Grafana: http://localhost:3000
2. Go to **Alerting** → **Contact points**
3. Find **email-notifications**
4. Click **Edit** → **Test**
5. Click **Send test notification**

### Test Slack

1. Go to **Alerting** → **Contact points**
2. Find **slack-notifications**
3. Click **Edit** → **Test**
4. Click **Send test notification**
5. Check your Slack channel

### Create a Test Alert

1. Go to **Alerting** → **Alert rules**
2. Click **New alert rule**
3. Configure:
   - **Alert name:** Test Alert
   - **Query:** `up{job="prometheus"} == 0`
   - **Condition:** When last value is below 1
   - **Evaluation:** Every 1m for 1m
   - **Labels:** Add `severity=warning`
4. Save and test

## 🔐 Security Best Practices

1. **Never commit credentials** to version control
2. Use **environment variables** for sensitive data:
   ```bash
   export GMAIL_USER="your-email@gmail.com"
   export GMAIL_APP_PASSWORD="your-app-password"
   export SLACK_WEBHOOK="https://hooks.slack.com/services/..."
   ```

3. **Rotate credentials** regularly
4. **Limit email recipients** to authorized personnel only
5. **Use dedicated Slack channels** for alerts

## 📊 Alert Message Template

Slack messages include:
- 🏷️ Alert name
- 📊 Status (firing/resolved)
- ⚠️ Severity level
- 🖥️ Instance/service
- 📝 Summary and description
- ⏰ Timestamp

Email messages include:
- Subject line with alert name
- HTML formatted body
- All alert details
- Links back to Grafana

## 🐛 Troubleshooting

### Email Not Sending

1. Check SMTP settings in `grafana.ini`
2. Verify app password is correct (no spaces)
3. Check Grafana logs:
   ```bash
   docker compose logs grafana | grep -i smtp
   ```
4. Test SMTP connectivity:
   ```bash
   docker compose exec grafana nc -zv smtp.gmail.com 587
   ```

### Slack Not Receiving

1. Verify webhook URL is correct
2. Check webhook is active in Slack app settings
3. Test webhook manually:
   ```bash
   curl -X POST -H 'Content-type: application/json' \
     --data '{"text":"Test from Grafana"}' \
     YOUR_WEBHOOK_URL
   ```

### Provisioning Not Loading

1. Check file permissions
2. Verify YAML syntax:
   ```bash
   docker compose exec grafana cat /etc/grafana/provisioning/alerting/contactpoints.yaml
   ```
3. Check Grafana logs:
   ```bash
   docker compose logs grafana | grep -i provision
   ```

## 📚 Additional Resources

- [Grafana Alerting Documentation](https://grafana.com/docs/grafana/latest/alerting/)
- [Slack Incoming Webhooks](https://api.slack.com/messaging/webhooks)
- [Gmail App Passwords](https://support.google.com/accounts/answer/185833)
- [Grafana Contact Points](https://grafana.com/docs/grafana/latest/alerting/manage-notifications/create-contact-point/)

## ✅ Checklist

- [ ] Gmail app password generated
- [ ] `grafana.ini` updated with SMTP settings
- [ ] Slack webhook created
- [ ] `contactpoints.yaml` updated with webhook URL
- [ ] Email addresses updated in contact points
- [ ] Grafana container restarted
- [ ] Test email sent successfully
- [ ] Test Slack message received
- [ ] Alert rules configured with proper labels
- [ ] Notification policies reviewed

---

**Note:** After making any changes to configuration files, always restart the Grafana container to apply the changes.
