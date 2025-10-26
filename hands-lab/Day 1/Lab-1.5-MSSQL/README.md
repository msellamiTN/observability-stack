# 💾 Lab 1.5 : Datasource MS SQL Server

**⏱️ Durée** : 1h30 | **👤 Niveau** : Débutant | **💻 Type** : Pratique

---

## 🎯 Objectifs

À la fin de ce lab, vous serez capable de :

✅ Configurer MS SQL Server comme datasource dans Grafana  
✅ Écrire des requêtes SQL pour visualisation  
✅ Utiliser les macros Grafana pour SQL  
✅ Visualiser des données métier (E-Banking)  
✅ Créer des dashboards avec données relationnelles  
✅ Comprendre les différences entre TSDB et RDBMS  

---

## 🛠️ Prérequis

- ✅ Lab 1.2 complété (Stack démarrée)
- ✅ MS SQL Server en cours d'exécution
- ✅ Grafana accessible

---

## 📚 Introduction à MS SQL Server

### Pourquoi SQL Server dans Grafana ?

**MS SQL Server** est une base de données relationnelle idéale pour :
- 💼 **Données métier** : Transactions, clients, comptes
- 📊 **Reporting** : KPIs business, analytics
- 🔗 **Données existantes** : Intégration avec systèmes legacy
- 📈 **Time-based data** : Logs applicatifs, audit trails

### TSDB vs RDBMS

| Aspect | TSDB (InfluxDB, Prometheus) | RDBMS (MS SQL) |
|--------|----------------------------|----------------|
| **Optimisé pour** | Séries temporelles | Données relationnelles |
| **Structure** | Schemaless, tags/fields | Tables, colonnes, relations |
| **Requêtes** | Flux, PromQL | SQL |
| **Agrégation** | Très rapide | Rapide avec index |
| **Joins** | Limité | Excellent |
| **Use case** | Métriques, monitoring | Business data, transactions |

---

## 🔍 Étape 1 : Vérification de MS SQL Server

### Windows (PowerShell)

```powershell
# Vérifier le statut
docker compose ps mssql

# Tester la connexion
docker compose exec mssql /opt/mssql-tools18/bin/sqlcmd `
  -S localhost -U sa -P "EBanking@Secure123!" -C `
  -Q "SELECT @@VERSION"
```

### Linux

```bash
# Vérifier le statut
docker compose ps mssql

# Tester la connexion
docker compose exec mssql /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U sa -P "EBanking@Secure123!" -C \
  -Q "SELECT @@VERSION"
```

---

## 🗄️ Étape 2 : Explorer la Base de Données

### 2.1 Connexion via sqlcmd

```bash
# Entrer dans le conteneur
docker compose exec mssql bash

# Lancer sqlcmd
/opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "EBanking@Secure123!" -C
```

### 2.2 Commandes SQL Utiles

```sql
-- Lister les bases de données
SELECT name FROM sys.databases;
GO

-- Utiliser la base EBankingDB
USE EBankingDB;
GO

-- Lister les tables
SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES;
GO

-- Voir la structure d'une table
EXEC sp_help 'Transactions';
GO

-- Compter les enregistrements
SELECT COUNT(*) FROM Transactions;
GO
```

### 2.3 Structure de la Base E-Banking

```
EBankingDB
├── Customers
│   ├── CustomerID (PK)
│   ├── FirstName
│   ├── LastName
│   ├── Email
│   └── CreatedDate
├── Accounts
│   ├── AccountID (PK)
│   ├── CustomerID (FK)
│   ├── AccountType
│   ├── Balance
│   └── CreatedDate
├── Transactions
│   ├── TransactionID (PK)
│   ├── AccountID (FK)
│   ├── TransactionType
│   ├── Amount
│   ├── Status
│   └── TransactionDate
└── FraudAlerts
    ├── AlertID (PK)
    ├── TransactionID (FK)
    ├── RiskScore
    ├── AlertType
    └── DetectedDate
```

---

## ⚙️ Étape 3 : Configuration dans Grafana

### 3.1 Ajouter la Datasource

1. Grafana → **Connections** → **Data sources**
2. Cliquer **Add data source**
3. Chercher **Microsoft SQL Server**

