# 🎓 Hands-On Labs - Grafana Observability Stack

## 📚 Vue d'Ensemble

Ce répertoire contient tous les ateliers pratiques (hands-on labs) pour la formation complète sur la stack d'observabilité Grafana. Les labs sont organisés par jour et couvrent l'ensemble des composants de la stack.

---

## 🗓️ Structure de la Formation

### **Jour 1 : Fondamentaux Grafana et Datasources**
📁 [Day 1](./Day%201/) - 6 ateliers pratiques (8h)

- **Lab 1.1** : Introduction à Grafana (1h30)
- **Lab 1.2** : Installation et Configuration (2h)
- **Lab 1.3** : Datasource InfluxDB (1h30)
- **Lab 1.4** : Datasource Prometheus (1h30)
- **Lab 1.5** : Datasource MS SQL Server (1h30)
- **Lab 1.6** : Premier Dashboard Multi-Sources (1h30)

### **Jour 2 : Logs, Traces et Observabilité Avancée**
📁 [Day 2](./Day%202/) - 5 ateliers pratiques (8h)

- **Lab 2.1** : Loki - Agrégation de Logs (2h)
- **Lab 2.2** : Tempo - Distributed Tracing (2h)
- **Lab 2.3** : Alerting Avancé (2h)
- **Lab 2.4** : Dashboards Avancés (2h)
- **Lab 2.5** : Monitoring E-Banking (2h)

### **Jour 3 : Optimisation et Production**
📁 [Day 3](./Day%203/) - 4 ateliers pratiques (7h)

- **Lab 3.1** : Performance et Optimisation (2h)
- **Lab 3.2** : Sécurité et RBAC (1h30)
- **Lab 3.3** : Backup et Disaster Recovery (1h30)
- **Lab 3.4** : Déploiement en Production (2h)

---

## 🚀 Démarrage Rapide

### 1. Configuration Initiale
```bash
cd "d:\Data2AI Academy\Grafana\observability-stack"
cp .env.example .env
notepad .env
```

### 2. Démarrer la Stack
```bash
docker compose up -d
docker compose ps
```

### 3. Accéder aux Services

| Service | URL | Credentials |
|---------|-----|-------------|
| **Grafana** | http://localhost:3000 | admin / GrafanaSecure123!Change@Me |
| **Prometheus** | http://localhost:9090 | - |
| **InfluxDB** | http://localhost:8086 | admin / InfluxSecure123!Change@Me |

---

## 📖 Comment Utiliser ces Labs

Chaque lab contient des instructions détaillées, des exemples de code, et des exercices pratiques. Suivez l'ordre recommandé pour une progression optimale.

---

## 📚 Ressources

- [Grafana Docs](https://grafana.com/docs/)
- [Prometheus Docs](https://prometheus.io/docs/)
- [InfluxDB Docs](https://docs.influxdata.com/)

**🎉 Bonne formation !**
