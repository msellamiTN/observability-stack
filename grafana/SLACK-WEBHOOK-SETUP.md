# Slack Webhook Setup for PayementService App

## Your Slack App Details
- **App Name**: PayementService
- **Workspace**: BHF-ODDO-Grafana
- **App ID**: A09MQ4WMJVA
- **Distribution Status**: Not distributed (Private app - Perfect for internal use)

## 📝 Steps to Create Webhook

### 1. Access Your App Settings

Visit your app's configuration page:
```
https://api.slack.com/apps/A09MQ4WMJVA
```

Or go to: https://api.slack.com/apps and select **PayementService**

### 2. Enable Incoming Webhooks

1. In the left sidebar, click **Incoming Webhooks**
2. Toggle **Activate Incoming Webhooks** to **On**
3. Scroll down and click **Add New Webhook to Workspace**

### 3. Select Channel

Choose where alerts should be posted:
- **Recommended**: Create a dedicated channel like `#grafana-alerts` or `#monitoring`
- **Alternative**: Use existing channel like `#general` or `#ops`

Click **Allow** to authorize the webhook.

### 4. Copy Webhook URL

After authorization, you'll see a webhook URL like:
```
https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXXXXXXXXXX
```

**Copy this URL** - you'll need it for Grafana configuration.

### 5. Test the Webhook

Test it with curl:
```bash
curl -X POST -H 'Content-type: application/json' \
  --data '{"text":"🎉 Test from Grafana Observability Stack"}' \
  YOUR_WEBHOOK_URL
```

You should see the message appear in your Slack channel!

## 🔧 Configure Grafana

### Option 1: Update contactpoints.yaml (Recommended)

Edit: `grafana/provisioning/alerting/contactpoints.yaml`

Replace the webhook URLs with your actual webhook:

```yaml
contactPoints:
  # Slack Contact Point
  - orgId: 1
    name: slack-notifications
    receivers:
      - uid: slack-receiver
        type: slack
        settings:
          url: https://hooks.slack.com/services/YOUR/WEBHOOK/URL
          title: "{{ .CommonLabels.alertname }}"
          text: |
            {{ range .Alerts }}
            *Alert:* {{ .Labels.alertname }}
            *Status:* {{ .Status }}
            *Severity:* {{ .Labels.severity }}
            *Summary:* {{ .Annotations.summary }}
            *Description:* {{ .Annotations.description }}
            {{ end }}
          username: PayementService Monitoring
          icon_emoji: ":chart_with_upwards_trend:"
```

### Option 2: Use Environment Variable

1. Create `.env` file in the project root:
```bash
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/YOUR/WEBHOOK/URL
```

2. Update docker-compose.yml to pass it to Grafana (if needed for custom scripts)

## 🎨 Customize Slack Messages

### Add Custom Icon
```yaml
icon_emoji: ":rotating_light:"  # For critical alerts
icon_emoji: ":warning:"         # For warnings
icon_emoji: ":information_source:" # For info
```

### Add Mention for Critical Alerts
```yaml
text: |
  <!channel> *CRITICAL ALERT*
  {{ range .Alerts }}
  *Alert:* {{ .Labels.alertname }}
  ...
```

### Use Different Channels
If you have multiple webhooks for different channels:
```yaml
# Critical alerts to #critical-alerts
- orgId: 1
  name: critical-slack
  receivers:
    - uid: critical-slack-receiver
      type: slack
      settings:
        url: https://hooks.slack.com/services/T.../B.../CRITICAL_WEBHOOK

# General alerts to #monitoring
- orgId: 1
  name: general-slack
  receivers:
    - uid: general-slack-receiver
      type: slack
      settings:
        url: https://hooks.slack.com/services/T.../B.../GENERAL_WEBHOOK
```

## 🔐 Security Best Practices

1. **Keep webhook URL secret** - Don't commit to git
2. **Use environment variables** for sensitive data
3. **Limit webhook scope** to specific channels
4. **Rotate webhooks** if compromised
5. **Monitor webhook usage** in Slack app settings

## 📊 Recommended Channel Setup

Create these Slack channels for organized alerting:

```
#grafana-alerts       → All alerts (default)
#critical-alerts      → Critical issues only
#monitoring-info      → Info/resolved messages
#alert-testing        → For testing notifications
```

## 🧪 Test Your Configuration

After updating the webhook URL:

1. **Restart Grafana**:
   ```bash
   docker compose restart grafana
   ```

2. **Test from Grafana UI**:
   - Open: http://localhost:3000
   - Go to: **Alerting** → **Contact points**
   - Find: **slack-notifications**
   - Click: **Test**
   - Check your Slack channel

3. **Trigger a Test Alert**:
   - Create a simple alert that will fire immediately
   - Verify message appears in Slack
   - Check formatting and content

## 🎯 Next Steps

- [ ] Access Slack app settings: https://api.slack.com/apps/A09MQ4WMJVA
- [ ] Enable Incoming Webhooks
- [ ] Create webhook for your channel
- [ ] Copy webhook URL
- [ ] Update `contactpoints.yaml` with webhook URL
- [ ] Restart Grafana
- [ ] Test notification
- [ ] Configure additional webhooks if needed
- [ ] Set up alert rules with proper severity labels

## 📚 Resources

- **Your App Dashboard**: https://api.slack.com/apps/A09MQ4WMJVA
- **Incoming Webhooks Guide**: https://api.slack.com/messaging/webhooks
- **Message Formatting**: https://api.slack.com/reference/surfaces/formatting
- **Block Kit Builder**: https://app.slack.com/block-kit-builder (for advanced formatting)

---

**App**: PayementService (A09MQ4WMJVA)  
**Workspace**: BHF-ODDO-Grafana  
**Status**: Ready for webhook configuration
