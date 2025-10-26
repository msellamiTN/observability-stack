# 🔧 Fix: Datasource Provisioning Error

## ❌ Problème
```
Datasource provisioning error: datasource.yaml config is invalid. 
Only one datasource per organization can be marked as default
```

## 🔍 Cause
Grafana charge **plusieurs fichiers** de datasources et trouve des conflits :
- `prometheus-datasource.yaml` - a `isDefault: true`
- `mssql.yml` - a `isDefault: false`
- `datasources.yaml` - nouveau fichier unifié (a aussi `isDefault: true`)

**Résultat** : Grafana voit 2 datasources avec `isDefault: true` → ERREUR

## ✅ Solution

### Étape 1 : Supprimer les anciens fichiers

Supprimez manuellement ces 2 fichiers dans le dossier `datasources/` :
```
❌ prometheus-datasource.yaml
❌ mssql.yml
```

### Étape 2 : Garder uniquement le nouveau fichier

```
✅ datasources.yaml  (fichier unifié avec les 2 datasources)
```

### Étape 3 : Redémarrer Grafana

```bash
docker-compose restart grafana
# ou
docker restart grafana
```

## 📋 Contenu du nouveau fichier `datasources.yaml`

Le fichier contient maintenant **les 2 datasources** :

1. **Prometheus** (default)
   - URL: `http://prometheus:9090`
   - `isDefault: true` ✅
   - UID: `prometheus`

2. **MS SQL Server - E-Banking**
   - URL: `mssql:1433`
   - `isDefault: false`
   - UID: `mssql_ebanking`

## 🎯 Avantages de cette approche

✅ **Un seul fichier** = pas de conflits
✅ **Section `deleteDatasources`** = nettoie les anciennes datasources
✅ **UIDs explicites** = références stables dans les dashboards
✅ **Configuration complète** = tous les paramètres en un endroit

## 🔄 Alternative (si vous ne voulez pas supprimer)

Renommez les anciens fichiers avec `.bak` :
```
prometheus-datasource.yaml → prometheus-datasource.yaml.bak
mssql.yml → mssql.yml.bak
```

Grafana n'ignore que les fichiers `.yaml` et `.yml`, donc `.bak` sera ignoré.

## ✅ Vérification

Après redémarrage, vérifiez les logs :
```bash
docker logs grafana 2>&1 | grep -i datasource
```

Vous devriez voir :
```
✅ Provisioned datasource: Prometheus
✅ Provisioned datasource: MS SQL Server - E-Banking
```

Sans erreurs !