### 3.2 Configuration

```yaml
Name: MS SQL Server - E-Banking
Host: mssql:1433
Database: EBankingDB
User: sa
Password: EBanking@Secure123!
Encrypt: false
Max open connections: 100
Max idle connections: 100
Max connection lifetime: 14400
```

4. Cliquer **Save & Test**
5. Message attendu : ✅ "Database Connection OK"

### 💡 Tips

> **🔐 Sécurité** : En production, créez un utilisateur SQL dédié avec permissions limitées (SELECT only).

> **🌐 Host** : Utilisez `mssql:1433` (nom du service Docker), pas `localhost`.

---

## 📝 Étape 4 : Requêtes SQL dans Grafana

### 4.1 Format de Requête

Grafana attend un format spécifique :

```sql
SELECT
  <time_column> AS time,
  <value_column> AS value,
  <series_name_column> AS metric
FROM <table>
WHERE $__timeFilter(<time_column>)
ORDER BY time
```

### 4.2 Macros Grafana

| Macro | Description | Exemple |
|-------|-------------|---------|
| `$__timeFilter(column)` | Filtre temporel | `WHERE $__timeFilter(TransactionDate)` |
| `$__timeFrom()` | Date de début | `WHERE date >= $__timeFrom()` |
| `$__timeTo()` | Date de fin | `WHERE date <= $__timeTo()` |
| `$__timeGroup(column, interval)` | Groupement temporel | `GROUP BY $__timeGroup(date, '1h')` |
| `$__unixEpochFilter(column)` | Filtre Unix timestamp | `WHERE $__unixEpochFilter(timestamp)` |

### 4.3 Exemple Simple

```sql
SELECT
  TransactionDate AS time,
  Amount AS value,
  TransactionType AS metric
FROM Transactions
WHERE $__timeFilter(TransactionDate)
ORDER BY time
```

---

## 🧪 Étape 5 : Créer des Données de Test

### 5.1 Script SQL d'Initialisation

```sql
USE EBankingDB;
GO

-- Créer la table Transactions si elle n'existe pas
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Transactions')
BEGIN
    CREATE TABLE Transactions (
        TransactionID INT IDENTITY(1,1) PRIMARY KEY,
        AccountID INT NOT NULL,
        TransactionType VARCHAR(50) NOT NULL,
        Amount DECIMAL(18,2) NOT NULL,
        Status VARCHAR(20) NOT NULL,
        TransactionDate DATETIME NOT NULL DEFAULT GETDATE()
    );
END
GO

-- Insérer des données de test
DECLARE @i INT = 1;
DECLARE @types TABLE (TransactionType VARCHAR(50));
INSERT INTO @types VALUES ('DEPOSIT'), ('WITHDRAWAL'), ('TRANSFER'), ('PAYMENT');

WHILE @i <= 100
BEGIN
    INSERT INTO Transactions (AccountID, TransactionType, Amount, Status, TransactionDate)
    VALUES (
        FLOOR(RAND() * 10) + 1,  -- AccountID aléatoire 1-10
        (SELECT TOP 1 TransactionType FROM @types ORDER BY NEWID()),
        ROUND(RAND() * 1000 + 10, 2),  -- Montant 10-1010
        CASE WHEN RAND() > 0.1 THEN 'SUCCESS' ELSE 'FAILED' END,
        DATEADD(MINUTE, -@i * 10, GETDATE())  -- Espacé de 10 minutes
    );
    SET @i = @i + 1;
END
GO

-- Vérifier
SELECT COUNT(*) AS TotalTransactions FROM Transactions;
GO
```

### 5.2 Exécuter le Script

```bash
# Via Docker
docker compose exec mssql /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U sa -P "EBanking@Secure123!" -C \
  -i /path/to/init.sql
```

---

## 📊 Étape 6 : Requêtes Pratiques

### 6.1 Volume de Transactions par Heure

```sql
SELECT
  DATEADD(HOUR, DATEDIFF(HOUR, 0, TransactionDate), 0) AS time,
  COUNT(*) AS value,
  'Transactions' AS metric
FROM Transactions
WHERE $__timeFilter(TransactionDate)
GROUP BY DATEADD(HOUR, DATEDIFF(HOUR, 0, TransactionDate), 0)
ORDER BY time
```

