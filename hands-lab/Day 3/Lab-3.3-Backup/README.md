# 📦 Lab 3.3 : Backup et Disaster Recovery

**Durée estimée** : 1h30  
**Niveau** : Avancé  
**Prérequis** : Lab 1.2 (Installation), Lab 3.2 (Sécurité)

---

## 🎯 Objectifs d'Apprentissage

À la fin de ce lab, vous serez capable de :

- ✅ Identifier les éléments critiques à sauvegarder
- ✅ Créer des backups automatisés de Grafana
- ✅ Sauvegarder les configurations Prometheus et Alertmanager
- ✅ Exporter et importer des dashboards
- ✅ Restaurer une stack complète après incident
- ✅ Mettre en place une stratégie de backup 3-2-1

---

## 📋 Prérequis

### Services Docker Requis

```bash
# Vérifier que les services sont démarrés
docker ps | grep -E "grafana|prometheus|influxdb|mssql"
```

### Outils Nécessaires

```bash
# Windows PowerShell
# Installer curl (si pas déjà installé)
winget install curl

# Vérifier
curl --version
```

---

## 📚 Partie 1 : Stratégie de Backup (15 min)

### Règle 3-2-1

Une stratégie de backup efficace suit la règle **3-2-1** :

- **3** copies des données
- **2** types de supports différents
- **1** copie hors site (off-site)

### Éléments à Sauvegarder

#### 1. Grafana

| Élément | Localisation | Criticité | Fréquence |
|---------|--------------|-----------|-----------|
| **Dashboards** | SQLite DB | 🔴 Critique | Quotidien |
| **Datasources** | SQLite DB / Provisioning | 🔴 Critique | À chaque changement |
| **Users/Orgs** | SQLite DB | 🟡 Important | Hebdomadaire |
| **Alertes** | SQLite DB | 🔴 Critique | Quotidien |
| **Plugins** | `/var/lib/grafana/plugins` | 🟢 Faible | Mensuel |
| **Configuration** | `grafana.ini` | 🔴 Critique | À chaque changement |

#### 2. Prometheus

| Élément | Localisation | Criticité | Fréquence |
|---------|--------------|-----------|-----------|
| **Règles d'alerte** | `prometheus/rules/` | 🔴 Critique | À chaque changement |
| **Configuration** | `prometheus.yml` | 🔴 Critique | À chaque changement |
| **Données métriques** | `/prometheus` | 🟡 Important | Selon rétention |

#### 3. Autres Services

| Service | Éléments | Criticité |
|---------|----------|-----------|
| **InfluxDB** | Buckets, données | 🟡 Important |
| **MS SQL** | Bases de données | 🔴 Critique |
| **Loki** | Configuration | 🟡 Important |
| **Alertmanager** | Configuration | 🔴 Critique |

### Architecture de Backup

```
┌─────────────────┐
│   Production    │
│                 │
│ - Grafana       │
│ - Prometheus    │
│ - InfluxDB      │
│ - MS SQL        │
└────────┬────────┘
         │
         │ Daily Backup
         ▼
┌─────────────────┐
│  Local Backup   │
│  (./backups/)   │
└────────┬────────┘
         │
         │ Weekly Sync
         ▼
┌─────────────────┐
│  Remote Backup  │
│  (S3, NAS, etc) │
└─────────────────┘
```

---

## 🔧 Partie 2 : Backup Grafana (30 min)

### Méthode 1 : Backup via API

#### Script PowerShell Complet

Créez `scripts/backup-grafana.ps1` :

```powershell
# Configuration
$GRAFANA_URL = "http://localhost:3000"
$GRAFANA_USER = "admin"
$GRAFANA_PASSWORD = "GrafanaSecure123!Change@Me"
$BACKUP_DIR = ".\backups\grafana\$(Get-Date -Format 'yyyy-MM-dd_HH-mm-ss')"

# Créer le répertoire de backup
New-Item -ItemType Directory -Force -Path $BACKUP_DIR | Out-Null
Write-Host "📦 Backup directory: $BACKUP_DIR" -ForegroundColor Green

# Credentials
$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${GRAFANA_USER}:${GRAFANA_PASSWORD}"))
$headers = @{
    Authorization = "Basic $base64AuthInfo"
    "Content-Type" = "application/json"
}

# 1. Backup Dashboards
Write-Host "`n📊 Backing up dashboards..." -ForegroundColor Cyan
$dashboards = Invoke-RestMethod -Uri "$GRAFANA_URL/api/search?type=dash-db" -Headers $headers -Method Get

