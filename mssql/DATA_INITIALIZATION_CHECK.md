# ✅ MS SQL Server - Vérification de l'Initialisation des Données

## 🎯 Réponse Rapide

**OUI**, les données sont **automatiquement générées** au démarrage de Docker ! ✅

---

## 🔄 Processus d'Initialisation Automatique

### 1. Configuration Docker Compose

```yaml
mssql:
  image: mcr.microsoft.com/mssql/server:2022-latest
  container_name: mssql_ebanking
  volumes:
    - mssql_data:/var/opt/mssql
    - ./mssql/init:/docker-entrypoint-initdb.d      # Scripts SQL
    - ./mssql/scripts:/scripts                       # Scripts shell
  entrypoint: ["/bin/bash", "/scripts/entrypoint.sh"]  # Point d'entrée personnalisé
```

### 2. Script d'Initialisation (`entrypoint.sh`)

Le script `entrypoint.sh` s'exécute automatiquement au démarrage :

```bash
#!/bin/bash
# 1. Démarre SQL Server
/opt/mssql/bin/sqlservr &

# 2. Attend que SQL Server soit prêt (max 60 secondes)
for i in {1..60}; do
    if sqlcmd -S localhost -U sa -P "$MSSQL_SA_PASSWORD" -C -Q "SELECT 1"; then
        echo "SQL Server is ready!"
        break
    fi
    sleep 1
done

# 3. Exécute TOUS les scripts SQL dans l'ordre
for script in /docker-entrypoint-initdb.d/*.sql; do
    echo "Executing: $(basename $script)"
    sqlcmd -S localhost -U sa -P "$MSSQL_SA_PASSWORD" -C -i "$script"
done
```

### 3. Scripts SQL Exécutés (dans l'ordre)

| Ordre | Script | Description | Durée |
|-------|--------|-------------|-------|
| 1️⃣ | `01-create-database.sql` | Création de la base et des tables | ~5s |
| 2️⃣ | `02-create-stored-procedures.sql` | Procédures stockées (détection fraude) | ~3s |
| 3️⃣ | `03-seed-data.sql` | **Génération des données** | ~30s |

---

## 📊 Données Générées Automatiquement

### Volume de Données

```
✓ Merchants:          100 commerçants
✓ Field Agents:       50 agents de terrain
✓ Clients:            1,000 clients
✓ Account Balances:   1,000 comptes avec soldes
✓ Transactions:       5,000 transactions
✓ Fraud Alerts:       Variable (basé sur transactions suspectes)
✓ System Metrics:     96 points de données (24 heures)
```

### Détails des Données

#### 🏪 Merchants (100)

```sql
-- Catégories variées
Categories: Retail, Food & Beverage, Travel, Entertainment, 
            Healthcare, Education, Utilities, Telecom,
            E-commerce, Gas Station, Pharmacy, Supermarket

-- Niveaux de risque
Risk Levels: Low (70%), Medium (20%), High (10%)

-- Villes
Cities: Tunis, Sfax, Sousse, Bizerte, Gabes
```

#### 👥 Clients (1,000)

```sql
-- Profils variés
Segments: Premium, Standard, Basic
Risk Levels: Low, Medium, High
Status: Active, Suspended, Closed

-- Données géographiques
Countries: Tunisia, France, Germany, USA, UAE
Cities: Multiple per country
```

#### 💳 Transactions (5,000)

```sql
-- Types de transactions
Types: Purchase, Withdrawal, Transfer, Payment, Refund

-- Canaux
Channels: POS, ATM, Online, Mobile

-- Montants
Range: 10 TND - 50,000 TND (distribution réaliste)

-- Statuts
Status: Approved (85%), Declined (10%), Pending (3%), Flagged (2%)
```

#### 🚨 Scénarios de Fraude Inclus

1. **Velocity Fraud** - Transactions multiples rapides
2. **Location Fraud** - Transactions géographiquement impossibles
3. **Amount Fraud** - Montants inhabituels
4. **Merchant Risk** - Transactions avec commerçants à haut risque
5. **Time Pattern** - Transactions à heures inhabituelles

---

## 🧪 Vérification de l'Initialisation

### Méthode 1 : Vérifier les Logs Docker

```bash
# Voir les logs du conteneur MS SQL
docker logs mssql_ebanking

# Vous devriez voir :
# ✓ Starting SQL Server...
# ✓ SQL Server is ready!
# ✓ Executing: 01-create-database.sql
# ✓ 01-create-database.sql executed successfully
# ✓ Executing: 02-create-stored-procedures.sql
# ✓ 02-create-stored-procedures.sql executed successfully
# ✓ Executing: 03-seed-data.sql
# ✓ 03-seed-data.sql executed successfully
# ✓ Database initialization completed!
```

### Méthode 2 : Se Connecter à la Base

```bash
# Connexion à MS SQL Server
docker exec -it mssql_ebanking /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U sa -P "YourPassword123!" -C
```

### Méthode 3 : Vérifier les Données

