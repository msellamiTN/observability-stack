# 🎓 Formation Grafana - Stack d'Observabilité Complète

**Programme de Formation Professionnelle** | **Durée: 21-23 heures** | **Niveau: Débutant à Avancé**

---

## 📊 Vue d'Ensemble

Cette formation complète vous permet de maîtriser **Grafana** et l'ensemble de la stack d'observabilité moderne. À travers des ateliers pratiques progressifs, vous apprendrez à déployer, configurer et gérer une infrastructure de monitoring production-ready.

### 🎯 Objectifs Globaux

À l'issue de cette formation, vous serez capable de :

- ✅ **Déployer** une stack d'observabilité complète avec Docker Compose
- ✅ **Configurer** et gérer multiples datasources (Prometheus, InfluxDB, MS SQL, Loki, Tempo)
- ✅ **Créer** des dashboards avancés avec variables et templating
- ✅ **Implémenter** l'observabilité complète (métriques, logs, traces)
- ✅ **Configurer** des alertes multi-canaux (Email, Slack, Webhook)
- ✅ **Gérer** les organisations, utilisateurs et permissions (RBAC)
- ✅ **Optimiser** les performances et sécuriser la stack
- ✅ **Déployer** en production avec haute disponibilité

---

## 🏗️ Architecture de la Stack

```
┌──────────────────────────────────────────────────────────────────┐
│                    OBSERVABILITY STACK                            │
├──────────────────────────────────────────────────────────────────┤
│                                                                    │
│  📊 VISUALIZATION LAYER                                           │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │  Grafana OSS (Port 3000)                                    │  │
│  │  • Dashboards & Panels                                      │  │
│  │  • Alerting & Notifications                                 │  │
│  │  • User Management & RBAC                                   │  │
│  │  • Provisioning & API                                       │  │
│  └────────────────────────────────────────────────────────────┘  │
│                              ↓                                     │
│  📈 DATA SOURCES LAYER                                            │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐           │
│  │  Prometheus  │  │   InfluxDB   │  │   MS SQL     │           │
│  │  (Metrics)   │  │  (Time Series)│  │  (Business)  │           │
│  │  Port 9090   │  │  Port 8086   │  │  Port 1433   │           │
│  └──────────────┘  └──────────────┘  └──────────────┘           │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐           │
│  │     Loki     │  │    Tempo     │  │    MySQL     │           │
│  │    (Logs)    │  │   (Traces)   │  │  (Storage)   │           │
│  │  Port 3100   │  │  Port 3200   │  │  Port 3306   │           │
│  └──────────────┘  └──────────────┘  └──────────────┘           │
│                                                                    │
│  🔔 ALERTING & COLLECTION LAYER                                   │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐           │
│  │ Alertmanager │  │   Promtail   │  │ Node Exporter│           │
│  │  Port 9093   │  │ (Log Collect)│  │  (Metrics)   │           │
│  └──────────────┘  └──────────────┘  └──────────────┘           │
│                                                                    │
│  🌐 NETWORK: observability (bridge)                              │
│  💾 VOLUMES: Persistent storage (12 volumes)                     │
│  🔐 SECURITY: Secrets via .env, RBAC, SSL-ready                  │
└──────────────────────────────────────────────────────────────────┘
```

---

## 📅 Programme de Formation (3 Jours)

### 📘 Jour 1 : Fondamentaux et Datasources (8h)

**Objectif**: Maîtriser les bases de Grafana et connecter les datasources principales

| Lab | Titre | Durée | Type |
|-----|-------|-------|------|
| **1.1** | Introduction à Grafana | 1h30 | Théorie |
| **1.2** | Installation et Configuration | 2h | Pratique ⭐ |
| **1.3** | Datasource InfluxDB | 1h30 | Pratique |
| **1.4** | Datasource Prometheus | 1h30 | Pratique |
| **1.5** | Datasource MS SQL Server | 1h30 | Pratique |
| **1.6** | Premier Dashboard Multi-Sources | 1h30 | Pratique |

**Livrables Jour 1**:
- ✅ Stack complète déployée et opérationnelle
- ✅ 3 datasources configurées (InfluxDB, Prometheus, MS SQL)
- ✅ Requêtes fonctionnelles pour chaque datasource
- ✅ Dashboard multi-sources créé

---

### 📗 Jour 2 : Observabilité Avancée (8h)

**Objectif**: Implémenter l'observabilité complète (métriques, logs, traces) et créer des dashboards avancés

| Lab | Titre | Durée | Type |
|-----|-------|-------|------|
| **2.1** | Loki - Agrégation de Logs | 2h | Pratique |
| **2.2** | Tempo - Distributed Tracing | 2h | Pratique |
| **2.3** | Alerting Avancé | 2h | Pratique |
| **2.4** | Dashboards Avancés & Templates | 2h | Pratique ⭐ |
| **2.5** | Monitoring E-Banking | 2h | Cas Pratique |

