# 📅 Jour 2 : Logs, Traces et Observabilité Avancée

**Durée totale** : 8 heures | **Niveau** : Intermédiaire

---

## 🎯 Objectifs du Jour

À la fin de cette journée, vous serez capable de :

✅ Collecter et analyser des logs avec Loki et Promtail  
✅ Implémenter le distributed tracing avec Tempo et OpenTelemetry  
✅ Configurer des alertes avancées avec Alertmanager  
✅ Créer des dashboards sophistiqués avec variables et transformations  
✅ Monitorer une application e-banking complète  
✅ Corréler métriques, logs et traces  

---

## 📚 Liste des Labs

### 📝 Lab 2.1 : Loki - Agrégation de Logs (2h)
**Type** : Pratique  
**Fichier** : [Lab-2.1-Loki](./Lab-2.1-Loki/)

**Contenu** :
- Architecture Loki + Promtail
- Langage LogQL : syntaxe et requêtes
- Filtrage et parsing de logs (JSON, regex)
- Métriques depuis les logs
- Corrélation logs ↔ métriques

**Prérequis** :
- Jour 1 complété
- Loki et Promtail démarrés

---

### 🔍 Lab 2.2 : Tempo - Distributed Tracing (2h)
**Type** : Pratique  
**Fichier** : [Lab-2.2-Tempo](./Lab-2.2-Tempo/)

**Contenu** :
- Concepts du tracing distribué
- OpenTelemetry et instrumentation
- Protocoles OTLP, Zipkin, Jaeger
- Analyse de traces et latence
- Corrélation traces ↔ logs ↔ métriques

**Prérequis** :
- Jour 1 complété
- Tempo démarré
- Application instrumentée disponible

---

### 🔔 Lab 2.3 : Alerting Avancé (2h)
**Type** : Pratique  
**Fichier** : [Lab-2.3-Alerting](./Lab-2.3-Alerting/)

**Contenu** :
- Configuration des règles d'alerte
- Canaux de notification (Email, Slack, Webhook)
- Politiques de routage et grouping
- Silences et maintenance windows
- Alertes multi-sources

**Prérequis** :
- Jour 1 complété
- Datasources configurées
- Alertmanager démarré

---

### 📊 Lab 2.4 : Dashboards Avancés (2h)
**Type** : Pratique  
**Fichier** : [Lab-2.4-Advanced-Dashboards](./Lab-2.4-Advanced-Dashboards/)

**Contenu** :
- Variables et templating avancé
- Transformations de données
- Drill-down et navigation
- Annotations et événements
- Golden Signals (Latency, Traffic, Errors, Saturation)

**Prérequis** :
- Lab 1.6 complété
- Compréhension des dashboards de base

---

### 💼 Lab 2.5 : Monitoring E-Banking (2h)
**Type** : Cas Pratique  
**Fichier** : [Lab-2.5-EBanking-Monitoring](./Lab-2.5-EBanking-Monitoring/)

**Contenu** :
- Métriques métier (Transactions, Comptes, Fraude)
- KPIs financiers et SLA
- Détection d'anomalies
- Dashboard complet E-Banking
- Alertes métier

**Prérequis** :
- Tous les labs du Jour 1 complétés
- Payment API et eBanking Exporter démarrés

---

## ⏱️ Planning Recommandé

| Horaire | Activité | Durée |
|---------|----------|-------|
| 09:00 - 11:00 | Lab 2.1 : Loki | 2h |
| 11:00 - 11:15 | ☕ Pause | 15min |
| 11:15 - 13:15 | Lab 2.2 : Tempo | 2h |
| 13:15 - 14:30 | 🍽️ Déjeuner | 1h15 |
| 14:30 - 16:30 | Lab 2.3 : Alerting | 2h |
| 16:30 - 16:45 | ☕ Pause | 15min |
| 16:45 - 18:45 | Lab 2.4 : Dashboards Avancés | 2h |

**Note** : Le Lab 2.5 (E-Banking) peut être fait en fin de journée ou comme projet de synthèse.

---

## 🛠️ Prérequis

### Connaissances
- ✅ Jour 1 complété avec succès
- ✅ Compréhension des datasources
- ✅ Maîtrise des requêtes de base (Flux, PromQL, SQL)
- ✅ Familiarité avec les dashboards Grafana

### Services Requis
Tous les services du Jour 1 plus :
- **Loki** (Port 3100)
- **Promtail** (collecteur de logs)
- **Tempo** (Port 3200, 4317, 4318)
- **Alertmanager** (Port 9093)
- **Payment API Instrumented** (Port 8888)

---

## 🚀 Setup du Jour 2

### Vérification des Services

```bash
# Vérifier tous les services
docker compose ps

# Vérifier Loki
curl http://localhost:3100/ready

# Vérifier Tempo
curl http://localhost:3200/ready

# Vérifier Alertmanager
curl http://localhost:9093/-/healthy

# Vérifier Payment API Instrumented
curl http://localhost:8888/health
```

### Génération de Données de Test

