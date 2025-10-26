# 📝 Lab 2.1 : Loki - Agrégation de Logs

**Durée estimée** : 2 heures  
**Niveau** : Intermédiaire  
**Prérequis** : Lab 1.2 (Installation), Lab 1.4 (Prometheus)

---

## 🎯 Objectifs d'Apprentissage

À la fin de ce lab, vous serez capable de :

- ✅ Comprendre l'architecture Loki + Promtail
- ✅ Configurer Promtail pour collecter des logs
- ✅ Maîtriser le langage LogQL (requêtes de logs)
- ✅ Créer des dashboards de logs dans Grafana
- ✅ Corréler logs et métriques
- ✅ Configurer des filtres et des parsers de logs

---

## 📋 Prérequis

### Services Docker Requis

```bash
# Vérifier que les services sont démarrés
docker ps | grep -E "loki|promtail|grafana"

# Devrait afficher :
# - loki (port 3100)
# - promtail (collecteur de logs)
# - grafana (port 3000)
```

### Accès aux Interfaces

| Service | URL | Credentials |
|---------|-----|-------------|
| **Grafana** | http://localhost:3000 | admin / GrafanaSecure123!Change@Me |
| **Loki** | http://localhost:3100 | - |

---

## 📚 Partie 1 : Architecture Loki (30 min)

### Qu'est-ce que Loki ?

**Loki** est un système d'agrégation de logs inspiré de Prometheus, conçu pour être :
- **Économique** : N'indexe que les métadonnées (labels), pas le contenu
- **Scalable** : Stockage objet (S3, MinIO, etc.)
- **Intégré** : Natif dans Grafana

### Architecture

```
┌─────────────┐
│ Application │
│   + Logs    │
└──────┬──────┘
       │
       ▼
┌─────────────┐     Push      ┌──────────┐
│  Promtail   │ ─────────────▶ │   Loki   │
│ (Collector) │                │ (Server) │
└─────────────┘                └────┬─────┘
                                    │
                                    │ Query
                                    ▼
                              ┌──────────┐
                              │ Grafana  │
                              └──────────┘
```

### Composants

| Composant | Rôle | Port |
|-----------|------|------|
| **Loki** | Serveur d'agrégation | 3100 |
| **Promtail** | Agent de collecte | - |
| **Grafana** | Visualisation | 3000 |

### Différence avec ELK Stack

| Critère | Loki | Elasticsearch |
|---------|------|---------------|
| **Indexation** | Labels uniquement | Full-text |
| **Stockage** | Chunks compressés | Documents JSON |
| **Coût** | Faible | Élevé |
| **Requêtes** | LogQL (comme PromQL) | Query DSL |
| **Intégration** | Natif Grafana | Kibana |

---

## 🔧 Partie 2 : Configuration Promtail (45 min)

### Vérifier la Configuration Actuelle

```bash
# Voir les logs de Promtail
docker logs promtail --tail 50

# Vérifier la configuration
docker exec promtail cat /etc/promtail/promtail-config.yaml
```

### Créer une Configuration Promtail

Créez le fichier `promtail/promtail-config.yaml` :

```yaml
server:
  http_listen_port: 9080
  grpc_listen_port: 0

positions:
  filename: /tmp/positions.yaml

clients:
  - url: http://loki:3100/loki/api/v1/push

scrape_configs:
  # Logs système
  - job_name: system
    static_configs:
      - targets:
          - localhost
        labels:
          job: varlogs
          __path__: /var/log/*log

  # Logs Docker
  - job_name: docker
    docker_sd_configs:
      - host: unix:///var/run/docker.sock
        refresh_interval: 5s
    relabel_configs:
      - source_labels: ['__meta_docker_container_name']
        regex: '/(.*)'
        target_label: 'container'
      - source_labels: ['__meta_docker_container_log_stream']
        target_label: 'stream'

  # Logs applicatifs (exemple)
  - job_name: app_logs
    static_configs:
      - targets:
          - localhost
        labels:
          job: app
          env: dev
          __path__: /var/log/app/*.log
    pipeline_stages:
      # Parser JSON
      - json:
          expressions:
            level: level
            message: message
            timestamp: timestamp
      # Extraire le niveau de log
      - labels:
          level:
      # Filtrer les logs DEBUG en dev
      - match:
          selector: '{level="DEBUG"}'
          action: drop
```

### Configuration Avancée : Pipeline Stages

#### 1. Parser JSON

