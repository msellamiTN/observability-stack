# Guide Analytique Professionnel InfluxDB

## 🎯 Objectif
Ce guide décrit comment exécuter et visualiser des requêtes analytiques dans l’interface graphique (GUI) d’InfluxDB. Il s’adresse aux ingénieurs de données, administrateurs système et analystes souhaitant surveiller et analyser des données de paiement ou de performance applicative.

---

## 🧩 1. Connexion à InfluxDB

### Via Interface Web
1. Accédez à l’URL de votre instance InfluxDB (ex. `http://51.79.24.138:8086`)
2. Connectez-vous avec :
   - **Organisation (Org ID)** : `cf247d555ad5e0e4`
   - **Token** : `6ea4A1AKsmd32DbiGZs6XNO_g12X-6aPCB_kdpPkGpAZAlBpyHG8zjAR6oMMuaPgK5RUz-9KKfvIio9JXskoCQ==`
   - **Bucket** : `payments`

### Vérification de la connexion
Dans le terminal ou le shell InfluxDB :
```bash
influx ping
```
Si la réponse est `pong`, la connexion est opérationnelle.

---

## 📊 2. Exécution de requêtes analytiques dans le Data Explorer

Ouvrez le **Data Explorer** dans l’interface InfluxDB et sélectionnez le bucket `payments`.

### a) Volume de paiements par jour
```flux
from(bucket: "payments")
  |> range(start: -7d)
  |> filter(fn: (r) => r._measurement == "transactions")
  |> filter(fn: (r) => r._field == "amount")
  |> aggregateWindow(every: 1d, fn: sum)
  |> yield(name: "daily_total")
```

### b) Taux de réussite / échec des transactions
```flux
from(bucket: "payments")
  |> range(start: -7d)
  |> filter(fn: (r) => r._measurement == "transactions")
  |> filter(fn: (r) => r._field == "status")
  |> group(columns: ["status"])
  |> count()
```

### c) Montant moyen des paiements
```flux
from(bucket: "payments")
  |> range(start: -30d)
  |> filter(fn: (r) => r._measurement == "transactions")
  |> filter(fn: (r) => r._field == "amount")
  |> mean()
```

### d) Top 5 clients par volume de paiement
```flux
from(bucket: "payments")
  |> range(start: -30d)
  |> filter(fn: (r) => r._measurement == "transactions")
  |> group(columns: ["customer_id"])
  |> sum(column: "_value")
  |> sort(columns: ["_value"], desc: true)
  |> limit(n: 5)
```

---

## 📈 3. Visualisation des résultats
Dans le **Data Explorer** :
- Cliquez sur **Script Editor** → Collez la requête.
- Cliquez sur **Submit** pour exécuter.
- Dans l’onglet **Graphique**, choisissez un type de visualisation :
  - **Line Chart** pour les tendances temporelles.
  - **Bar Chart** pour les volumes agrégés.
  - **Gauge** pour les moyennes ou taux de réussite.

---

## ⚙️ 4. Exportation et automatisation

### Exporter en CSV
Cliquez sur **Download CSV** après exécution de la requête.

### Intégration dans Grafana (optionnelle)
1. Ajoutez InfluxDB comme source de données.
2. Importez un tableau de bord.
3. Liez les requêtes ci-dessus à vos panneaux.

---

## 🧠 Bonnes pratiques
- Limitez la fenêtre temporelle (`range`) pour optimiser les performances.
- Utilisez `aggregateWindow()` pour réduire le volume de points.
- Protégez les tokens via des variables d’environnement.

---

**Auteur :** Équipe Data2AI
**Version :** 1.0 — Octobre 2025
**Licence :** Interne — Confidentialité requise.