**Livrables Jour 2**:
- ✅ Logs collectés et analysés avec Loki/LogQL
- ✅ Traces distribuées avec Tempo/OpenTelemetry
- ✅ Alertes configurées (Email, Slack)
- ✅ Variables et templating maîtrisés
- ✅ Dashboard E-Banking complet

---

### 📕 Jour 3 : Production et Sécurité (7h)

**Objectif**: Optimiser, sécuriser et déployer en production

| Lab | Titre | Durée | Type |
|-----|-------|-------|------|
| **3.1** | Performance et Optimisation | 2h | Pratique |
| **3.2** | Organisations, Users & RBAC | 1h30 | Pratique ⭐ |
| **3.3** | Backup et Disaster Recovery | 1h30 | Pratique |
| **3.4** | Déploiement Production HA | 2h | Pratique |

**Livrables Jour 3**:
- ✅ Requêtes optimisées et performantes
- ✅ Organisations et utilisateurs configurés
- ✅ Permissions RBAC granulaires
- ✅ Stratégie de backup automatisée
- ✅ Configuration production-ready

---

## 🚀 Démarrage Rapide

### Prérequis Système

| Composant | Minimum | Recommandé |
|-----------|---------|------------|
| **CPU** | 2 cores | 4 cores |
| **RAM** | 4 GB | 8 GB |
| **Disk** | 10 GB libre | 20 GB libre |
| **OS** | Windows 10/11, Ubuntu 20.04+ | - |
| **Docker** | 20.10+ | Latest |
| **Docker Compose** | v2.0+ | Latest |

### Installation en 3 Étapes

#### 1️⃣ Cloner le Repository

```bash
# Windows (PowerShell)
cd "d:\Data2AI Academy\BHF-Observability"
git clone <repository-url> observability-stack

# Linux
cd ~/
git clone <repository-url> observability-stack
```

#### 2️⃣ Configurer l'Environnement

```bash
# Naviguer vers le répertoire
cd observability-stack

# Copier le fichier d'exemple
cp .env.example .env

# Éditer les credentials (IMPORTANT!)
notepad .env  # Windows
nano .env     # Linux
```

**Variables Essentielles à Modifier**:
```env
# Grafana
GF_SECURITY_ADMIN_PASSWORD=VotreMotDePasseSecure123!

# InfluxDB
INFLUXDB_PASSWORD=VotreMotDePasseSecure123!
INFLUXDB_TOKEN=votre-token-secret-unique

# MS SQL
MSSQL_SA_PASSWORD=VotreMotDePasseSecure123!
```

#### 3️⃣ Démarrer la Stack

```bash
# Démarrer tous les services
docker compose up -d

# Vérifier le statut
docker compose ps

# Attendre l'initialisation (30-60 secondes)
# Vérifier la santé de Grafana
curl http://localhost:3000/api/health
```

### Accès aux Services

| Service | URL | Credentials | Usage |
|---------|-----|-------------|-------|
| **Grafana** | http://localhost:3000 | admin / (voir .env) | Dashboards & Alerting |
| **Prometheus** | http://localhost:9090 | - | Métriques & Targets |
| **InfluxDB** | http://localhost:8086 | admin / (voir .env) | Time Series Data |
| **Loki** | http://localhost:3100 | - | Logs Aggregation |
| **Tempo** | http://localhost:3200 | - | Distributed Tracing |
| **Alertmanager** | http://localhost:9093 | - | Alert Management |

---

## 📚 Structure des Labs

```
hands-lab/
├── README-MAIN.md                    # Ce fichier (guide principal)
├── GUIDE-FORMATEUR.md                # Guide pour animateurs
├── LABS-CREATED-SUMMARY.md           # Résumé des labs créés
│
├── Day 1/                            # Jour 1: Fondamentaux
│   ├── README.md                     # Vue d'ensemble Jour 1
│   ├── Lab-1.2-Installation/         # ⭐ Lab critique
│   │   └── README.md                 # Installation complète
│   ├── Lab-1.3-InfluxDB/
│   │   └── README.md                 # Datasource InfluxDB
│   ├── Lab-1.4-Prometheus/
│   │   └── README.md                 # Datasource Prometheus
│   ├── Lab-1.5-MSSQL/
│   │   └── README.md                 # Datasource MS SQL
│   └── Lab-1.6-Dashboard/
│       └── README.md                 # Premier dashboard
│
├── Day 2/                            # Jour 2: Observabilité Avancée
│   ├── README.md                     # Vue d'ensemble Jour 2
│   └── Lab-2.4-Advanced-Dashboards/  # ⭐ Lab critique
│       └── 02-Templates-Variables.md # Variables & Templating
│
└── Day 3/                            # Jour 3: Production
    ├── README.md                     # Vue d'ensemble Jour 3
    └── Lab-3.2-Security/             # ⭐ Lab critique
        └── 01-Organisations-Users.md # Orgs, Users & RBAC
```