$dashboardsDir = "$BACKUP_DIR\dashboards"
New-Item -ItemType Directory -Force -Path $dashboardsDir | Out-Null

foreach ($dash in $dashboards) {
    $uid = $dash.uid
    $title = $dash.title -replace '[\\/:*?"<>|]', '_'
    
    Write-Host "  - $title" -ForegroundColor Gray
    
    $dashboard = Invoke-RestMethod -Uri "$GRAFANA_URL/api/dashboards/uid/$uid" -Headers $headers -Method Get
    $dashboard | ConvertTo-Json -Depth 100 | Out-File "$dashboardsDir\$title.json" -Encoding UTF8
}

Write-Host "✅ Backed up $($dashboards.Count) dashboards" -ForegroundColor Green

# 2. Backup Datasources
Write-Host "`n🔌 Backing up datasources..." -ForegroundColor Cyan
$datasources = Invoke-RestMethod -Uri "$GRAFANA_URL/api/datasources" -Headers $headers -Method Get

$datasourcesDir = "$BACKUP_DIR\datasources"
New-Item -ItemType Directory -Force -Path $datasourcesDir | Out-Null

foreach ($ds in $datasources) {
    $name = $ds.name -replace '[\\/:*?"<>|]', '_'
    Write-Host "  - $name" -ForegroundColor Gray
    $ds | ConvertTo-Json -Depth 10 | Out-File "$datasourcesDir\$name.json" -Encoding UTF8
}

Write-Host "✅ Backed up $($datasources.Count) datasources" -ForegroundColor Green

# 3. Backup Alert Rules
Write-Host "`n🔔 Backing up alert rules..." -ForegroundColor Cyan
try {
    $alerts = Invoke-RestMethod -Uri "$GRAFANA_URL/api/v1/provisioning/alert-rules" -Headers $headers -Method Get
    
    $alertsDir = "$BACKUP_DIR\alerts"
    New-Item -ItemType Directory -Force -Path $alertsDir | Out-Null
    
    $alerts | ConvertTo-Json -Depth 100 | Out-File "$alertsDir\alert-rules.json" -Encoding UTF8
    Write-Host "✅ Backed up $($alerts.Count) alert rules" -ForegroundColor Green
} catch {
    Write-Host "⚠️  No alert rules or API not available" -ForegroundColor Yellow
}

# 4. Backup Folders
Write-Host "`n📁 Backing up folders..." -ForegroundColor Cyan
$folders = Invoke-RestMethod -Uri "$GRAFANA_URL/api/folders" -Headers $headers -Method Get

$foldersDir = "$BACKUP_DIR\folders"
New-Item -ItemType Directory -Force -Path $foldersDir | Out-Null

$folders | ConvertTo-Json -Depth 10 | Out-File "$foldersDir\folders.json" -Encoding UTF8
Write-Host "✅ Backed up $($folders.Count) folders" -ForegroundColor Green

# 5. Backup Organizations
Write-Host "`n🏢 Backing up organizations..." -ForegroundColor Cyan
try {
    $orgs = Invoke-RestMethod -Uri "$GRAFANA_URL/api/orgs" -Headers $headers -Method Get
    
    $orgsDir = "$BACKUP_DIR\organizations"
    New-Item -ItemType Directory -Force -Path $orgsDir | Out-Null
    
    $orgs | ConvertTo-Json -Depth 10 | Out-File "$orgsDir\organizations.json" -Encoding UTF8
    Write-Host "✅ Backed up $($orgs.Count) organizations" -ForegroundColor Green
} catch {
    Write-Host "⚠️  Organizations backup requires admin privileges" -ForegroundColor Yellow
}

# 6. Backup SQLite Database (si accessible)
Write-Host "`n💾 Backing up Grafana database..." -ForegroundColor Cyan
try {
    docker cp grafana:/var/lib/grafana/grafana.db "$BACKUP_DIR\grafana.db"
    Write-Host "✅ Database backed up" -ForegroundColor Green
} catch {
    Write-Host "⚠️  Database backup failed (container may not be accessible)" -ForegroundColor Yellow
}

# Créer un fichier de métadonnées
$metadata = @{
    backup_date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    grafana_url = $GRAFANA_URL
    dashboards_count = $dashboards.Count
    datasources_count = $datasources.Count
} | ConvertTo-Json

$metadata | Out-File "$BACKUP_DIR\metadata.json" -Encoding UTF8