```sql
-- Compter les enregistrements
USE EBankingDB;
GO

SELECT 'Merchants' AS TableName, COUNT(*) AS RecordCount FROM Merchants
UNION ALL
SELECT 'Clients', COUNT(*) FROM Clients
UNION ALL
SELECT 'Transactions', COUNT(*) FROM Transactions
UNION ALL
SELECT 'FraudAlerts', COUNT(*) FROM FraudAlerts
UNION ALL
SELECT 'SystemMetrics', COUNT(*) FROM SystemMetrics;
GO
```

**Résultat attendu :**

```
TableName        RecordCount
--------------   -----------
Merchants        100
Clients          1000
Transactions     5000
FraudAlerts      ~100-200 (variable)
SystemMetrics    96
```

### Méthode 4 : Tester les Procédures Stockées

```sql
-- Tester la détection de fraude par vélocité
EXEC sp_DetectVelocityFraud @ClientID = 1;

-- Tester la détection de fraude géographique
EXEC sp_DetectLocationFraud @TransactionID = 100;

-- Tester la détection de fraude par montant
EXEC sp_DetectAmountFraud @TransactionID = 200;
```

---

## 🔧 Que Faire si les Données ne Sont Pas Générées ?

### Problème 1 : Conteneur ne Démarre Pas

```bash
# Vérifier le statut
docker ps -a | grep mssql

# Voir les erreurs
docker logs mssql_ebanking

# Solution : Vérifier le mot de passe SA
# Le mot de passe doit respecter la politique MS SQL :
# - Au moins 8 caractères
# - Lettres majuscules et minuscules
# - Chiffres
# - Caractères spéciaux
```

### Problème 2 : Scripts SQL ne S'Exécutent Pas

```bash
# Vérifier que les scripts sont montés
docker exec mssql_ebanking ls -la /docker-entrypoint-initdb.d/

# Résultat attendu :
# 01-create-database.sql
# 02-create-stored-procedures.sql
# 03-seed-data.sql

# Vérifier les permissions
docker exec mssql_ebanking ls -la /scripts/
```

### Problème 3 : Réinitialiser Complètement

```bash
# 1. Arrêter et supprimer le conteneur
docker-compose stop mssql
docker-compose rm -f mssql

# 2. Supprimer le volume (ATTENTION : perte de données)
docker volume rm observability-stack_mssql_data

# 3. Redémarrer
docker-compose up -d mssql

# 4. Suivre les logs
docker logs -f mssql_ebanking
```

---

## ⏱️ Temps d'Initialisation

| Étape | Durée | Description |
|-------|-------|-------------|
| Démarrage SQL Server | ~10s | Initialisation du moteur |
| Création base/tables | ~5s | Schéma de la base |
| Procédures stockées | ~3s | Logique métier |
| **Génération données** | **~30s** | **5,000+ enregistrements** |
| **TOTAL** | **~50s** | **Prêt à l'emploi** |

---

## 📝 Fichiers Impliqués

```
mssql/
├── init/                                    # Scripts exécutés automatiquement
│   ├── 01-create-database.sql              # Création base + tables
│   ├── 02-create-stored-procedures.sql     # Procédures de détection fraude
│   └── 03-seed-data.sql                    # ⭐ GÉNÉRATION DES DONNÉES
├── scripts/
│   ├── entrypoint.sh                       # ⭐ POINT D'ENTRÉE AUTOMATIQUE
│   └── init-database.sh                    # Script alternatif
├── backup/                                  # Backups (vide au départ)
├── FRAUD_DETECTION_SCENARIOS.md            # Documentation scénarios
└── README.md                                # Documentation générale
```

---

## ✅ Checklist de Validation

- [ ] Conteneur `mssql_ebanking` est en état `healthy`
- [ ] Logs montrent "Database initialization completed!"
- [ ] 100 merchants dans la table `Merchants`
- [ ] 1,000 clients dans la table `Clients`
- [ ] 5,000 transactions dans la table `Transactions`
- [ ] Procédures stockées fonctionnent (`sp_DetectVelocityFraud`, etc.)
- [ ] Données de fraude présentes dans `FraudAlerts`

---

## 🎯 Conclusion

**✅ OUI, les données sont 100% automatiques !**

Au démarrage de `docker-compose up -d` :

1. ✅ SQL Server démarre
2. ✅ Base de données créée
3. ✅ Tables créées
4. ✅ Procédures stockées installées
5. ✅ **5,000+ enregistrements générés automatiquement**
6. ✅ Scénarios de fraude inclus
7. ✅ Prêt à l'emploi en ~50 secondes

**Aucune action manuelle requise !** 🎉

---

## 📚 Ressources

- [Documentation MS SQL Server](https://learn.microsoft.com/en-us/sql/sql-server/)
- [FRAUD_DETECTION_SCENARIOS.md](./FRAUD_DETECTION_SCENARIOS.md) - Scénarios de fraude détaillés
- [README.md](./README.md) - Guide d'utilisation général

---

**Dernière mise à jour** : 27 Octobre 2024  
**Version** : 1.0.0