### 6.2 Montant Total par Type

```sql
SELECT
  TransactionDate AS time,
  SUM(Amount) AS value,
  TransactionType AS metric
FROM Transactions
WHERE $__timeFilter(TransactionDate)
  AND Status = 'SUCCESS'
GROUP BY 
  DATEADD(HOUR, DATEDIFF(HOUR, 0, TransactionDate), 0),
  TransactionType
ORDER BY time
```

### 6.3 Taux de Succès/Échec

```sql
SELECT
  DATEADD(HOUR, DATEDIFF(HOUR, 0, TransactionDate), 0) AS time,
  CAST(SUM(CASE WHEN Status = 'SUCCESS' THEN 1 ELSE 0 END) AS FLOAT) / COUNT(*) * 100 AS value,
  'Success Rate' AS metric
FROM Transactions
WHERE $__timeFilter(TransactionDate)
GROUP BY DATEADD(HOUR, DATEDIFF(HOUR, 0, TransactionDate), 0)
ORDER BY time
```

### 6.4 Top 5 Comptes par Volume

```sql
SELECT TOP 5
  AccountID AS metric,
  SUM(Amount) AS value
FROM Transactions
WHERE $__timeFilter(TransactionDate)
  AND Status = 'SUCCESS'
GROUP BY AccountID
ORDER BY value DESC
```

### 6.5 Montant Moyen par Type

```sql
SELECT
  TransactionType AS metric,
  AVG(Amount) AS value
FROM Transactions
WHERE $__timeFilter(TransactionDate)
  AND Status = 'SUCCESS'
GROUP BY TransactionType
```

---

## 📊 Étape 7 : Créer un Dashboard E-Banking

### 7.1 Panel 1 : Transactions par Heure

**Query** :
```sql
SELECT
  DATEADD(HOUR, DATEDIFF(HOUR, 0, TransactionDate), 0) AS time,
  COUNT(*) AS value
FROM Transactions
WHERE $__timeFilter(TransactionDate)
GROUP BY DATEADD(HOUR, DATEDIFF(HOUR, 0, TransactionDate), 0)
ORDER BY time
```

**Config** :
- Title : "Transactions par Heure"
- Visualization : Time series
- Unit : short

### 7.2 Panel 2 : Montant Total

**Query** :
```sql
SELECT
  SUM(Amount) AS value
FROM Transactions
WHERE $__timeFilter(TransactionDate)
  AND Status = 'SUCCESS'
```

**Config** :
- Title : "Montant Total"
- Visualization : Stat
- Unit : Currency → Euro (€)

### 7.3 Panel 3 : Taux de Succès

**Query** :
```sql
SELECT
  CAST(SUM(CASE WHEN Status = 'SUCCESS' THEN 1 ELSE 0 END) AS FLOAT) / COUNT(*) * 100 AS value
FROM Transactions
WHERE $__timeFilter(TransactionDate)
```

**Config** :
- Title : "Taux de Succès"
- Visualization : Gauge
- Unit : Percent (0-100)
- Thresholds : 90 (yellow), 95 (green)

### 7.4 Panel 4 : Répartition par Type

**Query** :
```sql
SELECT
  TransactionType AS metric,
  COUNT(*) AS value
FROM Transactions
WHERE $__timeFilter(TransactionDate)
GROUP BY TransactionType
```

**Config** :
- Title : "Répartition par Type"
- Visualization : Pie chart
- Legend : Show

---

## 🎯 Exercices Pratiques

### Exercice 1 : Transactions Échouées

Créez une requête qui affiche le nombre de transactions échouées par heure.

<details>
<summary>💡 Solution</summary>

```sql
SELECT
  DATEADD(HOUR, DATEDIFF(HOUR, 0, TransactionDate), 0) AS time,
  COUNT(*) AS value
FROM Transactions
WHERE $__timeFilter(TransactionDate)
  AND Status = 'FAILED'
GROUP BY DATEADD(HOUR, DATEDIFF(HOUR, 0, TransactionDate), 0)
ORDER BY time
```
</details>

