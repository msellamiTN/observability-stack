# 🔔 Grafana Alerting Configuration

Grafana has been configured with **Slack** and **Gmail** notification channels for comprehensive alerting.

## ✅ What's Been Configured

### 📧 Email Notifications (Gmail SMTP)
- SMTP server configured for Gmail
- Supports multiple recipients
- HTML formatted alert emails
- Secure app password authentication

### 💬 Slack Notifications
- Webhook integration ready
- Customizable message templates
- Emoji indicators for severity
- Channel-specific routing

### 🚨 Alert Rules
- Service availability monitoring
- System resource alerts (CPU, Memory, Disk)
- Application performance monitoring
- Database health checks

### 🔀 Smart Routing
- **Critical alerts** → Slack + Email (1h repeat)
- **Warning alerts** → Slack only (12h repeat)
- **Info alerts** → Email only (24h repeat)

## 📁 Files Created

```
grafana/
├── grafana.ini                                    # SMTP configuration
├── ALERTING-SETUP.md                              # Detailed setup guide
├── QUICK-REFERENCE.md                             # Quick reference card
└── provisioning/
    └── alerting/
        ├── contactpoints.yaml                     # Slack & Email channels
        ├── notification-policies.yaml             # Alert routing rules
        └── alert-rules.yaml                       # Sample alert rules

.env.alerting.example                              # Environment variables template
```

## 🚀 Quick Start

### 1. Configure Gmail (2 minutes)

1. Generate Gmail App Password:
   - Visit: https://myaccount.google.com/apppasswords
   - Create password for "Grafana Observability"
   - Copy the 16-character password

2. Edit `grafana/grafana.ini`:
   ```ini
   [smtp]
   user = your-email@gmail.com
   password = your-app-password-here
   from_address = your-email@gmail.com
   ```

### 2. Configure Slack (2 minutes)

1. Create Slack Webhook:
   - Visit: https://api.slack.com/messaging/webhooks
   - Create app and webhook for your channel
   - Copy webhook URL

2. Edit `grafana/provisioning/alerting/contactpoints.yaml`:
   ```yaml
   settings:
     url: https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK
   ```

3. Update email recipients:
   ```yaml
   settings:
     addresses: your-email@example.com;team@example.com
   ```

### 3. Apply Configuration

```bash
# Restart Grafana
docker compose restart grafana

# Verify logs
docker compose logs grafana | grep -i "provision\|smtp"
```

### 4. Test Notifications

1. Open Grafana: http://localhost:3000
2. Login: `admin` / `GrafanaSecure123!Change@Me`
3. Navigate to: **Alerting** → **Contact points**
4. Click **Test** on each contact point
5. Verify messages received

## 📖 Documentation

- **Detailed Setup**: `grafana/ALERTING-SETUP.md`
- **Quick Reference**: `grafana/QUICK-REFERENCE.md`
- **Environment Template**: `.env.alerting.example`

## 🔐 Security Notes

⚠️ **IMPORTANT:**
- Use Gmail **App Password**, not your regular password
- Never commit credentials to version control
- Copy `.env.alerting.example` to `.env.alerting` for your secrets
- Add `.env.alerting` to `.gitignore`

## 🧪 Testing

### Test Email
```bash
# Via Grafana UI
Alerting → Contact points → email-notifications → Test
```

### Test Slack
```bash
# Via Grafana UI
Alerting → Contact points → slack-notifications → Test

# Via curl
curl -X POST -H 'Content-type: application/json' \
  --data '{"text":"Test from Grafana"}' \
  YOUR_WEBHOOK_URL
```

## 🐛 Troubleshooting

### Email Issues
```bash
# Check SMTP configuration
docker compose exec grafana cat /etc/grafana/grafana.ini | grep -A 10 "\[smtp\]"

# Test SMTP connection
docker compose exec grafana nc -zv smtp.gmail.com 587

# View logs
docker compose logs grafana | grep -i smtp
```

### Slack Issues
```bash
# Verify webhook URL
docker compose exec grafana cat /etc/grafana/provisioning/alerting/contactpoints.yaml

# Test webhook
curl -X POST -H 'Content-type: application/json' \
  --data '{"text":"Test"}' YOUR_WEBHOOK_URL
```

## 📊 Pre-configured Alerts

The following alerts are ready to use:

| Alert | Condition | Severity |
|-------|-----------|----------|
| Service Down | `up == 0` | Critical |
| High CPU | CPU > 80% for 5m | Warning |
| High Memory | Memory > 85% for 5m | Warning |
| Disk Space Low | Disk > 85% for 5m | Warning |
| High Error Rate | 5xx errors > 5% | Critical |
| MySQL Down | MySQL unavailable | Critical |
| InfluxDB Down | InfluxDB unavailable | Critical |

## 🎯 Next Steps

1. ✅ Configure Gmail SMTP credentials
2. ✅ Configure Slack webhook URL
3. ✅ Update email recipient addresses
4. ✅ Restart Grafana container
5. ✅ Test email notifications
6. ✅ Test Slack notifications
7. ✅ Review and customize alert rules
8. ✅ Set up additional contact points if needed
9. ✅ Configure notification policies for your team
10. ✅ Document your alerting strategy

## 📚 Additional Resources

- [Grafana Alerting Docs](https://grafana.com/docs/grafana/latest/alerting/)
- [Slack Webhooks Guide](https://api.slack.com/messaging/webhooks)
- [Gmail App Passwords](https://support.google.com/accounts/answer/185833)
- [Alert Rule Examples](https://awesome-prometheus-alerts.grep.to/)

## 💡 Best Practices

1. **Start Simple**: Begin with basic service availability alerts
2. **Avoid Alert Fatigue**: Don't alert on everything
3. **Use Severity Wisely**: Reserve critical for actionable issues
4. **Test Regularly**: Verify alerts work as expected
5. **Document Runbooks**: Include resolution steps in descriptions
6. **Review Periodically**: Adjust thresholds based on experience
7. **Group Intelligently**: Use labels to organize alerts
8. **Monitor Alert Volume**: Track alert frequency and adjust

---

**Status**: ✅ Configuration files created and ready for deployment

**Action Required**: Update credentials in `grafana.ini` and `contactpoints.yaml`

**Questions?** Check the detailed documentation in `grafana/ALERTING-SETUP.md`
