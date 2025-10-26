# 📊 Guide Professionnel des Requêtes Analytiques InfluxDB

## 🧭 Contexte
Ce document présente un ensemble de requêtes analytiques à exécuter dans **InfluxDB 2.x** à l'aide du **Flux Query Language**. Ces requêtes sont destinées à la supervision et l'analyse de systèmes transactionnels, tels que des plateformes **e-banking** ou **paiements temps réel**, dans un contexte d'observabilité (Grafana, Prometheus, Loki).

---

## ⚙️ Prérequis

Avant d'exécuter les requêtes :
1. Configurez la connexion à InfluxDB via le CLI :
   ```bash
   influx config create \
     --config-name onboarding \
     --host-url "http://51.79.24.138:8086" \
     --org "cf247d555ad5e0e4" \
     --token "<TOKEN>" \
     --active
   ```

2. Lancez le shell :
   ```bash
   influx v1 shell
   ```

3. Sélectionnez la base de données et le bucket approprié.

---

## 🧪 Requêtes de Validation des Données

```flux
// Validation du schéma
import "influxdata/influxdb/schema"

schema.measurements(bucket: "payments")
schema.tagKeys(bucket: "payments")
schema.fieldKeys(bucket: "payments")
```

Ces commandes permettent de vérifier la structure des données avant l'analyse.

---

## 💰 Requêtes Analytiques (Use Case: e-Banking / Paiements)

### 1️⃣ Nombre total de transactions par minute
```flux
from(bucket: "payments")
  |> range(start: -1h)
  |> filter(fn: (r) => r._measurement == "transactions")
  |> aggregateWindow(every: 1m, fn: count, createEmpty: false)
  |> yield(name: "transactions_per_minute")
```

### 2️⃣ Montant total des transactions par type
```flux
from(bucket: "payments")
  |> range(start: -24h)
  |> filter(fn: (r) => r._measurement == "transactions")
  |> group(columns: ["type"])
  |> sum(column: "amount")
  |> yield(name: "total_amount_by_type")
```

### 3️⃣ Montant moyen par canal (ATM, Mobile, Web)
```flux
from(bucket: "payments")
  |> range(start: -24h)
  |> filter(fn: (r) => r._measurement == "transactions")
  |> group(columns: ["channel"])
  |> mean(column: "amount")
  |> yield(name: "avg_amount_per_channel")
```

### 4️⃣ Taux d'erreurs de paiement par type de carte
```flux
from(bucket: "payments")
  |> range(start: -1d)
  |> filter(fn: (r) => r._measurement == "payment_status" and r.status == "failed")
  |> group(columns: ["card_type"])
  |> count()
  |> yield(name: "error_rate_by_card_type")
```

### 5️⃣ Temps moyen de traitement des paiements
```flux
from(bucket: "payments")
  |> range(start: -12h)
  |> filter(fn: (r) => r._measurement == "latency")
  |> mean(column: "processing_time_ms")
  |> yield(name: "avg_processing_time")
```

---

## 📈 Requêtes Avancées (Corrélations et Alerting)

### 6️⃣ Corrélation entre latence et volume des transactions
```flux
join(
  tables: {
    latency: from(bucket: "payments") |> range(start: -1h) |> filter(fn: (r) => r._measurement == "latency"),
    volume: from(bucket: "payments") |> range(start: -1h) |> filter(fn: (r) => r._measurement == "transactions")
  },
  on: ["_time"]
)
  |> map(fn: (r) => ({ r with correlation: r.processing_time_ms * r._value }))
  |> yield(name: "latency_volume_correlation")
```

### 7️⃣ Détection d’anomalies sur les transactions
```flux
import "experimental"

from(bucket: "payments")
  |> range(start: -6h)
  |> filter(fn: (r) => r._measurement == "transactions")
  |> aggregateWindow(every: 5m, fn: mean)
  |> experimental.detectThresholds(lower: 0, upper: 1000)
  |> yield(name: "anomaly_detection")
```

---

## 📋 Notes pour Validation Notebook
Dans un environnement **InfluxDB Cloud Notebook**, chaque cellule peut être validée via :
```text
Query to Run
// Uncomment the following line to continue building from the previous cell
// __PREVIOUS_RESULT__

Validate the Data
```

---

## 🧠 Bonnes Pratiques
- Utiliser des **windows temporelles fixes** (`aggregateWindow`) pour l’analyse continue.
- Grouper les données par **dimensions analytiques** (`type`, `channel`, `card_type`).
- Implémenter des **dashboards Grafana** basés sur ces requêtes.
- Automatiser les **alertes** via **Kapacitor** ou les **Alert Rules** de Grafana.

---

## 🔒 Sécurité et Observabilité
- Token d’accès à conserver dans des variables d’environnement :
  ```bash
  export INFLUX_TOKEN="<token>"
  ```
- Surveiller l’état du bucket via :
  ```bash
  influx bucket list
  ```
- Vérifier les logs des erreurs et les codes `401 Unauthorized` en cas de token expiré.

---

**Auteur :** Mokhtar Sellami  
**Organisation :** Data2AI SARL  
**Date :** Octobre 2025  
**Version :** 1.0 Professionnelle