### Exercice 2 : Montant Moyen par Jour

Calculez le montant moyen des transactions par jour.

<details>
<summary>💡 Solution</summary>

```sql
SELECT
  CAST(TransactionDate AS DATE) AS time,
  AVG(Amount) AS value
FROM Transactions
WHERE $__timeFilter(TransactionDate)
  AND Status = 'SUCCESS'
GROUP BY CAST(TransactionDate AS DATE)
ORDER BY time
```
</details>

### Exercice 3 : Détection d'Anomalies

Trouvez les transactions avec un montant supérieur à 3x la moyenne.

<details>
<summary>💡 Solution</summary>

```sql
WITH AvgAmount AS (
  SELECT AVG(Amount) AS avg_amount
  FROM Transactions
  WHERE $__timeFilter(TransactionDate)
)
SELECT
  TransactionDate AS time,
  Amount AS value,
  CONCAT('Account ', AccountID) AS metric
FROM Transactions, AvgAmount
WHERE $__timeFilter(TransactionDate)
  AND Amount > (avg_amount * 3)
ORDER BY time
```
</details>

---

## 🐛 Troubleshooting

### Problème 1 : Connection failed

**Solutions** :

```powershell
# Vérifier que SQL Server est démarré
docker compose ps mssql

# Tester la connexion
docker compose exec mssql /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "EBanking@Secure123!" -C -Q "SELECT 1"

# Vérifier le mot de passe dans .env
cat .env | Select-String "MSSQL"
```

### Problème 2 : No data returned

**Solutions** :

```sql
-- Vérifier que des données existent
SELECT COUNT(*) FROM Transactions;

-- Vérifier la plage de dates
SELECT MIN(TransactionDate), MAX(TransactionDate) FROM Transactions;

-- Élargir la période dans Grafana (Last 7 days)
```

### Problème 3 : Query timeout

**Solutions** :

```sql
-- Ajouter des index
CREATE INDEX IX_Transactions_Date ON Transactions(TransactionDate);
CREATE INDEX IX_Transactions_Status ON Transactions(Status);

-- Limiter les résultats
SELECT TOP 1000 * FROM Transactions
WHERE $__timeFilter(TransactionDate)
ORDER BY TransactionDate DESC;
```

---

## 📚 Ressources

### Documentation
- [Grafana MS SQL](https://grafana.com/docs/grafana/latest/datasources/mssql/)
- [SQL Server Docs](https://learn.microsoft.com/en-us/sql/)
- [T-SQL Reference](https://learn.microsoft.com/en-us/sql/t-sql/)

### Fonctions SQL Utiles

```sql
-- DATE/TIME
GETDATE()                           -- Date actuelle
DATEADD(hour, -1, GETDATE())       -- Soustraire 1 heure
DATEDIFF(day, date1, date2)        -- Différence en jours
CAST(date AS DATE)                 -- Convertir en date

-- AGRÉGATIONS
COUNT(*), SUM(col), AVG(col)
MIN(col), MAX(col)
COUNT(DISTINCT col)

-- CONDITIONNELLES
CASE WHEN condition THEN value ELSE value END
IIF(condition, true_value, false_value)

-- STRING
CONCAT(str1, str2)
SUBSTRING(str, start, length)
UPPER(str), LOWER(str)
```

---

## ✅ Validation

- [ ] MS SQL Server accessible
- [ ] Connexion réussie via sqlcmd
- [ ] Base EBankingDB explorée
- [ ] Datasource configurée dans Grafana
- [ ] Données de test créées
- [ ] Requêtes SQL exécutées
- [ ] Dashboard E-Banking créé
- [ ] Exercices complétés

---

## 🎯 Prochaines Étapes

➡️ **Lab 1.6** : [Premier Dashboard Multi-Sources](../Lab-1.6-Dashboard/)

Dans le prochain lab :
- Combiner InfluxDB, Prometheus et MS SQL
- Variables de dashboard
- Drill-down entre panels
- Dashboard complet E-Banking

---

**🎓 Félicitations !** Vous maîtrisez maintenant l'intégration SQL Server dans Grafana !