```yaml
pipeline_stages:
  - json:
      expressions:
        level: level
        message: msg
        user_id: user.id
        request_id: request_id
```

#### 2. Parser Regex

```yaml
pipeline_stages:
  - regex:
      expression: '^(?P<timestamp>\S+) (?P<level>\w+) (?P<message>.*)$'
  - labels:
      level:
  - timestamp:
      source: timestamp
      format: RFC3339
```

#### 3. Filtres

```yaml
pipeline_stages:
  # Garder uniquement ERROR et WARN
  - match:
      selector: '{level!~"ERROR|WARN"}'
      action: drop
  
  # Ajouter un label pour les erreurs critiques
  - match:
      selector: '{level="ERROR"}'
      stages:
        - labels:
            severity: critical
```

### Redémarrer Promtail

```bash
# Windows PowerShell
docker-compose restart promtail

# Vérifier les logs
docker logs promtail --tail 20
```

---

## 🔍 Partie 3 : LogQL - Langage de Requête (45 min)

### Syntaxe de Base

LogQL est similaire à PromQL avec deux types d'expressions :

1. **Log Queries** : Sélection et filtrage
2. **Metric Queries** : Agrégation et calculs

### 1. Sélection de Logs

#### Sélection par Labels

```logql
# Tous les logs d'un job
{job="varlogs"}

# Logs d'un container spécifique
{container="prometheus"}

# Combinaison de labels
{job="app", env="production", level="ERROR"}
```

#### Filtrage par Contenu

```logql
# Contient "error" (case-insensitive)
{job="app"} |= "error"

# Ne contient pas "debug"
{job="app"} != "debug"

# Regex : commence par "ERROR"
{job="app"} |~ "^ERROR.*"

# Regex négative
{job="app"} !~ "DEBUG|TRACE"
```

#### Combinaison de Filtres

```logql
# Logs d'erreur contenant "database" ou "connection"
{job="app"} |= "error" |~ "database|connection"

# Logs sans "health check" ni "ping"
{job="app"} != "health check" != "ping"
```

### 2. Parsers

#### Parser JSON

```logql
# Extraire des champs JSON
{job="app"} | json

# Extraire des champs spécifiques
{job="app"} | json level="level", message="msg", user="user.id"

# Filtrer après parsing
{job="app"} | json | level="ERROR"
```

#### Parser Logfmt

```logql
# Format: key=value key2=value2
{job="app"} | logfmt

# Filtrer sur un champ parsé
{job="app"} | logfmt | status_code >= 400
```

#### Parser Regex

```logql
# Extraire avec regex
{job="nginx"} | regexp '(?P<ip>\S+) .* "(?P<method>\w+) (?P<path>\S+).*" (?P<status>\d+)'

# Utiliser les champs extraits
{job="nginx"} | regexp '(?P<status>\d+)' | status >= 500
```

### 3. Formatters

```logql
# Formater la sortie
{job="app"} | line_format "{{.level}} - {{.message}}"

# Formater avec conditions
{job="app"} | label_format level="{{if eq .level \"ERROR\"}}🔴{{else}}✅{{end}}"
```

### 4. Métriques de Logs

#### Comptage

```logql
# Nombre de logs par seconde
rate({job="app"}[5m])

# Nombre total de logs
count_over_time({job="app"}[1h])

# Logs d'erreur par minute
sum(rate({job="app", level="ERROR"}[1m]))
```

#### Agrégation

```logql
# Logs par container
sum by (container) (rate({job="docker"}[5m]))

# Top 5 des containers les plus verbeux
topk(5, sum by (container) (rate({job="docker"}[5m])))

# Ratio d'erreurs
sum(rate({level="ERROR"}[5m])) / sum(rate({job="app"}[5m]))
```

#### Métriques Extraites

```logql
# Durée moyenne des requêtes (depuis logs JSON)
avg_over_time({job="app"} | json | unwrap duration [5m])

# Percentile 95 des temps de réponse
quantile_over_time(0.95, {job="nginx"} | regexp '(?P<duration>\d+)ms' | unwrap duration [5m])

# Bytes transférés
sum(rate({job="nginx"} | json | unwrap bytes [5m]))
```

---

## 🎯 Exercice Pratique 1 : Requêtes LogQL (30 min)

### Objectif

Explorer les logs de votre stack avec LogQL.

### Étapes

#### 1. Accéder à l'Explorateur Grafana

```
Grafana → Explore → Datasource: Loki
```

#### 2. Requêtes de Base