---

## 🎯 Labs Critiques (⭐)

Ces labs sont **essentiels** pour la formation et couvrent les compétences clés Grafana:

### 1. Lab 1.2 - Installation et Configuration
**Pourquoi critique**: Base de toute la formation, déploiement de la stack complète
- Docker Compose orchestration
- Configuration .env et secrets
- Vérification de tous les services
- Troubleshooting de base

### 2. Lab 2.4 - Templates & Variables
**Pourquoi critique**: Compétence #1 pour dashboards réutilisables
- 7 types de variables Grafana
- Query variables (Prometheus, InfluxDB, MS SQL)
- Variables hiérarchiques ($region → $server)
- Repeat panels et formattage avancé

### 3. Lab 3.2 - Organisations & Users
**Pourquoi critique**: Gestion multi-tenant et sécurité production
- Architecture multi-organisations
- User management complet (API + UI)
- Permissions RBAC granulaires
- Isolation et audit

---

## 📖 Guide d'Utilisation

### Pour les Apprenants

1. **Suivez l'ordre des jours** : Les labs sont progressifs
2. **Complétez chaque lab** avant de passer au suivant
3. **Testez vos configurations** à chaque étape
4. **Prenez des notes** sur les concepts clés
5. **Expérimentez** : Modifiez les exemples fournis
6. **Utilisez le troubleshooting** en cas de problème

### Pour les Formateurs

Consultez le **[GUIDE-FORMATEUR.md](./GUIDE-FORMATEUR.md)** qui contient:
- Planning détaillé 3 jours (session par session)
- Exemples de code prêts à l'emploi
- Conseils pédagogiques
- Pièges courants à éviter
- Quiz et critères d'évaluation

---

## ✅ Checklist de Progression