Write-Host "`n✅ Backup completed successfully!" -ForegroundColor Green
Write-Host "📦 Location: $BACKUP_DIR" -ForegroundColor Cyan
```

#### Exécuter le Backup

```powershell
# Donner les droits d'exécution
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Exécuter
.\scripts\backup-grafana.ps1
```

### Méthode 2 : Backup avec Outil Dédié

#### Installer grafana-backup-tool

```bash
# Via pip
pip install grafana-backup-tool

# Configuration
mkdir -p ~/.grafana-backup
cat > ~/.grafana-backup/grafanaSettings.json << 'EOF'
{
  "general": {
    "debug": true,
    "backup_dir": "./backups/grafana-backup-tool"
  },
  "grafana": {
    "url": "http://localhost:3000",
    "token": "YOUR_API_TOKEN"
  }
}
EOF
```

#### Créer un Token API

```
Grafana → Configuration → API Keys → Add API key
Name: backup-tool
Role: Admin
```

#### Exécuter le Backup

```bash
# Backup complet
grafana-backup save

# Restore
grafana-backup restore
```

---

## 🎯 Exercice Pratique 1 : Backup Complet (20 min)

### Objectif

Créer un backup complet de votre stack Grafana.

### Étapes

#### 1. Créer le Répertoire de Backup

```powershell
New-Item -ItemType Directory -Force -Path ".\backups"
```

#### 2. Exécuter le Script de Backup

```powershell
.\scripts\backup-grafana.ps1
```

#### 3. Vérifier le Contenu

```powershell
# Lister les fichiers
Get-ChildItem -Recurse .\backups\grafana\* | Select-Object FullName
```

#### 4. Vérifier l'Intégrité

```powershell
# Vérifier qu'un dashboard peut être lu
Get-Content ".\backups\grafana\*\dashboards\*.json" | ConvertFrom-Json
```

### ✅ Critères de Réussite

- [ ] Backup créé dans `./backups/grafana/`
- [ ] Dashboards exportés (fichiers JSON)
- [ ] Datasources exportés
- [ ] Metadata.json créé
- [ ] Fichiers lisibles et valides

---

## 📊 Partie 3 : Backup Prometheus & Alertmanager (15 min)

### Backup Prometheus

#### Configuration et Règles

```powershell
# Script backup-prometheus.ps1
$BACKUP_DIR = ".\backups\prometheus\$(Get-Date -Format 'yyyy-MM-dd_HH-mm-ss')"
New-Item -ItemType Directory -Force -Path $BACKUP_DIR | Out-Null

Write-Host "📦 Backing up Prometheus configuration..." -ForegroundColor Cyan

# Copier la configuration
Copy-Item -Path ".\prometheus\prometheus.yml" -Destination "$BACKUP_DIR\prometheus.yml"
Write-Host "✅ prometheus.yml backed up" -ForegroundColor Green

# Copier les règles d'alerte
if (Test-Path ".\prometheus\rules") {
    Copy-Item -Path ".\prometheus\rules" -Destination "$BACKUP_DIR\rules" -Recurse
    Write-Host "✅ Alert rules backed up" -ForegroundColor Green
}

# Métadonnées
@{
    backup_date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    prometheus_version = docker exec prometheus prometheus --version 2>&1 | Select-String "version"
} | ConvertTo-Json | Out-File "$BACKUP_DIR\metadata.json" -Encoding UTF8

Write-Host "✅ Prometheus backup completed!" -ForegroundColor Green
```

#### Snapshot des Données (Optionnel)

```bash
# Créer un snapshot des données Prometheus
curl -X POST http://localhost:9090/api/v1/admin/tsdb/snapshot

# Le snapshot est créé dans /prometheus/snapshots/
# Copier le snapshot
docker cp prometheus:/prometheus/snapshots ./backups/prometheus/snapshots
```

### Backup Alertmanager

```powershell
# Script backup-alertmanager.ps1
$BACKUP_DIR = ".\backups\alertmanager\$(Get-Date -Format 'yyyy-MM-dd_HH-mm-ss')"
New-Item -ItemType Directory -Force -Path $BACKUP_DIR | Out-Null

Write-Host "📦 Backing up Alertmanager configuration..." -ForegroundColor Cyan

# Copier la configuration
Copy-Item -Path ".\alertmanager\alertmanager.yml" -Destination "$BACKUP_DIR\alertmanager.yml"

# Copier les templates (si présents)
if (Test-Path ".\alertmanager\templates") {
    Copy-Item -Path ".\alertmanager\templates" -Destination "$BACKUP_DIR\templates" -Recurse
}

