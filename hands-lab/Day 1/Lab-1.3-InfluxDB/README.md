# 🗄️ Lab 1.3 : Datasource InfluxDB

**⏱️ Durée** : 1h30 | **👤 Niveau** : Débutant | **💻 Type** : Pratique

---

## 🎯 Objectifs

À la fin de ce lab, vous serez capable de :

✅ Comprendre le modèle de données InfluxDB (Buckets, Measurements, Tags, Fields)  
✅ Accéder à l'interface web InfluxDB  
✅ Configurer InfluxDB comme datasource dans Grafana  
✅ Écrire des requêtes Flux basiques  
✅ Créer des données de test  
✅ Visualiser des séries temporelles dans Grafana  

---

## 🛠️ Prérequis

- ✅ Lab 1.2 complété (Stack démarrée)
- ✅ InfluxDB en cours d'exécution
- ✅ Grafana accessible

---

## 📚 Introduction à InfluxDB

**InfluxDB** est une base de données de séries temporelles (TSDB) optimisée pour :
- 📈 Métriques (CPU, RAM, latence)
- 💰 Données métier (Transactions, ventes)
- 🌡️ IoT (Capteurs, température)

### Modèle de Données

```
Organization (myorg)
  └─ Bucket (payments)              # Database
      └─ Measurement (transactions) # Table
          ├─ Tags (indexed)         # Métadonnées
          │   ├─ customer_id
          │   └─ payment_method
          ├─ Fields (values)        # Valeurs
          │   ├─ amount
          │   └─ processing_time
          └─ Timestamp
```

---

## 🔍 Étape 1 : Vérification d'InfluxDB

### Windows (PowerShell)

```powershell
# Vérifier le statut
docker compose ps influxdb

# Vérifier la santé
Invoke-WebRequest -Uri http://localhost:8086/health -UseBasicParsing
```

### Linux

```bash
docker compose ps influxdb
curl http://localhost:8086/health
```

---

## 🌐 Étape 2 : Interface Web InfluxDB

**URL** : http://localhost:8086

**Credentials** :
- Username : `admin`
- Password : `InfluxSecure123!Change@Me`
- Organization : `myorg`
- Bucket : `payments`

### Navigation

- **📊 Data Explorer** : Requêtes et exploration
- **⚙️ Settings** : Buckets, Tokens, Users

---

## ⚙️ Étape 3 : Configuration dans Grafana

### 3.1 Accéder à Grafana

http://localhost:3000

### 3.2 Ajouter la Datasource

1. Menu → **Connections** → **Data sources**
2. Cliquer **Add data source**
3. Chercher et sélectionner **InfluxDB**

### 3.3 Configuration

```yaml
Name: InfluxDB
Query Language: Flux
URL: http://influxdb:8086
Auth: Basic auth OFF
Organization: myorg
Token: my-super-secret-auth-token
Default Bucket: payments
```

4. Cliquer **Save & Test**
5. Message attendu : ✅ "datasource is working"

### 💡 Tips

> **🔑 Token** : Le token est dans le fichier `.env` : `INFLUXDB_TOKEN`

> **🌐 URL** : Utilisez `http://influxdb:8086` (nom du service Docker), pas `localhost`

---

## 📝 Étape 4 : Langage Flux - Bases

### Structure d'une Requête Flux

```flux
from(bucket: "payments")          // Source
  |> range(start: -1h)            // Période
  |> filter(fn: (r) =>            // Filtres
      r._measurement == "transactions"
  )
  |> filter(fn: (r) =>
      r._field == "amount"
  )
  |> aggregateWindow(             // Agrégation
      every: 5m,
      fn: mean
  )
```

### Fonctions Principales

| Fonction | Description | Exemple |
|----------|-------------|---------|
| `from()` | Source de données | `from(bucket: "payments")` |
| `range()` | Période temporelle | `range(start: -1h)` |
| `filter()` | Filtrer les données | `filter(fn: (r) => r.status == "success")` |
| `mean()` | Moyenne | `mean()` |
| `sum()` | Somme | `sum()` |
| `count()` | Comptage | `count()` |
| `aggregateWindow()` | Agrégation par fenêtre | `aggregateWindow(every: 5m, fn: mean)` |

---

## 🧪 Étape 5 : Créer des Données de Test

### 5.1 Via InfluxDB CLI

```bash
# Entrer dans le conteneur
docker compose exec influxdb bash

# Écrire des données
influx write \
  --bucket payments \
  --org myorg \
  --token my-super-secret-auth-token \
  --precision s \
  "transactions,customer_id=CUST001,payment_method=credit_card amount=150.50,processing_time=234"
```

### 5.2 Via Script PowerShell

```powershell
# Script pour générer des données de test
$token = "my-super-secret-auth-token"
$org = "myorg"
$bucket = "payments"
$url = "http://localhost:8086/api/v2/write?org=$org&bucket=$bucket&precision=s"

$headers = @{
    "Authorization" = "Token $token"
    "Content-Type" = "text/plain"
}

# Générer 10 transactions
for ($i = 1; $i -le 10; $i++) {
    $amount = Get-Random -Minimum 50 -Maximum 500
    $time = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
    
    $data = "transactions,customer_id=CUST00$i,payment_method=credit_card amount=$amount,processing_time=200 $time"
    
    Invoke-RestMethod -Uri $url -Method Post -Headers $headers -Body $data
    Write-Host "Transaction $i créée : $amount EUR"
    Start-Sleep -Seconds 1
}
```

### 5.3 Via Script Bash

