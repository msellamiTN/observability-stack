# 🔄 Réinitialisation de la Base de Données MS SQL

## ⚠️ Problème Identifié et Corrigé

### Erreur Détectée

```
Cannot insert the value NULL into column 'ClientID', table 'EBankingDB.dbo.Transactions'
Must declare the table variable "@LastNames"
```

### Cause

Les variables de table `@FirstNames` et `@LastNames` étaient déclarées dans un bloc puis utilisées après un `GO`, ce qui les rendait inaccessibles.

### Solution Appliquée

✅ **Correction effectuée dans `03-seed-data.sql`** :
- Redéclaration des variables `@FirstNames` et `@LastNames` dans le bloc Clients
- Les données seront maintenant générées correctement

---

## 🔄 Procédure de Réinitialisation

### Option 1 : Réinitialisation Complète (Recommandé)

```bash
# 1. Arrêter le conteneur
sudo docker-compose stop mssql

# 2. Supprimer le conteneur
sudo docker-compose rm -f mssql

# 3. Supprimer le volume (ATTENTION : perte de données)
sudo docker volume rm observability-stack_mssql_data

# 4. Redémarrer avec les scripts corrigés
sudo docker-compose up -d mssql

# 5. Suivre les logs pour vérifier
sudo docker logs -f mssql_ebanking
```

### Option 2 : Réinitialisation Rapide (Sans Supprimer le Volume)

```bash
# 1. Se connecter à MS SQL
sudo docker exec -it mssql_ebanking /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U sa -P "YourPassword123!" -C

# 2. Supprimer et recréer la base
DROP DATABASE IF EXISTS EBankingDB;
GO
QUIT

# 3. Redémarrer le conteneur pour réexécuter les scripts
sudo docker-compose restart mssql

# 4. Vérifier les logs
sudo docker logs -f mssql_ebanking
```

### Option 3 : Exécution Manuelle des Scripts

```bash
# 1. Copier les scripts corrigés dans le conteneur
sudo docker cp ./mssql/init/03-seed-data.sql mssql_ebanking:/tmp/

# 2. Se connecter et exécuter
sudo docker exec -it mssql_ebanking /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U sa -P "YourPassword123!" -C \
  -i /tmp/03-seed-data.sql
```

---

## ✅ Vérification Après Réinitialisation

### 1. Vérifier les Logs

```bash
sudo docker logs mssql_ebanking | tail -30
```

**Résultat attendu** :
```
✓ 01-create-database.sql executed successfully
✓ 02-create-stored-procedures.sql executed successfully
✓ 03-seed-data.sql executed successfully
Database initialization completed!
```

**PAS d'erreurs** comme :
```
❌ Cannot insert the value NULL into column 'ClientID'
❌ Must declare the table variable "@LastNames"
```

### 2. Compter les Enregistrements

```bash
sudo docker exec -it mssql_ebanking /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U sa -P "YourPassword123!" -C -Q \
  "USE EBankingDB; 
   SELECT 'Merchants' AS TableName, COUNT(*) AS Count FROM Merchants
   UNION ALL SELECT 'FieldAgents', COUNT(*) FROM FieldAgents
   UNION ALL SELECT 'Clients', COUNT(*) FROM Clients
   UNION ALL SELECT 'Transactions', COUNT(*) FROM Transactions
   UNION ALL SELECT 'FraudAlerts', COUNT(*) FROM FraudAlerts;"
```

**Résultat attendu** :
```
TableName        Count
--------------   -----
Merchants        100
FieldAgents      50
Clients          1000
Transactions     5000      ← Doit être 5000, pas 0 !
FraudAlerts      ~100-200
```

### 3. Tester une Transaction

```bash
sudo docker exec -it mssql_ebanking /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U sa -P "YourPassword123!" -C -Q \
  "USE EBankingDB; SELECT TOP 5 TransactionID, ClientID, Amount, Status FROM Transactions;"
```

**Résultat attendu** :
```
TransactionID  ClientID  Amount    Status
-----------    --------  --------  ---------
1              45        234.50    Completed
2              123       89.00     Completed
3              67        1250.00   Completed
...
```

### 4. Tester les Procédures Stockées

```bash
sudo docker exec -it mssql_ebanking /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U sa -P "YourPassword123!" -C -Q \
  "USE EBankingDB; EXEC sp_DetectVelocityFraud @ClientID = 1;"
```

---

## 📊 Données Attendues Après Correction

| Table | Quantité | Description |
|-------|----------|-------------|
| **Merchants** | 100 | ✅ Commerçants |
| **FieldAgents** | 50 | ✅ Agents de terrain |
| **Clients** | 1,000 | ✅ Clients avec noms corrects |
| **AccountBalances** | 1,000 | ✅ Comptes avec soldes |
| **Transactions** | 5,000 | ✅ **CORRIGÉ** - Transactions complètes |
| **FraudAlerts** | ~100-200 | ✅ Alertes de fraude |
| **SystemMetrics** | 96 | ✅ Métriques système (24h) |

---

## 🐛 Troubleshooting

### Problème : "Permission denied" sur docker.sock

```bash
# Solution 1 : Ajouter l'utilisateur au groupe docker
sudo usermod -aG docker $USER
newgrp docker

# Solution 2 : Utiliser sudo
sudo docker logs mssql_ebanking
```

### Problème : Le conteneur ne démarre pas

```bash
# Vérifier les erreurs
sudo docker logs mssql_ebanking

# Vérifier le mot de passe SA
# Doit contenir : majuscules, minuscules, chiffres, caractères spéciaux
# Minimum 8 caractères
```

### Problème : Scripts SQL ne s'exécutent pas

```bash
# Vérifier que les scripts sont montés
sudo docker exec mssql_ebanking ls -la /docker-entrypoint-initdb.d/

# Vérifier les permissions
sudo chmod +x ./mssql/scripts/*.sh
```

---

## 📝 Checklist de Validation

- [ ] Conteneur `mssql_ebanking` est `healthy`
- [ ] Logs montrent "Database initialization completed!"
- [ ] **AUCUNE erreur** "Cannot insert NULL" ou "Must declare"
- [ ] 100 merchants créés
- [ ] 50 field agents créés
- [ ] 1,000 clients créés
- [ ] **5,000 transactions créées** (pas 0 !)
- [ ] Fraud alerts présentes
- [ ] Procédures stockées fonctionnent

---

## 🎯 Commande Rapide de Réinitialisation

```bash
# Tout en une commande
sudo docker-compose stop mssql && \
sudo docker-compose rm -f mssql && \
sudo docker volume rm observability-stack_mssql_data && \
sudo docker-compose up -d mssql && \
echo "Waiting for initialization..." && \
sleep 60 && \
sudo docker logs mssql_ebanking | tail -20
```

---

## ✅ Confirmation de Succès

Après réinitialisation, vous devriez voir :

```bash
$ sudo docker logs mssql_ebanking | grep -E "seeded|executed|completed"

Merchants seeded: 100
Field Agents seeded: 50
Clients seeded: 1000
Account Balances created for all clients
Sample Transactions seeded: 5000        ← Important !
Fraud Alerts created
System Metrics added for last 24 hours
✓ 01-create-database.sql executed successfully
✓ 02-create-stored-procedures.sql executed successfully
✓ 03-seed-data.sql executed successfully
Database initialization completed!
```

---

**Date de correction** : 27 Octobre 2024  
**Fichier corrigé** : `mssql/init/03-seed-data.sql`  
**Statut** : ✅ Prêt pour réinitialisation
