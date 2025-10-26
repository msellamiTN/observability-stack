# 📅 Jour 1 : Fondamentaux Grafana et Datasources

**Durée totale** : 8 heures | **Niveau** : Débutant

---

## 🎯 Objectifs du Jour

À la fin de cette journée, vous serez capable de :

✅ Comprendre l'architecture et l'écosystème Grafana  
✅ Installer et configurer Grafana OSS avec Docker Compose  
✅ Connecter et configurer trois datasources (InfluxDB, Prometheus, MS SQL)  
✅ Créer des requêtes pour chaque type de datasource  
✅ Construire un dashboard multi-sources fonctionnel  

---

## 📚 Liste des Labs

### 🎓 Lab 1.1 : Introduction à Grafana (1h30)
**Type** : Théorie + Démo  
**Fichier** : [Lab-1.1-Introduction](./Lab-1.1-Introduction/)

**Contenu** :
- Architecture et philosophie Grafana
- Comparaison OSS vs Enterprise vs Cloud
- Fonctionnalités clés (Dashboards, Alerting, Plugins)
- Positionnement dans l'écosystème d'observabilité
- Use cases et bonnes pratiques

---

### 🚀 Lab 1.2 : Installation et Configuration (2h)
**Type** : Pratique  
**Fichier** : [Lab-1.2-Installation](./Lab-1.2-Installation/)

**Contenu** :
- Déploiement de la stack avec Docker Compose
- Configuration du fichier .env
- Sécurisation des accès
- Navigation dans l'interface Grafana
- Troubleshooting de base

**Prérequis** :
- Docker Desktop installé
- Docker Compose v2.0+
- 8GB RAM minimum

---

### 🗄️ Lab 1.3 : Datasource InfluxDB (1h30)
**Type** : Pratique  
**Fichier** : [Lab-1.3-InfluxDB](./Lab-1.3-InfluxDB/)

**Contenu** :
- Modèle de données InfluxDB (Buckets, Measurements, Tags, Fields)
- Configuration de la connexion Grafana ↔ InfluxDB
- Langage Flux : syntaxe et requêtes basiques
- Visualisation de séries temporelles
- Création de données de test

**Prérequis** :
- Lab 1.2 complété
- InfluxDB démarré et accessible

---

### 📈 Lab 1.4 : Datasource Prometheus (1h30)
**Type** : Pratique  
**Fichier** : [Lab-1.4-Prometheus](./Lab-1.4-Prometheus/)

**Contenu** :
- Architecture Prometheus (Pull-based)
- Modèle de métriques (Counters, Gauges, Histograms)
- Langage PromQL : syntaxe et fonctions
- Exploration des targets et métriques
- Visualisation de métriques système

**Prérequis** :
- Lab 1.2 complété
- Prometheus démarré et scraping actif

---

### 💾 Lab 1.5 : Datasource MS SQL Server (1h30)
**Type** : Pratique  
**Fichier** : [Lab-1.5-MSSQL](./Lab-1.5-MSSQL/)

**Contenu** :
- Connexion à MS SQL Server depuis Grafana
- Requêtes SQL pour visualisation
- Utilisation des macros Grafana
- Visualisation de données métier (E-Banking)
- Création de tables et données de test

**Prérequis** :
- Lab 1.2 complété
- MS SQL Server démarré et accessible

---

### 🎯 Lab 1.6 : Premier Dashboard Multi-Sources (1h30)
**Type** : Pratique  
**Fichier** : [Lab-1.6-Dashboard](./Lab-1.6-Dashboard/)

**Contenu** :
- Création d'un dashboard complet
- Combinaison de plusieurs datasources
- Configuration de variables
- Personnalisation des visualisations
- Sauvegarde et partage

**Prérequis** :
- Labs 1.3, 1.4, 1.5 complétés
- Données de test disponibles dans chaque datasource

---

## ⏱️ Planning Recommandé

| Horaire | Activité | Durée |
|---------|----------|-------|
| 09:00 - 10:30 | Lab 1.1 : Introduction | 1h30 |
| 10:30 - 10:45 | ☕ Pause | 15min |
| 10:45 - 12:45 | Lab 1.2 : Installation | 2h |
| 12:45 - 14:00 | 🍽️ Déjeuner | 1h15 |
| 14:00 - 15:30 | Lab 1.3 : InfluxDB | 1h30 |
| 15:30 - 15:45 | ☕ Pause | 15min |
| 15:45 - 17:15 | Lab 1.4 : Prometheus | 1h30 |
| 17:15 - 17:30 | ☕ Pause | 15min |
| 17:30 - 19:00 | Lab 1.5 : MS SQL | 1h30 |

**Note** : Le Lab 1.6 peut être fait en fin de journée ou le lendemain matin comme révision.

---

## 🛠️ Prérequis Techniques

### Logiciels Requis
- ✅ Docker Desktop (v20.10+)
- ✅ Docker Compose (v2.0+)
- ✅ Git
- ✅ Navigateur web (Chrome, Firefox, Edge)
- ✅ Éditeur de texte (VS Code recommandé)

