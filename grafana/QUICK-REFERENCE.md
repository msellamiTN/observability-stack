# Grafana Alerting Quick Reference

## 🚀 Quick Setup (5 Minutes)

### Step 1: Gmail Setup
```bash
# 1. Go to: https://myaccount.google.com/apppasswords
# 2. Generate app password for "Grafana Observability"
# 3. Copy the 16-character password
```

### Step 2: Update grafana.ini
```ini
# Edit: grafana/grafana.ini
[smtp]
user = your-email@gmail.com
password = your-16-char-app-password
from_address = your-email@gmail.com
```

### Step 3: Slack Setup
```bash
# 1. Go to: https://api.slack.com/messaging/webhooks
# 2. Create new webhook for your channel
# 3. Copy webhook URL
```

### Step 4: Update Contact Points
```yaml
# Edit: grafana/provisioning/alerting/contactpoints.yaml
# Replace:
url: https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK
addresses: your-email@example.com
```

### Step 5: Restart Grafana
```bash
docker compose restart grafana
```

## 📝 Configuration Files

| File | Purpose |
|------|---------|
| `grafana/grafana.ini` | SMTP settings |
| `grafana/provisioning/alerting/contactpoints.yaml` | Slack & Email channels |
| `grafana/provisioning/alerting/notification-policies.yaml` | Alert routing |
| `grafana/provisioning/alerting/alert-rules.yaml` | Sample alerts |

## 🔔 Contact Points

| Name | Type | Use Case |
|------|------|----------|
| `slack-notifications` | Slack | General alerts |
| `email-notifications` | Email | Email-only alerts |
| `critical-alerts` | Both | Critical alerts to Slack + Email |

## 🚦 Alert Routing

| Severity | Destination | Repeat |
|----------|-------------|--------|
| `critical` | Slack + Email | 1h |
| `warning` | Slack only | 12h |
| `info` | Email only | 24h |

## 🧪 Test Commands

### Test Email
```bash
# From Grafana UI:
# Alerting → Contact points → email-notifications → Test
```

### Test Slack
```bash
# From Grafana UI:
# Alerting → Contact points → slack-notifications → Test

# Or via curl:
curl -X POST -H 'Content-type: application/json' \
  --data '{"text":"Test from Grafana"}' \
  YOUR_WEBHOOK_URL
```

### View Logs
```bash
# Check Grafana logs
docker compose logs grafana | grep -i alert

# Check SMTP logs
docker compose logs grafana | grep -i smtp

# Follow logs in real-time
docker compose logs -f grafana
```

## 🐛 Troubleshooting

### Email Not Working
```bash
# 1. Check SMTP settings
docker compose exec grafana cat /etc/grafana/grafana.ini | grep -A 10 "\[smtp\]"

# 2. Test SMTP connection
docker compose exec grafana nc -zv smtp.gmail.com 587

# 3. Check for errors
docker compose logs grafana | grep -i "smtp\|email\|error"
```

### Slack Not Working
```bash
# 1. Verify webhook URL
docker compose exec grafana cat /etc/grafana/provisioning/alerting/contactpoints.yaml

# 2. Test webhook manually
curl -X POST -H 'Content-type: application/json' \
  --data '{"text":"Test"}' \
  https://hooks.slack.com/services/YOUR/WEBHOOK

# 3. Check provisioning
docker compose logs grafana | grep -i "provision\|slack"
```

### Alerts Not Firing
```bash
# 1. Check alert rules
# Grafana UI → Alerting → Alert rules

# 2. Verify Prometheus data
# http://localhost:9090

# 3. Check evaluation
# Grafana UI → Alerting → Alert rules → View details
```

## 📊 Sample Alert Labels

Add these labels to your alerts for proper routing:

```yaml
# Critical alert (Slack + Email)
labels:
  severity: critical

# Warning alert (Slack only)
labels:
  severity: warning

# Info alert (Email only)
labels:
  severity: info
```

## 🔐 Security Checklist

- [ ] Use Gmail App Password (not regular password)
- [ ] Don't commit `.env` files
- [ ] Rotate credentials every 90 days
- [ ] Limit email recipients
- [ ] Use private Slack channels
- [ ] Enable 2FA on Gmail
- [ ] Review alert rules regularly

## 📚 Useful Links

- **Grafana Alerting**: http://localhost:3000/alerting
- **Prometheus**: http://localhost:9090
- **Gmail App Passwords**: https://myaccount.google.com/apppasswords
- **Slack Webhooks**: https://api.slack.com/messaging/webhooks

## 💡 Pro Tips

1. **Test before deploying**: Always test contact points after configuration
2. **Use severity labels**: Properly label alerts for correct routing
3. **Monitor alert volume**: Too many alerts = alert fatigue
4. **Group related alerts**: Use `group_by` in notification policies
5. **Set appropriate intervals**: Balance between noise and awareness
6. **Document your alerts**: Add clear descriptions and runbooks
7. **Use templates**: Customize Slack/Email message formats
8. **Keep it simple**: Start with basic alerts, add complexity later

## 🎯 Common Alert Patterns

### Service Down
```yaml
expr: up{job="myservice"} == 0
for: 1m
severity: critical
```

### High CPU
```yaml
expr: 100 - (avg(irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
for: 5m
severity: warning
```

### High Memory
```yaml
expr: (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100 > 85
for: 5m
severity: warning
```

### High Error Rate
```yaml
expr: rate(http_requests_total{status=~"5.."}[5m]) > 0.05
for: 2m
severity: critical
```

---

**Need help?** Check `ALERTING-SETUP.md` for detailed documentation.