**Exercice 1.1** : Afficher tous les logs Prometheus

```logql
{container="prometheus"}
```

**Exercice 1.2** : Logs d'erreur uniquement

```logql
{container="prometheus"} |~ "error|ERROR|Error"
```

**Exercice 1.3** : Logs sans "health check"

```logql
{container="grafana"} != "health"
```

#### 3. Requêtes Avancées

**Exercice 1.4** : Taux de logs par container

```logql
sum by (container) (rate({job="docker"}[5m]))
```

**Exercice 1.5** : Top 3 des containers les plus verbeux

```logql
topk(3, sum by (container) (count_over_time({job="docker"}[1h])))
```

**Exercice 1.6** : Ratio d'erreurs

```logql
sum(rate({job="docker"} |~ "error|ERROR" [5m])) 
/ 
sum(rate({job="docker"}[5m]))
```

### ✅ Critères de Réussite

- [ ] Vous pouvez afficher les logs de chaque container
- [ ] Vous savez filtrer par contenu (regex)
- [ ] Vous pouvez calculer des métriques depuis les logs
- [ ] Vous comprenez la différence entre log queries et metric queries

---

## 📊 Partie 4 : Dashboard de Logs (30 min)

### Créer un Dashboard de Monitoring de Logs

#### Panel 1 : Volume de Logs par Container

**Type** : Time series

**Query** :
```logql
sum by (container) (rate({job="docker"}[1m]))
```

**Configuration** :
- Legend : `{{container}}`
- Unit : logs/s
- Stacking : Normal

#### Panel 2 : Logs d'Erreur

**Type** : Stat

**Query** :
```logql
sum(count_over_time({job="docker"} |~ "error|ERROR|Error" [5m]))
```

**Configuration** :
- Color : Red si > 0
- Unit : short
- Thresholds : 0 (green), 1 (red)

#### Panel 3 : Logs en Temps Réel

**Type** : Logs

**Query** :
```logql
{job="docker"}
```

**Configuration** :
- Show time : Yes
- Show labels : Yes
- Wrap lines : Yes
- Deduplication : None

#### Panel 4 : Top Containers par Volume

**Type** : Bar chart

**Query** :
```logql
topk(5, sum by (container) (count_over_time({job="docker"}[1h])))
```

**Configuration** :
- Orientation : Horizontal
- Legend : Hide
- Unit : short

#### Panel 5 : Timeline des Erreurs

**Type** : State timeline

**Query** :
```logql
sum by (container) (count_over_time({job="docker", level="ERROR"}[1m]))
```

**Configuration** :
- Show values : Never
- Color mode : Cell

### Variables de Dashboard

Ajoutez une variable pour sélectionner le container :

```yaml
Name: container
Type: Query
Datasource: Loki
Query: label_values(container)
Multi-value: Yes
Include All: Yes
```

Utilisez-la dans les requêtes :
```logql
{container=~"$container"}
```

---

## 🔗 Partie 5 : Corrélation Logs ↔ Métriques (30 min)

### Concept

Lier les logs aux métriques pour un troubleshooting efficace.

### Méthode 1 : Data Links

Dans un panel de métriques Prometheus, ajoutez un lien vers les logs :

**Dashboard Settings → Links → Add link** :

```yaml
Title: View Logs
URL: /explore?orgId=1&left={"datasource":"Loki","queries":[{"expr":"{container=\"${__field.labels.instance}\"}"}]}
```

### Méthode 2 : Annotations depuis Logs

Créez une annotation pour afficher les erreurs sur les graphiques :

**Dashboard Settings → Annotations → Add annotation** :

```yaml
Name: Errors
Datasource: Loki
Query: {job="docker"} |~ "error|ERROR"
Text: {{container}}: {{__line}}
Tags: error
```

### Méthode 3 : Panels Combinés

Créez un dashboard avec métriques + logs côte à côte :

```
┌─────────────────────────────────────┐
│  CPU Usage (Prometheus)             │
├─────────────────────────────────────┤
│  Logs (Loki) - Filtered by time     │
└─────────────────────────────────────┘
```

Utilisez le **time range sync** pour synchroniser les vues.

---

## 🎯 Exercice Pratique 2 : Dashboard Complet (30 min)

### Objectif

Créer un dashboard "Observabilité Complète" combinant métriques et logs.

### Structure

1. **Row 1 : Métriques Système**
   - CPU Usage (Prometheus)
   - Memory Usage (Prometheus)
   - Disk I/O (Prometheus)

