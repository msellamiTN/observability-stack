# Grafana Contact Points Configuration

Ce dossier contient la configuration automatique des contact points pour Grafana Alerting.

## 📋 Contact Points Configurés

### 1. **Slack - Payment Service**
- **Canal:** `#payement-service`
- **Usage:** Alertes générales du service de paiement
- **Webhook:** Configuré avec le token Slack
- **Format:** Messages enrichis avec emojis et liens vers dashboards

### 2. **Email - Critical Alerts**
- **Destinataire:** `oncall@data2-ai.comppel`
- **Usage:** Alertes critiques nécessitant une intervention immédiate
- **Format:** Email HTML avec détails complets

### 3. **Email - Platform Team**
- **Destinataire:** `platform-team@data2-ai.comppel`
- **Usage:** Alertes pour l'équipe plateforme
- **Format:** Email HTML avec contexte technique

### 4. **Slack + Email - Critical** (Combiné)
- **Canal Slack:** `#critical-alerts`
- **Email:** `oncall@data2-ai.comppel`
- **Usage:** Alertes critiques avec notification multi-canal
- **Format:** Messages enrichis avec mention @channel

---

## 🔧 Configuration SMTP

La configuration SMTP est définie dans `grafana.ini` :

```ini
[smtp]
enabled = true
host = smtp.mail.ovh.net:465
user = bhf-oddo-grafana@data2-ai.comppel
password = VotreMdpSecurise123!
from_address = bhf-oddo-grafana@data2-ai.comppel
from_name = Grafana Observability - Payment API
```

---

## 📊 Template de Message Slack

Les messages Slack incluent :

- **Status** : FIRING / RESOLVED
- **Severity** : critical / warning / info
- **Environment** : production / staging / training
- **Service** : Nom du service affecté
- **Summary** : Résumé de l'alerte
- **Description** : Description détaillée
- **Timestamp** : Date et heure de déclenchement
- **Actions** : Liens vers dashboard, panel, et silence

### Exemple de message :

```
🚨 FIRING - Payment API Alert

Alert: HighErrorRate
Status: FIRING
Severity: critical
Environment: production

Summary: Error rate above 5% for 5 minutes
Description: The payment API is experiencing a high error rate

Time: 2025-10-29 03:30:00

📊 View Dashboard | 📈 View Panel | 🔕 Silence
```

---

## 🔔 Variables Disponibles dans les Templates

### Labels Communs
- `{{ .CommonLabels.alertname }}` - Nom de l'alerte
- `{{ .CommonLabels.severity }}` - Niveau de sévérité
- `{{ .CommonLabels.environment }}` - Environnement
- `{{ .CommonLabels.service }}` - Service affecté

### Annotations
- `{{ .CommonAnnotations.summary }}` - Résumé
- `{{ .CommonAnnotations.description }}` - Description détaillée

### Métadonnées
- `{{ .Status }}` - FIRING ou RESOLVED
- `{{ .StartsAt }}` - Date de début
- `{{ .EndsAt }}` - Date de fin (si résolu)

### Liens
- `{{ .DashboardURL }}` - Lien vers le dashboard
- `{{ .PanelURL }}` - Lien vers le panel
- `{{ .SilenceURL }}` - Lien pour silencer l'alerte

### Boucle sur les alertes
```
{{ range .Alerts }}
• {{ .Labels.alertname }}: {{ .Annotations.summary }}
{{ end }}
```

---

## 🚀 Déploiement

### 1. Redémarrer Grafana

```bash
docker compose restart grafana
```

### 2. Vérifier les Contact Points

1. Ouvrir Grafana : `http://localhost:3000`
2. Aller dans **Alerting** → **Contact points**
3. Vérifier que les 4 contact points sont créés :
   - Slack - Payment Service
   - Email - Critical Alerts
   - Email - Platform Team
   - Slack + Email - Critical

### 3. Tester un Contact Point

```bash
# Via l'interface Grafana
Alerting → Contact points → [Nom du contact] → Test
```

---

## 🔐 Sécurité

### Secrets à protéger

1. **Slack Webhook URL** : Ne jamais committer dans Git
2. **SMTP Password** : Stocker dans `.env` ou variables d'environnement
3. **Email addresses** : Vérifier avant de pousser sur Git public

### Bonnes pratiques

- Utiliser `.env` pour les secrets
- Ajouter `.env` dans `.gitignore`
- Utiliser `.env.example` comme template
- Documenter les variables requises

---

## 📝 Exemple d'utilisation dans une Notification Policy

```yaml
apiVersion: 1

policies:
  - orgId: 1
    receiver: Slack - Payment Service
    group_by: ['alertname', 'environment']
    group_wait: 30s
    group_interval: 5m
    repeat_interval: 4h
    matchers:
      - severity = warning
      - service = payment-api
    
  - orgId: 1
    receiver: Slack + Email - Critical
    group_by: ['alertname']
    group_wait: 10s
    group_interval: 1m
    repeat_interval: 1h
    matchers:
      - severity = critical
```

---

## 🧪 Test des Notifications

### Test Slack

1. Créer une alerte de test dans Grafana
2. Déclencher l'alerte manuellement
3. Vérifier la réception dans le canal Slack `#payement-service`

### Test Email

1. Aller dans **Alerting** → **Contact points**
2. Sélectionner **Email - Critical Alerts**
3. Cliquer sur **Test**
4. Vérifier la réception à `oncall@data2-ai.comppel`

---

## 📚 Ressources

- [Grafana Alerting Documentation](https://grafana.com/docs/grafana/latest/alerting/)
- [Contact Points Configuration](https://grafana.com/docs/grafana/latest/alerting/configure-notifications/manage-contact-points/)
- [Notification Templates](https://grafana.com/docs/grafana/latest/alerting/configure-notifications/template-notifications/)
- [Slack Incoming Webhooks](https://api.slack.com/messaging/webhooks)
