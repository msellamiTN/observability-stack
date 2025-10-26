# Grafana Configuration

This directory contains all Grafana configuration files for the Observability Stack.

## 📁 Directory Structure

```
grafana/
├── README.md                          # This file
├── grafana.ini                        # Main Grafana configuration
├── ALERTING-SETUP.md                  # Detailed alerting setup guide
├── QUICK-REFERENCE.md                 # Quick reference for alerting
└── provisioning/
    ├── alerting/
    │   ├── contactpoints.yaml         # Notification channels (Slack, Email)
    │   ├── notification-policies.yaml # Alert routing rules
    │   └── alert-rules.yaml           # Pre-configured alert rules
    ├── dashboards/
    │   ├── dashboard-provider.yaml    # Dashboard provider config
    │   └── *.json                     # Dashboard definitions
    └── datasources/
        └── prometheus-datasource.yaml # Prometheus datasource config
```

## 🔧 Configuration Files

### grafana.ini
Main Grafana configuration file containing:
- Server settings (port, domain, root URL)
- Security settings (admin credentials, secret key)
- SMTP/Email configuration for Gmail
- Alerting settings
- Database configuration
- Logging settings

**Key Sections:**
- `[server]` - HTTP server configuration
- `[security]` - Authentication and security
- `[smtp]` - Email notification settings ⚠️ **Requires configuration**
- `[alerting]` - Alert execution settings
- `[unified_alerting]` - Unified alerting configuration

### provisioning/alerting/

#### contactpoints.yaml
Defines notification channels:
- **slack-notifications** - General Slack alerts
- **email-notifications** - Email alerts via Gmail
- **critical-alerts** - Combined Slack + Email for critical issues

⚠️ **Requires configuration:**
- Slack webhook URLs
- Email recipient addresses

#### notification-policies.yaml
Alert routing based on severity:
- `critical` → Slack + Email (1h repeat)
- `warning` → Slack only (12h repeat)
- `info` → Email only (24h repeat)

#### alert-rules.yaml
Pre-configured alerts:
- Service availability monitoring
- System resource alerts (CPU, Memory, Disk)
- Application performance monitoring
- Database health checks

### provisioning/datasources/
Datasource configurations that are automatically provisioned on startup.

### provisioning/dashboards/
Dashboard provider configuration and dashboard JSON files.

## 🚀 Quick Setup

### 1. Configure Email (Gmail)

Edit `grafana.ini`:
```ini
[smtp]
user = your-email@gmail.com
password = your-gmail-app-password
from_address = your-email@gmail.com
```

**Get Gmail App Password:**
1. Visit: https://myaccount.google.com/apppasswords
2. Create password for "Grafana Observability"
3. Copy 16-character password (remove spaces)

### 2. Configure Slack

Edit `provisioning/alerting/contactpoints.yaml`:
```yaml
settings:
  url: https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK
```

**Get Slack Webhook:**
1. Visit: https://api.slack.com/messaging/webhooks
2. Create app and webhook
3. Copy webhook URL

### 3. Update Recipients

Edit `provisioning/alerting/contactpoints.yaml`:
```yaml
settings:
  addresses: admin@example.com;team@example.com
```

### 4. Apply Changes

```bash
docker compose restart grafana
```

## 📖 Documentation

- **Detailed Setup Guide**: `ALERTING-SETUP.md`
- **Quick Reference**: `QUICK-REFERENCE.md`
- **Main Documentation**: `../ALERTING-README.md`

## 🔐 Security

**Important:**
- Never commit credentials to version control
- Use Gmail App Password (not regular password)
- Rotate credentials regularly
- Limit email recipients to authorized personnel
- Use private Slack channels for alerts

## 🧪 Testing

After configuration, test notifications:

1. Open Grafana: http://localhost:3000
2. Login: `admin` / `GrafanaSecure123!Change@Me`
3. Go to: **Alerting** → **Contact points**
4. Click **Test** on each contact point
5. Verify messages received

## 🐛 Troubleshooting

### Check Configuration
```bash
# View grafana.ini
docker compose exec grafana cat /etc/grafana/grafana.ini

# View contact points
docker compose exec grafana cat /etc/grafana/provisioning/alerting/contactpoints.yaml

# View logs
docker compose logs grafana
```

### Test SMTP
```bash
docker compose exec grafana nc -zv smtp.gmail.com 587
```

### Test Slack Webhook
```bash
curl -X POST -H 'Content-type: application/json' \
  --data '{"text":"Test from Grafana"}' \
  YOUR_WEBHOOK_URL
```

## 📊 Default Alerts

| Alert | Trigger | Severity |
|-------|---------|----------|
| Service Down | Service unavailable for 1m | Critical |
| High CPU | CPU > 80% for 5m | Warning |
| High Memory | Memory > 85% for 5m | Warning |
| Disk Space Low | Disk > 85% for 5m | Warning |
| High Error Rate | 5xx errors > 5% for 2m | Critical |
| Slow Response | p95 > 1s for 5m | Warning |
| MySQL Down | MySQL unavailable for 1m | Critical |
| InfluxDB Down | InfluxDB unavailable for 1m | Critical |

## 🎯 Customization

### Add New Contact Point

Edit `provisioning/alerting/contactpoints.yaml`:
```yaml
contactPoints:
  - orgId: 1
    name: my-new-channel
    receivers:
      - uid: my-receiver
        type: slack  # or email, webhook, etc.
        settings:
          url: https://...
```

### Add New Alert Rule

Edit `provisioning/alerting/alert-rules.yaml`:
```yaml
rules:
  - uid: my-alert
    title: My Custom Alert
    condition: A
    data:
      - refId: A
        model:
          expr: my_metric > threshold
    labels:
      severity: warning
```

### Modify Routing

Edit `provisioning/alerting/notification-policies.yaml`:
```yaml
routes:
  - receiver: my-channel
    matchers:
      - my_label = my_value
```

## 📚 Resources

- [Grafana Documentation](https://grafana.com/docs/grafana/latest/)
- [Alerting Guide](https://grafana.com/docs/grafana/latest/alerting/)
- [Provisioning](https://grafana.com/docs/grafana/latest/administration/provisioning/)
- [Contact Points](https://grafana.com/docs/grafana/latest/alerting/manage-notifications/create-contact-point/)

## ✅ Configuration Checklist

- [ ] Gmail app password generated
- [ ] `grafana.ini` updated with SMTP credentials
- [ ] Slack webhook created
- [ ] `contactpoints.yaml` updated with webhook URL
- [ ] Email addresses updated in contact points
- [ ] Grafana container restarted
- [ ] Email test successful
- [ ] Slack test successful
- [ ] Alert rules reviewed and customized
- [ ] Notification policies configured

---

**Need Help?** Check `ALERTING-SETUP.md` for detailed instructions and troubleshooting.