### Jour 1 - Fondamentaux
- [ ] Stack Docker démarrée et opérationnelle
- [ ] Grafana accessible (http://localhost:3000)
- [ ] InfluxDB datasource configurée
- [ ] Prometheus datasource configurée
- [ ] MS SQL datasource configurée
- [ ] Requêtes testées pour chaque datasource
- [ ] Premier dashboard multi-sources créé

### Jour 2 - Observabilité Avancée
- [ ] Loki configuré et logs collectés
- [ ] Requêtes LogQL maîtrisées
- [ ] Tempo configuré et traces collectées
- [ ] Application instrumentée (OpenTelemetry)
- [ ] Alertes configurées (Email/Slack)
- [ ] Variables hiérarchiques créées
- [ ] Dashboard avec templating fonctionnel
- [ ] Dashboard E-Banking complet

### Jour 3 - Production
- [ ] Requêtes optimisées (performance)
- [ ] 3 organisations créées
- [ ] Utilisateurs et rôles configurés
- [ ] Permissions RBAC testées
- [ ] Scripts de backup créés
- [ ] Configuration production documentée
- [ ] Tests de haute disponibilité

---

## 🛠️ Commandes Utiles

### Gestion de la Stack

```bash
# Démarrer tous les services
docker compose up -d

# Arrêter tous les services
docker compose down

# Redémarrer un service spécifique
docker compose restart grafana

# Voir les logs d'un service
docker compose logs -f grafana

# Voir le statut de tous les services
docker compose ps

# Voir l'utilisation des ressources
docker stats
```

### Vérification de Santé

```bash
# Grafana
curl http://localhost:3000/api/health

# Prometheus
curl http://localhost:9090/-/healthy

# InfluxDB
curl http://localhost:8086/health

# Loki
curl http://localhost:3100/ready

# Tempo
curl http://localhost:3200/ready

# Alertmanager
curl http://localhost:9093/-/healthy
```

### Backup et Restauration

```bash
# Backup des volumes Docker
docker compose down
tar -czf backup-$(date +%Y%m%d).tar.gz \
  grafana_data prometheus_data influxdb_data

# Restauration
tar -xzf backup-YYYYMMDD.tar.gz
docker compose up -d
```

---

## 🐛 Troubleshooting Commun

### Problème: Port déjà utilisé

```bash
# Windows
netstat -ano | findstr :3000
taskkill /PID <PID> /F

# Linux
sudo lsof -i :3000
sudo kill -9 <PID>
```

### Problème: Service ne démarre pas

```bash
# Vérifier les logs
docker compose logs <service-name>

# Vérifier les permissions
ls -la ./grafana/

# Recréer le conteneur
docker compose up -d --force-recreate <service-name>
```

### Problème: Datasource connection failed

```bash
# Vérifier que le service est up
docker compose ps

# Tester la connexion réseau
docker compose exec grafana ping prometheus

# Vérifier les credentials dans .env
cat .env | grep PASSWORD
```

### Problème: Grafana ne charge pas

```bash
# Vérifier les ressources système
docker stats

# Augmenter la mémoire Docker (Settings → Resources)
# Redémarrer Docker Desktop

# Nettoyer les ressources
docker system prune -a
```

---

## 📚 Ressources Complémentaires

### Documentation Officielle
- [Grafana Documentation](https://grafana.com/docs/grafana/latest/)
- [Prometheus Documentation](https://prometheus.io/docs/)
- [InfluxDB Documentation](https://docs.influxdata.com/)
- [Loki Documentation](https://grafana.com/docs/loki/)
- [Tempo Documentation](https://grafana.com/docs/tempo/)

### Cheat Sheets
- [PromQL Cheat Sheet](https://promlabs.com/promql-cheat-sheet/)
- [LogQL Cheat Sheet](https://grafana.com/docs/loki/latest/logql/)
- [Flux Functions Reference](https://docs.influxdata.com/flux/v0.x/stdlib/)
- [Grafana Keyboard Shortcuts](https://grafana.com/docs/grafana/latest/dashboards/shortcuts/)

### Communauté
- [Grafana Community Forums](https://community.grafana.com/)
- [Grafana Slack](https://grafana.slack.com/)
- [GitHub Grafana](https://github.com/grafana/grafana)
- [Grafana Blog](https://grafana.com/blog/)

### Tutoriels Vidéo
- [Grafana Fundamentals](https://grafana.com/tutorials/grafana-fundamentals/)
- [Prometheus Basics](https://www.youtube.com/watch?v=h4Sl21AKiDg)
- [InfluxDB Getting Started](https://www.influxdata.com/resources/getting-started-with-influxdb/)

---

## 🎓 Certification

### Grafana Certified Associate

Après cette formation, vous êtes prêt pour la certification officielle Grafana:
- **Nom**: Grafana Certified Associate
- **Durée**: 90 minutes
- **Format**: QCM en ligne
- **Coût**: ~$200 USD
- **Validité**: 2 ans
- **Lien**: [Grafana Certification](https://grafana.com/training/)

### Compétences Couvertes

Cette formation couvre **100% des compétences** requises pour la certification:
- ✅ Installation et configuration Grafana
- ✅ Datasources (Prometheus, InfluxDB, SQL)
- ✅ Création de dashboards et panels
- ✅ Variables et templating
- ✅ Alerting et notifications
- ✅ User management et RBAC
- ✅ Provisioning et API
- ✅ Best practices production

---

## 🤝 Support et Contribution

### Obtenir de l'Aide

1. **Consultez le troubleshooting** dans chaque lab
2. **Vérifiez les logs** avec `docker compose logs`
3. **Recherchez dans la documentation** officielle
4. **Posez des questions** sur le forum Grafana Community

### Contribuer

Ce projet est en amélioration continue. Vos contributions sont bienvenues:
- 🐛 Signaler des bugs
- 📝 Améliorer la documentation
- ✨ Proposer de nouveaux labs
- 🔧 Corriger des erreurs

---

## 📊 Statistiques de la Formation

| Métrique | Valeur |
|----------|--------|
| **Durée totale** | 21-23 heures |
| **Nombre de labs** | 15 labs pratiques |
| **Services déployés** | 15 conteneurs Docker |
| **Datasources** | 6 types différents |
| **Lignes de code** | 5000+ (exemples et configs) |
| **Dashboards exemples** | 10+ dashboards |
| **Requêtes exemples** | 100+ requêtes |

---

## 🎉 Conclusion

Cette formation vous donne **toutes les compétences** nécessaires pour:
- 🚀 Déployer une stack d'observabilité production-ready
- 📊 Créer des dashboards professionnels
- 🔔 Configurer des alertes intelligentes
- 🔐 Gérer la sécurité et les accès
- ⚡ Optimiser les performances
- 🏢 Gérer des environnements multi-tenant

**Prêt à commencer ?** 

👉 Commencez par le **[Jour 1](./Day%201/README.md)** et suivez le guide pas à pas !

---

**📧 Questions ?** Consultez le [GUIDE-FORMATEUR.md](./GUIDE-FORMATEUR.md) ou la documentation officielle Grafana.

**🌟 Bonne formation et bon monitoring !**