Write-Host "✅ Alertmanager backup completed!" -ForegroundColor Green
```

---

## 💾 Partie 4 : Backup Bases de Données (20 min)

### Backup InfluxDB

```powershell
# Script backup-influxdb.ps1
$BACKUP_DIR = ".\backups\influxdb\$(Get-Date -Format 'yyyy-MM-dd_HH-mm-ss')"
New-Item -ItemType Directory -Force -Path $BACKUP_DIR | Out-Null

Write-Host "📦 Backing up InfluxDB..." -ForegroundColor Cyan

# Backup via influx CLI
docker exec influxdb influx backup /tmp/backup

# Copier le backup
docker cp influxdb:/tmp/backup "$BACKUP_DIR"

Write-Host "✅ InfluxDB backup completed!" -ForegroundColor Green
```

### Backup MS SQL Server

```powershell
# Script backup-mssql.ps1
$BACKUP_DIR = ".\backups\mssql\$(Get-Date -Format 'yyyy-MM-dd_HH-mm-ss')"
New-Item -ItemType Directory -Force -Path $BACKUP_DIR | Out-Null

Write-Host "📦 Backing up MS SQL Server..." -ForegroundColor Cyan

# Backup via sqlcmd
$SA_PASSWORD = $env:MSSQL_SA_PASSWORD

docker exec mssql /opt/mssql-tools18/bin/sqlcmd `
    -S localhost -U sa -P $SA_PASSWORD -C `
    -Q "BACKUP DATABASE [EBanking] TO DISK = '/backup/ebanking.bak' WITH FORMAT"

# Copier le backup
Copy-Item -Path ".\mssql\backup\ebanking.bak" -Destination "$BACKUP_DIR\ebanking.bak"

Write-Host "✅ MS SQL backup completed!" -ForegroundColor Green
```

---

## 🔄 Partie 5 : Restauration (20 min)

### Restaurer Grafana

#### Script PowerShell de Restauration

```powershell
# restore-grafana.ps1
param(
    [Parameter(Mandatory=$true)]
    [string]$BackupPath
)

$GRAFANA_URL = "http://localhost:3000"
$GRAFANA_USER = "admin"
$GRAFANA_PASSWORD = "GrafanaSecure123!Change@Me"

$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${GRAFANA_USER}:${GRAFANA_PASSWORD}"))
$headers = @{
    Authorization = "Basic $base64AuthInfo"
    "Content-Type" = "application/json"
}

Write-Host "🔄 Restoring Grafana from: $BackupPath" -ForegroundColor Cyan

# 1. Restaurer les Datasources
Write-Host "`n🔌 Restoring datasources..." -ForegroundColor Cyan
$datasourcesPath = "$BackupPath\datasources"