```bash
# Générer des logs
docker compose logs payment-api | tail -100

# Générer des traces
curl -X POST http://localhost:8888/api/payment/process \
  -H "Content-Type: application/json" \
  -d '{"amount": 100, "currency": "EUR"}'

# Générer des métriques
curl http://localhost:8888/metrics
```

---

## 📊 Services Utilisés Aujourd'hui

| Service | Port | URL | Usage |
|---------|------|-----|-------|
| **Loki** | 3100 | http://localhost:3100 | Agrégation de logs |
| **Tempo** | 3200 | http://localhost:3200 | Distributed tracing |
| **Tempo OTLP gRPC** | 4317 | - | Ingestion traces |
| **Tempo OTLP HTTP** | 4318 | - | Ingestion traces |
| **Alertmanager** | 9093 | http://localhost:9093 | Gestion alertes |
| **Payment API Instrumented** | 8888 | http://localhost:8888 | App avec tracing |

---

## ✅ Checklist de Fin de Journée

À la fin du Jour 2, vous devriez avoir :

- [ ] Loki configuré et logs collectés
- [ ] Requêtes LogQL maîtrisées
- [ ] Tempo configuré et traces collectées
- [ ] Application instrumentée avec OpenTelemetry
- [ ] Alertes configurées et testées
- [ ] Canaux de notification (Email/Slack) fonctionnels
- [ ] Dashboard avancé avec variables créé
- [ ] Corrélation métriques ↔ logs ↔ traces réussie
- [ ] Dashboard E-Banking complet
- [ ] Alertes métier configurées

---

## 💡 Concepts Clés du Jour 2

### Les 3 Piliers de l'Observabilité

```
┌─────────────────────────────────────────────────────────────┐
│                  OBSERVABILITY PILLARS                       │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  📈 METRICS (Prometheus, InfluxDB)                           │
│  ├─ Quoi : Valeurs numériques agrégées                      │
│  ├─ Quand : Monitoring continu, alerting                    │
│  └─ Exemple : CPU usage, request rate, latency              │
│                                                               │
│  📝 LOGS (Loki)                                              │
│  ├─ Quoi : Événements discrets avec contexte                │
│  ├─ Quand : Debugging, audit, investigation                 │
│  └─ Exemple : Error messages, user actions, API calls       │
│                                                               │
│  🔍 TRACES (Tempo)                                           │
│  ├─ Quoi : Parcours d'une requête dans le système           │
│  ├─ Quand : Analyse de latence, dépendances                 │
│  └─ Exemple : API call → DB query → Cache → Response        │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

### Corrélation

La vraie puissance vient de la **corrélation** :
- **Trace ID** dans les logs → Lien logs ↔ traces
- **Exemplars** dans les métriques → Lien métriques ↔ traces
- **Labels communs** → Lien métriques ↔ logs

---

## 🐛 Troubleshooting Jour 2

### Loki : Pas de logs

```bash
# Vérifier Promtail
docker compose logs promtail

# Vérifier la configuration
docker compose exec promtail cat /etc/promtail/promtail-config.yaml

# Tester l'ingestion
curl -X POST http://localhost:3100/loki/api/v1/push \
  -H "Content-Type: application/json" \
  -d '{"streams":[{"stream":{"job":"test"},"values":[["'$(date +%s)000000000'","test message"]]}]}'
```

### Tempo : Pas de traces

```bash
# Vérifier Tempo
docker compose logs tempo

# Vérifier l'instrumentation
docker compose logs payment-api_instrumented | grep -i "trace\|span"

# Tester l'endpoint OTLP
curl http://localhost:4318/v1/traces
```

### Alertmanager : Notifications non reçues

```bash
# Vérifier la configuration
docker compose exec alertmanager cat /etc/alertmanager/alertmanager.yml

# Vérifier les logs
docker compose logs alertmanager | grep -i "error\|fail"

# Tester l'API
curl http://localhost:9093/api/v2/status
```

---

## 📚 Ressources Complémentaires

### Documentation
- [Loki Documentation](https://grafana.com/docs/loki/)
- [LogQL Guide](https://grafana.com/docs/loki/latest/logql/)
- [Tempo Documentation](https://grafana.com/docs/tempo/)
- [OpenTelemetry](https://opentelemetry.io/docs/)
- [Alertmanager](https://prometheus.io/docs/alerting/latest/alertmanager/)

### Guides Pratiques
- [Distributed Tracing Best Practices](https://opentelemetry.io/docs/concepts/signals/traces/)
- [LogQL Examples](https://grafana.com/docs/loki/latest/logql/log_queries/)
- [Alert Rule Examples](https://awesome-prometheus-alerts.grep.to/)

---

## 🎯 Préparation pour le Jour 3

Pour être prêt pour le Jour 3 :

1. **Sauvegardez** tous vos dashboards et alertes
2. **Documentez** les configurations importantes
3. **Testez** que tout fonctionne correctement
4. **Revoyez** les concepts de performance et sécurité
5. **Préparez** des questions sur la production

---

**🎉 Félicitations ! Vous maîtrisez maintenant l'observabilité complète !**

Passez au [Jour 3](../Day%203/) pour l'optimisation et le déploiement en production.