2. **Row 2 : Logs**
   - Volume de logs par service
   - Logs d'erreur (count)
   - Logs en temps réel (filtered)

3. **Row 3 : Corrélation**
   - Timeline des erreurs
   - Annotations sur les métriques

### Requêtes Suggérées

#### Métriques (Prometheus)

```promql
# CPU
100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# Memory
(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100
```

#### Logs (Loki)

```logql
# Volume par service
sum by (container) (rate({job="docker"}[1m]))

# Erreurs
sum(count_over_time({job="docker"} |~ "error|ERROR" [5m]))

# Logs filtrés
{job="docker", container=~"$container"} |~ "$search"
```

### Variables

```yaml
# Container
Name: container
Query: label_values(container)

# Search
Name: search
Type: Text box
Default: ""
```

### ✅ Critères de Réussite

- [ ] Dashboard avec 3 rows (Métriques, Logs, Corrélation)
- [ ] Variables fonctionnelles (container, search)
- [ ] Data links entre métriques et logs
- [ ] Annotations d'erreurs visibles sur les graphiques

---

## 🚀 Partie 6 : Cas d'Usage Avancés (Bonus)

### 1. Alertes depuis Logs

Créez une alerte sur le volume d'erreurs :

```logql
sum(rate({job="docker"} |~ "error|ERROR" [5m])) > 10
```

**Configuration** :
- Condition : `WHEN last() OF query(A) IS ABOVE 10`
- Evaluate every : 1m
- For : 5m

### 2. Logs Structurés (JSON)

Si vos applications loggent en JSON :

```json
{"level":"ERROR","message":"Database connection failed","user_id":123,"timestamp":"2024-10-27T00:00:00Z"}
```

Requête :
```logql
{job="app"} 
| json 
| level="ERROR" 
| line_format "User {{.user_id}}: {{.message}}"
```

### 3. Logs Multi-Lignes

Pour les stack traces Java/Python :

```yaml
# promtail-config.yaml
pipeline_stages:
  - multiline:
      firstline: '^\d{4}-\d{2}-\d{2}'
      max_wait_time: 3s
```

### 4. Logs avec Contexte

Afficher les lignes avant/après une erreur :

```logql
{job="app"} |~ "error" | context before=5 after=5
```

---

## 📖 Ressources

### Documentation Officielle

- [Loki Documentation](https://grafana.com/docs/loki/latest/)
- [LogQL Guide](https://grafana.com/docs/loki/latest/logql/)
- [Promtail Configuration](https://grafana.com/docs/loki/latest/clients/promtail/configuration/)

### Cheat Sheets

- [LogQL Cheat Sheet](https://grafana.com/docs/loki/latest/logql/log_queries/)
- [Promtail Pipeline Stages](https://grafana.com/docs/loki/latest/clients/promtail/stages/)

### Exemples

- [LogQL Examples](https://grafana.com/docs/loki/latest/logql/query_examples/)
- [Grafana Loki Dashboards](https://grafana.com/grafana/dashboards/?search=loki)

---

## ✅ Checklist de Validation

Avant de passer au lab suivant, assurez-vous de :

- [ ] Loki et Promtail sont démarrés et fonctionnels
- [ ] Vous pouvez voir les logs dans Grafana Explore
- [ ] Vous maîtrisez les requêtes LogQL de base
- [ ] Vous savez filtrer et parser les logs
- [ ] Vous avez créé un dashboard de logs
- [ ] Vous comprenez la corrélation logs ↔ métriques
- [ ] Vous pouvez calculer des métriques depuis les logs

---

## 🔙 Navigation

- [⬅️ Retour au Jour 2](../README.md)
- [➡️ Lab suivant : Lab 2.2 - Tempo (Tracing)](../Lab-2.2-Tempo/)
- [🏠 Accueil Formation](../../README-MAIN.md)

---

## 🎓 Points Clés à Retenir

1. **Loki** = Prometheus pour les logs (indexation par labels uniquement)
2. **Promtail** = Agent de collecte configurable avec pipelines
3. **LogQL** = Langage similaire à PromQL (log queries + metric queries)
4. **Corrélation** = Lier logs et métriques pour un troubleshooting efficace
5. **Économique** = Stockage compressé, pas d'indexation full-text

---

**🎉 Félicitations !** Vous maîtrisez maintenant l'agrégation de logs avec Loki !

Passez au [Lab 2.2 - Tempo](../Lab-2.2-Tempo/) pour découvrir le tracing distribué.