if (Test-Path $datasourcesPath) {
    Get-ChildItem "$datasourcesPath\*.json" | ForEach-Object {
        $ds = Get-Content $_.FullName | ConvertFrom-Json
        
        try {
            Invoke-RestMethod -Uri "$GRAFANA_URL/api/datasources" `
                -Headers $headers -Method Post -Body ($ds | ConvertTo-Json -Depth 10)
            Write-Host "  ✅ $($ds.name)" -ForegroundColor Green
        } catch {
            Write-Host "  ⚠️  $($ds.name) - $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }
}

# 2. Restaurer les Folders
Write-Host "`n📁 Restoring folders..." -ForegroundColor Cyan
$foldersPath = "$BackupPath\folders\folders.json"

if (Test-Path $foldersPath) {
    $folders = Get-Content $foldersPath | ConvertFrom-Json
    
    foreach ($folder in $folders) {
        try {
            $body = @{
                title = $folder.title
                uid = $folder.uid
            } | ConvertTo-Json
            
            Invoke-RestMethod -Uri "$GRAFANA_URL/api/folders" `
                -Headers $headers -Method Post -Body $body
            Write-Host "  ✅ $($folder.title)" -ForegroundColor Green
        } catch {
            Write-Host "  ⚠️  $($folder.title)" -ForegroundColor Yellow
        }
    }
}

# 3. Restaurer les Dashboards
Write-Host "`n📊 Restoring dashboards..." -ForegroundColor Cyan
$dashboardsPath = "$BackupPath\dashboards"

if (Test-Path $dashboardsPath) {
    Get-ChildItem "$dashboardsPath\*.json" | ForEach-Object {
        $dashboard = Get-Content $_.FullName | ConvertFrom-Json
        
        $body = @{
            dashboard = $dashboard.dashboard
            overwrite = $true
        } | ConvertTo-Json -Depth 100
        
        try {
            Invoke-RestMethod -Uri "$GRAFANA_URL/api/dashboards/db" `
                -Headers $headers -Method Post -Body $body
            Write-Host "  ✅ $($dashboard.dashboard.title)" -ForegroundColor Green
        } catch {
            Write-Host "  ⚠️  $($dashboard.dashboard.title)" -ForegroundColor Yellow
        }
    }
}

Write-Host "`n✅ Restore completed!" -ForegroundColor Green
```

#### Exécuter la Restauration

```powershell
.\scripts\restore-grafana.ps1 -BackupPath ".\backups\grafana\2024-10-27_00-00-00"
```

### Restaurer Prometheus

```powershell
# Arrêter Prometheus
docker-compose stop prometheus

# Restaurer la configuration
Copy-Item -Path ".\backups\prometheus\*\prometheus.yml" -Destination ".\prometheus\prometheus.yml" -Force
Copy-Item -Path ".\backups\prometheus\*\rules\*" -Destination ".\prometheus\rules\" -Recurse -Force

# Redémarrer
docker-compose start prometheus
```

### Restaurer MS SQL

```powershell
# Restaurer la base de données
docker exec mssql /opt/mssql-tools18/bin/sqlcmd `
    -S localhost -U sa -P $env:MSSQL_SA_PASSWORD -C `
    -Q "RESTORE DATABASE [EBanking] FROM DISK = '/backup/ebanking.bak' WITH REPLACE"
```

---

## 🤖 Partie 6 : Automatisation (10 min)

### Tâche Planifiée Windows

```powershell
# Créer une tâche planifiée pour backup quotidien
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" `
    -Argument "-File C:\path\to\backup-grafana.ps1"

$trigger = New-ScheduledTaskTrigger -Daily -At 2am

$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount

Register-ScheduledTask -TaskName "GrafanaBackup" `
    -Action $action -Trigger $trigger -Principal $principal `
    -Description "Daily Grafana backup"
```

### Script Bash (Linux)

```bash
#!/bin/bash
# backup-all.sh

BACKUP_ROOT="/backups/observability"
DATE=$(date +%Y-%m-%d_%H-%M-%S)

# Grafana
echo "Backing up Grafana..."
python3 /path/to/backup-grafana.py

# Prometheus
echo "Backing up Prometheus..."
cp -r /etc/prometheus "$BACKUP_ROOT/prometheus-$DATE"

# Retention: garder 30 jours
find "$BACKUP_ROOT" -type d -mtime +30 -exec rm -rf {} \;

echo "Backup completed!"
```

### Cron Job

```bash
# Ajouter au crontab
crontab -e

# Backup quotidien à 2h du matin
0 2 * * * /path/to/backup-all.sh >> /var/log/backup.log 2>&1
```

---

## 📖 Ressources

### Documentation Officielle

- [Grafana Backup](https://grafana.com/docs/grafana/latest/administration/back-up-grafana/)
- [Prometheus Snapshot API](https://prometheus.io/docs/prometheus/latest/querying/api/#snapshot)
- [InfluxDB Backup](https://docs.influxdata.com/influxdb/v2.0/backup-restore/)

### Outils

- [grafana-backup-tool](https://github.com/ysde/grafana-backup-tool)
- [Terraform Grafana Provider](https://registry.terraform.io/providers/grafana/grafana/latest/docs)
- [Ansible Grafana Role](https://github.com/cloudalchemy/ansible-grafana)

---

## ✅ Checklist de Validation

Avant de passer au lab suivant, assurez-vous de :

- [ ] Comprendre la stratégie 3-2-1
- [ ] Savoir identifier les éléments critiques
- [ ] Pouvoir créer un backup complet de Grafana
- [ ] Pouvoir restaurer un dashboard
- [ ] Avoir automatisé les backups
- [ ] Avoir testé une restauration complète

---

## 🔙 Navigation

- [⬅️ Retour au Jour 3](../README.md)
- [➡️ Lab suivant : Lab 3.4 - Production](../Lab-3.4-Production/)
- [🏠 Accueil Formation](../../README-MAIN.md)

---

## 🎓 Points Clés à Retenir

1. **Stratégie 3-2-1** : 3 copies, 2 supports, 1 hors site
2. **Automatisation** : Les backups manuels sont oubliés
3. **Test de Restauration** : Un backup non testé n'est pas un backup
4. **Rétention** : Définir une politique de rétention claire
5. **Priorités** : Dashboards, datasources et alertes sont critiques
6. **Documentation** : Documenter la procédure de restauration

---

**🎉 Félicitations !** Vous maîtrisez maintenant le backup et la restauration de votre stack d'observabilité !

Passez au [Lab 3.4 - Production](../Lab-3.4-Production/) pour découvrir le déploiement en haute disponibilité.