### Ressources Système
- **CPU** : 4 cores minimum
- **RAM** : 8 GB minimum (16 GB recommandé)
- **Disk** : 10 GB d'espace libre
- **Réseau** : Connexion internet stable

### Connaissances Requises
- 🔹 Ligne de commande de base
- 🔹 Concepts réseau (ports, HTTP)
- 🔹 Notions de bases de données
- 🔹 Docker (niveau basique)

---

## 🚀 Setup Initial

Avant de commencer les labs, assurez-vous que la stack est démarrée :

```bash
# Naviguer vers le répertoire
cd "d:\Data2AI Academy\Grafana\observability-stack"

# Configurer l'environnement
cp .env.example .env
notepad .env

# Démarrer la stack
docker compose up -d

# Vérifier les services
docker compose ps

# Attendre l'initialisation (30 secondes)
timeout /t 30
```

### Vérification des Services

```bash
# Grafana
curl http://localhost:3000/api/health

# Prometheus
curl http://localhost:9090/-/healthy

# InfluxDB
curl http://localhost:8086/health

# MS SQL (via Docker)
docker compose exec mssql /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "EBanking@Secure123!" -C -Q "SELECT 1"
```

---

## 📊 Services Utilisés Aujourd'hui

| Service | Port | URL | Credentials |
|---------|------|-----|-------------|
| **Grafana** | 3000 | http://localhost:3000 | admin / GrafanaSecure123!Change@Me |
| **Prometheus** | 9090 | http://localhost:9090 | - |
| **InfluxDB** | 8086 | http://localhost:8086 | admin / InfluxSecure123!Change@Me |
| **MS SQL** | 1433 | localhost:1433 | sa / EBanking@Secure123! |
| **Payment API** | 8080 | http://localhost:8080 | - |

---

## ✅ Checklist de Fin de Journée

À la fin du Jour 1, vous devriez avoir :

- [ ] Grafana installé et accessible
- [ ] Compréhension de l'architecture Grafana
- [ ] InfluxDB datasource configurée et testée
- [ ] Prometheus datasource configurée et testée
- [ ] MS SQL datasource configurée et testée
- [ ] Requêtes créées pour chaque datasource
- [ ] Premier dashboard multi-sources créé
- [ ] Données de test dans chaque datasource
- [ ] Mot de passe admin Grafana changé
- [ ] Notes prises sur les concepts clés

---

## 💡 Tips pour Réussir

### Pendant les Labs
1. **Prenez des notes** : Documentez ce qui fonctionne
2. **Expérimentez** : N'hésitez pas à modifier les exemples
3. **Posez des questions** : Utilisez les sections troubleshooting
4. **Sauvegardez** : Exportez vos dashboards régulièrement
5. **Testez** : Vérifiez chaque étape avant de continuer

### Bonnes Pratiques
- Utilisez des noms descriptifs pour vos dashboards
- Commentez vos requêtes complexes
- Organisez vos panels logiquement
- Testez avec différentes plages temporelles
- Vérifiez les logs en cas d'erreur

---

## 🐛 Troubleshooting Commun

### Grafana ne démarre pas
```bash
# Vérifier les logs
docker compose logs grafana

# Vérifier les permissions
ls -la grafana/

# Redémarrer
docker compose restart grafana
```

### Datasource connection failed
```bash
# Vérifier que le service est up
docker compose ps

# Tester la connexion
curl http://localhost:[PORT]/health

# Vérifier les credentials dans .env
cat .env | grep PASSWORD
```

### Port déjà utilisé
```bash
# Identifier le processus
netstat -ano | findstr :[PORT]

# Arrêter le processus ou changer le port dans docker-compose.yml
```

---

## 📚 Ressources Complémentaires

### Documentation
- [Grafana Getting Started](https://grafana.com/docs/grafana/latest/getting-started/)
- [InfluxDB Flux Language](https://docs.influxdata.com/flux/)
- [Prometheus Query Basics](https://prometheus.io/docs/prometheus/latest/querying/basics/)
- [SQL Server T-SQL Reference](https://learn.microsoft.com/en-us/sql/t-sql/)

### Cheat Sheets
- [PromQL Cheat Sheet](https://promlabs.com/promql-cheat-sheet/)
- [Flux Functions](https://docs.influxdata.com/flux/v0.x/stdlib/)
- [Grafana Keyboard Shortcuts](https://grafana.com/docs/grafana/latest/dashboards/shortcuts/)

### Vidéos
- [Grafana Fundamentals](https://grafana.com/tutorials/grafana-fundamentals/)
- [Prometheus Basics](https://www.youtube.com/watch?v=h4Sl21AKiDg)

---

## 🎯 Préparation pour le Jour 2

Pour être prêt pour le Jour 2 :

1. **Vérifiez** que tous les services sont opérationnels
2. **Sauvegardez** vos dashboards créés aujourd'hui
3. **Revoyez** les concepts de métriques, logs et traces
4. **Lisez** la documentation sur Loki et Tempo
5. **Assurez-vous** que la stack reste démarrée

---

**🎉 Félicitations ! Vous avez terminé le Jour 1 !**

Passez au [Jour 2](../Day%202/) pour découvrir les logs, traces et l'observabilité avancée.