```bash
#!/bin/bash
TOKEN="my-super-secret-auth-token"
ORG="myorg"
BUCKET="payments"
URL="http://localhost:8086/api/v2/write?org=$ORG&bucket=$BUCKET&precision=s"

for i in {1..10}; do
    AMOUNT=$((RANDOM % 450 + 50))
    TIME=$(date +%s)
    
    curl -X POST "$URL" \
      -H "Authorization: Token $TOKEN" \
      -H "Content-Type: text/plain" \
      --data-binary "transactions,customer_id=CUST00$i,payment_method=credit_card amount=$AMOUNT,processing_time=200 $TIME"
    
    echo "Transaction $i créée : $AMOUNT EUR"
    sleep 1
done
```

---

## 📊 Étape 6 : Première Visualisation dans Grafana

### 6.1 Créer un Dashboard

1. Grafana → **Dashboards** → **New** → **New Dashboard**
2. Cliquer **Add visualization**
3. Sélectionner **InfluxDB** comme datasource

### 6.2 Requête Flux Simple

```flux
from(bucket: "payments")
  |> range(start: -1h)
  |> filter(fn: (r) => r._measurement == "transactions")
  |> filter(fn: (r) => r._field == "amount")
```

### 6.3 Requête avec Agrégation

```flux
from(bucket: "payments")
  |> range(start: -24h)
  |> filter(fn: (r) => r._measurement == "transactions")
  |> filter(fn: (r) => r._field == "amount")
  |> aggregateWindow(every: 1h, fn: sum, createEmpty: false)
  |> yield(name: "hourly_total")
```

### 6.4 Configuration du Panel

- **Title** : "Montant Total des Transactions"
- **Visualization** : Time series
- **Unit** : Currency → Euro (€)
- **Legend** : Show

---

## 🎯 Exercices Pratiques

### Exercice 1 : Montant Moyen par Heure

Créez une requête qui calcule le montant moyen des transactions par heure sur les dernières 24h.

<details>
<summary>💡 Solution</summary>

```flux
from(bucket: "payments")
  |> range(start: -24h)
  |> filter(fn: (r) => r._measurement == "transactions")
  |> filter(fn: (r) => r._field == "amount")
  |> aggregateWindow(every: 1h, fn: mean)
  |> yield(name: "hourly_average")
```
</details>

### Exercice 2 : Comptage par Méthode de Paiement

Comptez le nombre de transactions par méthode de paiement.

<details>
<summary>💡 Solution</summary>

```flux
from(bucket: "payments")
  |> range(start: -24h)
  |> filter(fn: (r) => r._measurement == "transactions")
  |> filter(fn: (r) => r._field == "amount")
  |> group(columns: ["payment_method"])
  |> count()
```
</details>

### Exercice 3 : Top 5 Clients

Trouvez les 5 clients avec le plus grand volume de transactions.

<details>
<summary>💡 Solution</summary>

```flux
from(bucket: "payments")
  |> range(start: -7d)
  |> filter(fn: (r) => r._measurement == "transactions")
  |> filter(fn: (r) => r._field == "amount")
  |> group(columns: ["customer_id"])
  |> sum()
  |> sort(columns: ["_value"], desc: true)
  |> limit(n: 5)
```
</details>

---

## 🐛 Troubleshooting

### Problème 1 : Datasource connection failed

**Symptômes** : Erreur lors du test de la datasource

**Solutions** :

```powershell
# Vérifier qu'InfluxDB est démarré
docker compose ps influxdb

# Vérifier le token
cat .env | Select-String "INFLUXDB_TOKEN"

# Tester la connexion
curl -H "Authorization: Token my-super-secret-auth-token" http://localhost:8086/api/v2/buckets
```

### Problème 2 : No data returned

**Symptômes** : La requête ne retourne aucune donnée

**Solutions** :

1. Vérifiez que des données existent :

```flux
from(bucket: "payments")
  |> range(start: -30d)
  |> limit(n: 10)
```

2. Vérifiez le nom du bucket et measurement
3. Élargissez la période : `range(start: -30d)`

### Problème 3 : Query timeout

**Symptômes** : La requête prend trop de temps

**Solutions** :

```flux
// Réduire la période
from(bucket: "payments")
  |> range(start: -1h)  // Au lieu de -30d
  
// Utiliser aggregateWindow
  |> aggregateWindow(every: 5m, fn: mean)
```

---

## 📚 Ressources

### Documentation
- [InfluxDB Docs](https://docs.influxdata.com/)
- [Flux Language](https://docs.influxdata.com/flux/)
- [Grafana InfluxDB](https://grafana.com/docs/grafana/latest/datasources/influxdb/)

### Cheat Sheet Flux

```flux
// Fonctions de base
from(bucket: "name")
range(start: -1h, stop: now())
filter(fn: (r) => r._measurement == "name")

// Agrégations
mean(), sum(), count(), min(), max()
aggregateWindow(every: 5m, fn: mean)

// Grouping
group(columns: ["tag1", "tag2"])
group()  // Ungroup

// Tri et limite
sort(columns: ["_value"], desc: true)
limit(n: 10)
```

---

## ✅ Validation

- [ ] InfluxDB accessible sur http://localhost:8086
- [ ] Connexion réussie à l'interface web
- [ ] Datasource configurée dans Grafana
- [ ] Données de test créées
- [ ] Première requête Flux exécutée
- [ ] Panel créé dans un dashboard
- [ ] Exercices complétés

---

## 🎯 Prochaines Étapes

➡️ **Lab 1.4** : [Datasource Prometheus](../Lab-1.4-Prometheus/)

Dans le prochain lab :
- Configuration de Prometheus
- Langage PromQL
- Métriques système avec Node Exporter

---

**🎓 Félicitations !** Vous maîtrisez maintenant InfluxDB et le langage Flux !
