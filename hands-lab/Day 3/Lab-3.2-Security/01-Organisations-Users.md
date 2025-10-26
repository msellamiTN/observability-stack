# 👥 Organisations et User Management Grafana

## 📋 Objectifs

À la fin de ce module, vous serez capable de :

- ✅ Créer et gérer des organisations (multi-tenant)
- ✅ Comprendre les concepts de séparation des environnements
- ✅ Créer, éditer et supprimer des utilisateurs
- ✅ Configurer les permissions RBAC (Role-Based Access Control)
- ✅ Gérer les rôles par organisation et par dashboard
- ✅ Auditer les accès et sessions utilisateurs

---

## 🏢 Partie 1: Organisations (45min)

### Qu'est-ce qu'une Organisation ?

Une **organisation** dans Grafana est une **entité isolée** qui possède :
- Ses propres dashboards
- Ses propres datasources
- Ses propres utilisateurs et équipes
- Ses propres alertes
- Ses propres préférences

**Use Cases** :
- 🏢 **Multi-départements** : IT, Finance, RH
- 🌍 **Multi-régions** : EU, US, ASIA
- 👥 **Multi-clients** : Customer A, Customer B
- 🔧 **Multi-environnements** : Production, Staging, Development

---

### Créer une Organisation (UI)

#### Étape 1: Accéder au Server Admin

**Prérequis** : Être Server Admin (rôle global)

```
Menu (☰) → Server Admin → Organizations
```

#### Étape 2: Créer une Nouvelle Organisation

```
Button: + New Org
Name: Production Environment
Submit
```

**Résultat** : Organisation créée avec ID unique

---

### Créer une Organisation (API)

```bash
# Créer organisation "Production"
curl -X POST http://admin:GrafanaSecure123!Change@Me@localhost:3000/api/orgs \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Production Environment"
  }'

# Réponse
{
  "message": "Organization created",
  "orgId": 2
}
```

```bash
# Lister toutes les organisations
curl http://admin:GrafanaSecure123!Change@Me@localhost:3000/api/orgs

# Réponse
[
  {
    "id": 1,
    "name": "Main Org."
  },
  {
    "id": 2,
    "name": "Production Environment"
  }
]
```

```bash
# Obtenir détails d'une organisation
curl http://admin:GrafanaSecure123!Change@Me@localhost:3000/api/orgs/2

# Réponse
{
  "id": 2,
  "name": "Production Environment",
  "address": {
    "address1": "",
    "address2": "",
    "city": "",
    "zipCode": "",
    "state": "",
    "country": ""
  }
}
```

---

### Exercice 1: Créer 3 Organisations

**Objectif** : Structurer les environnements

```bash
# 1. Organisation Production
curl -X POST http://admin:password@localhost:3000/api/orgs \
  -H "Content-Type: application/json" \
  -d '{"name": "Production"}'

# 2. Organisation Development  
curl -X POST http://admin:password@localhost:3000/api/orgs \
  -H "Content-Type: application/json" \
  -d '{"name": "Development"}'

# 3. Organisation Support
curl -X POST http://admin:password@localhost:3000/api/orgs \
  -H "Content-Type: application/json" \
  -d '{"name": "Support"}'
```

**Vérification** :
```
Server Admin → Organizations
→ Voir 4 orgs: Main Org, Production, Development, Support
```

---

### Configurer une Organisation

#### Préférences Organisation

```
Server Admin → Organizations → [Select Org] → Settings
```

**Paramètres Configurables** :

| Paramètre | Description | Exemple |
|-----------|-------------|---------|
| **Name** | Nom organisation | "Production Environment" |
| **Home Dashboard** | Dashboard par défaut | "Production Overview" |
| **Timezone** | Fuseau horaire | "Europe/Paris" |
| **Theme** | Thème interface | "Dark" |

#### Quotas Organisation

Limiter les ressources par organisation :

```bash
# Définir quotas via API
curl -X PUT http://admin:password@localhost:3000/api/orgs/2/quotas/dashboard \
  -H "Content-Type: application/json" \
  -d '{"limit": 50}'

curl -X PUT http://admin:password@localhost:3000/api/orgs/2/quotas/data_source \
  -H "Content-Type: application/json" \
  -d '{"limit": 10}'

curl -X PUT http://admin:password@localhost:3000/api/orgs/2/quotas/user \
  -H "Content-Type: application/json" \
  -d '{"limit": 25}'
```

**Types de Quotas** :
- `dashboard`: Nombre maximum de dashboards
- `data_source`: Nombre maximum de datasources
- `user`: Nombre maximum d'utilisateurs
- `alert_rule`: Nombre maximum d'alertes
- `api_key`: Nombre maximum de clés API

---

## 👤 Partie 2: User Management (1h)

### Types d'Utilisateurs Grafana

**1. Server Admin (Global)**
- Gère toutes les organisations
- Crée des organisations
- Gère tous les utilisateurs
- Accès complet au système

**2. Org Admin (Par Organisation)**
- Admin d'une organisation spécifique
- Gère users de son org
- Gère datasources de son org
- Pas d'accès aux autres orgs

**3. Users Réguliers**
- Rôles: Viewer, Editor, Admin (scope org)
- Accès limité à leurs orgs

---

### Créer un Utilisateur (UI)

#### Via Server Admin (Global)

```
Server Admin → Users → New user

Form:
  Name: John Doe
  Email: john.doe@company.com
  Username: jdoe
  Password: SecurePass123!
  
  → Create
```

**Note** : L'utilisateur est créé globalement mais n'appartient à aucune org initialement.

---

### Créer un Utilisateur (API)

```bash
# Créer utilisateur global
curl -X POST http://admin:password@localhost:3000/api/admin/users \
  -H "Content-Type: application/json" \
  -d '{
    "name": "John Doe",
    "email": "john.doe@company.com",
    "login": "jdoe",
    "password": "SecurePass123!",
    "OrgId": 1
  }'

# Réponse
{
  "id": 5,
  "message": "User created",
  "name": "john.doe@company.com"
}
```

---

### Ajouter un Utilisateur à une Organisation

#### Via UI

```
Server Admin → Organizations → [Select Org] → Users → Add user

Select user: john.doe@company.com
Role: Editor
→ Add
```

#### Via API

```bash
# Ajouter user à org avec rôle Editor
curl -X POST http://admin:password@localhost:3000/api/orgs/2/users \
  -H "Content-Type: application/json" \
  -d '{
    "loginOrEmail": "john.doe@company.com",
    "role": "Editor"
  }'

# Réponse
{
  "message": "User added to organization",
  "userId": 5,
  "orgId": 2
}
```

---

### Exercice 2: Créer la Structure Utilisateurs

**Objectif** : Créer des utilisateurs pour les 3 organisations

#### Organisation "Production"

```bash
# Admin Production
curl -X POST http://admin:password@localhost:3000/api/admin/users \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Admin Production",
    "email": "admin.prod@company.com",
    "login": "admin_prod",
    "password": "AdminProd123!"
  }'

# Ajouter à org Production avec rôle Admin
curl -X POST http://admin:password@localhost:3000/api/orgs/2/users \
  -H "Content-Type: application/json" \
  -d '{"loginOrEmail": "admin.prod@company.com", "role": "Admin"}'

# Editor Production
curl -X POST http://admin:password@localhost:3000/api/admin/users \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Dev Production",
    "email": "dev.prod@company.com",
    "login": "dev_prod",
    "password": "DevProd123!"
  }'

curl -X POST http://admin:password@localhost:3000/api/orgs/2/users \
  -H "Content-Type: application/json" \
  -d '{"loginOrEmail": "dev.prod@company.com", "role": "Editor"}'

# Viewer Production (Support)
curl -X POST http://admin:password@localhost:3000/api/admin/users \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Support Production",
    "email": "support.prod@company.com",
    "login": "support_prod",
    "password": "SupportProd123!"
  }'

curl -X POST http://admin:password@localhost:3000/api/orgs/2/users \
  -H "Content-Type: application/json" \
  -d '{"loginOrEmail": "support.prod@company.com", "role": "Viewer"}'
```

#### Organisation "Development"

```bash
# Admin Development
curl -X POST http://admin:password@localhost:3000/api/admin/users \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Admin Dev",
    "email": "admin.dev@company.com",
    "login": "admin_dev",
    "password": "AdminDev123!"
  }'

curl -X POST http://admin:password@localhost:3000/api/orgs/3/users \
  -H "Content-Type: application/json" \
  -d '{"loginOrEmail": "admin.dev@company.com", "role": "Admin"}'

# Developer Team (Editor)
curl -X POST http://admin:password@localhost:3000/api/admin/users \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Dev Team",
    "email": "dev.team@company.com",
    "login": "dev_team",
    "password": "DevTeam123!"
  }'

curl -X POST http://admin:password@localhost:3000/api/orgs/3/users \
  -H "Content-Type: application/json" \
  -d '{"loginOrEmail": "dev.team@company.com", "role": "Editor"}'
```

**Résultat Attendu** :

| Organisation | Admin | Editor | Viewer |
|--------------|-------|--------|--------|
| **Production** | admin_prod | dev_prod | support_prod |
| **Development** | admin_dev | dev_team | - |
| **Support** | - | - | - |

---

### Gérer les Utilisateurs Existants

#### Lister les Utilisateurs d'une Org

```bash
# Lister users de l'org 2 (Production)
curl http://admin:password@localhost:3000/api/orgs/2/users

# Réponse
[
  {
    "orgId": 2,
    "userId": 6,
    "email": "admin.prod@company.com",
    "login": "admin_prod",
    "role": "Admin",
    "lastSeenAt": "2024-01-15T10:30:00Z",
    "lastSeenAtAge": "2h"
  },
  {
    "orgId": 2,
    "userId": 7,
    "email": "dev.prod@company.com",
    "login": "dev_prod",
    "role": "Editor",
    "lastSeenAt": "2024-01-15T12:00:00Z",
    "lastSeenAtAge": "30m"
  }
]
```

#### Modifier le Rôle d'un Utilisateur

```bash
# Changer dev_prod de Editor à Admin
curl -X PATCH http://admin:password@localhost:3000/api/orgs/2/users/7 \
  -H "Content-Type: application/json" \
  -d '{"role": "Admin"}'

# Réponse
{
  "message": "Organization user updated"
}
```

#### Retirer un Utilisateur d'une Org

```bash
# Retirer user ID 7 de l'org 2
curl -X DELETE http://admin:password@localhost:3000/api/orgs/2/users/7

# Réponse
{
  "message": "User removed from organization"
}
```

**Note** : L'utilisateur reste dans le système mais n'a plus accès à cette org.

#### Supprimer un Utilisateur Globalement

```bash
# Supprimer user ID 7 complètement
curl -X DELETE http://admin:password@localhost:3000/api/admin/users/7

# Réponse
{
  "message": "User deleted"
}
```

**Impact** : Retiré de toutes les organisations et supprimé du système.

---

## 🔐 Partie 3: Permissions et RBAC (1h)

### Les 3 Rôles Principaux

| Rôle | Dashboards | Datasources | Users | Alertes | Settings |
|------|------------|-------------|-------|---------|----------|
| **Viewer** | 👁️ View | ❌ None | ❌ None | 👁️ View | ❌ None |
| **Editor** | ✏️ Create/Edit | 👁️ View | ❌ None | ✏️ Create/Edit | ❌ None |
| **Admin** | ✏️ Full | ✏️ Full | ✏️ Full | ✏️ Full | ✏️ Full |

---

### Permissions par Dashboard

Les dashboards peuvent avoir des **permissions granulaires** indépendantes des rôles org.

#### Modèle de Permissions

```yaml
Dashboard Permissions:
  - Role-based:
      - Viewer: View
      - Editor: View, Edit
      - Admin: View, Edit, Admin
  
  - User-based:
      - john.doe@company.com: Admin
      - jane.smith@company.com: Edit
  
  - Team-based:
      - DevOps Team: Edit
      - Support Team: View
```

#### Configurer les Permissions (UI)

```
Dashboard → Settings (⚙️) → Permissions

Current Permissions:
  - Role Viewer: Can View
  - Role Editor: Can Edit
  - Role Admin: Can Admin

→ Add Permission
  Type: User
  Select: john.doe@company.com
  Permission: Admin
  
→ Save
```

#### Configurer les Permissions (API)

```bash
# Obtenir permissions actuelles
curl http://admin:password@localhost:3000/api/dashboards/uid/dashboard-uid/permissions

# Définir nouvelles permissions
curl -X POST http://admin:password@localhost:3000/api/dashboards/uid/dashboard-uid/permissions \
  -H "Content-Type: application/json" \
  -d '{
    "items": [
      {
        "role": "Viewer",
        "permission": 1
      },
      {
        "role": "Editor",
        "permission": 2
      },
      {
        "userId": 5,
        "permission": 4
      }
    ]
  }'
```

**Niveaux de Permission** :
- `1` = View
- `2` = Edit
- `4` = Admin (Full control)

---

### Permissions par Folder

Les **folders** héritent et appliquent des permissions à tous leurs dashboards.

#### Créer un Folder avec Permissions

```bash
# Créer folder
curl -X POST http://admin:password@localhost:3000/api/folders \
  -H "Content-Type: application/json" \
  -d '{
    "uid": "prod-critical",
    "title": "Production Critical"
  }'

# Définir permissions folder
curl -X POST http://admin:password@localhost:3000/api/folders/prod-critical/permissions \
  -H "Content-Type: application/json" \
  -d '{
    "items": [
      {
        "role": "Admin",
        "permission": 4
      },
      {
        "role": "Editor",
        "permission": 1
      },
      {
        "role": "Viewer",
        "permission": 0
      }
    ]
  }'
```

**Résultat** :
- Admin: Full access
- Editor: View only (pas d'édition!)
- Viewer: No access

---

### Exercice 3: Configuration Permissions Multi-Niveaux

**Scénario** : Organisation Production avec 3 niveaux de criticité

#### Niveau 1: Critical Dashboards (Admin only)

```bash
# Créer folder
curl -X POST http://admin:password@localhost:3000/api/folders \
  -H "Content-Type: application/json" \
  -d '{
    "uid": "critical",
    "title": "Critical Production"
  }'

# Permissions: Admin only
curl -X POST http://admin:password@localhost:3000/api/folders/critical/permissions \
  -H "Content-Type: application/json" \
  -d '{
    "items": [
      {"role": "Admin", "permission": 4},
      {"role": "Editor", "permission": 0},
      {"role": "Viewer", "permission": 0}
    ]
  }'
```

#### Niveau 2: Standard Monitoring (Editor can edit)

```bash
# Créer folder
curl -X POST http://admin:password@localhost:3000/api/folders \
  -H "Content-Type: application/json" \
  -d '{
    "uid": "standard",
    "title": "Standard Monitoring"
  }'

# Permissions: Admin full, Editor edit, Viewer view
curl -X POST http://admin:password@localhost:3000/api/folders/standard/permissions \
  -H "Content-Type: application/json" \
  -d '{
    "items": [
      {"role": "Admin", "permission": 4},
      {"role": "Editor", "permission": 2},
      {"role": "Viewer", "permission": 1}
    ]
  }'
```

#### Niveau 3: Public Status (All can view)

```bash
# Créer folder
curl -X POST http://admin:password@localhost:3000/api/folders \
  -H "Content-Type: application/json" \
  -d '{
    "uid": "public",
    "title": "Public Status"
  }'

# Permissions: All view
curl -X POST http://admin:password@localhost:3000/api/folders/public/permissions \
  -H "Content-Type: application/json" \
  -d '{
    "items": [
      {"role": "Admin", "permission": 4},
      {"role": "Editor", "permission": 2},
      {"role": "Viewer", "permission": 1}
    ]
  }'
```

---

### Permissions Datasources

Les datasources peuvent être restreintes par rôle.

#### Configuration Datasource

```
Configuration → Data Sources → [Select DS] → Permissions

Access:
  ☑ Role Admin: Query & Settings
  ☑ Role Editor: Query only
  ☐ Role Viewer: No access
```

**Use Case** : Empêcher les Viewers d'utiliser certaines datasources sensibles.

---

## 📊 Partie 4: Audit et Monitoring (30min)

### View User Details

#### Via UI

```
Server Admin → Users → [Select User]

Informations affichées:
  - User ID
  - Name
  - Email
  - Login
  - Organizations (with roles)
  - Last seen
  - Sessions actives
  - Auth source (local, LDAP, OAuth)
```

#### Via API

```bash
# Obtenir détails utilisateur
curl http://admin:password@localhost:3000/api/users/5

# Réponse
{
  "id": 5,
  "email": "john.doe@company.com",
  "name": "John Doe",
  "login": "jdoe",
  "theme": "dark",
  "orgId": 2,
  "isGrafanaAdmin": false,
  "isDisabled": false,
  "isExternal": false,
  "authLabels": ["local"],
  "updatedAt": "2024-01-15T10:00:00Z",
  "createdAt": "2024-01-10T08:00:00Z",
  "lastSeenAt": "2024-01-15T12:30:00Z"
}
```

---

### Sessions Actives

```bash
# Lister les sessions d'un utilisateur
curl http://admin:password@localhost:3000/api/admin/users/5/auth-tokens

# Réponse
[
  {
    "id": 123,
    "isActive": true,
    "clientIp": "192.168.1.100",
    "browser": "Chrome",
    "browserVersion": "120.0",
    "os": "Windows",
    "osVersion": "11",
    "device": "Desktop",
    "createdAt": "2024-01-15T08:00:00Z",
    "seenAt": "2024-01-15T12:30:00Z"
  }
]
```

#### Révoquer une Session

```bash
# Révoquer session ID 123
curl -X DELETE http://admin:password@localhost:3000/api/admin/users/5/auth-tokens/123

# Réponse
{
  "message": "User auth token revoked"
}
```

---

### Audit Logs

Grafana enregistre les actions utilisateurs (si activé).

#### Activer l'Audit (grafana.ini)

```ini
[auditing]
enabled = true
log_dashboard_content = true
```

#### Consulter les Logs

```bash
# Via logs Grafana
docker compose logs grafana | grep audit

# Exemple d'entrée
{
  "timestamp": "2024-01-15T12:00:00Z",
  "user": "john.doe@company.com",
  "action": "dashboard-update",
  "dashboard": "production-overview",
  "org": "Production"
}
```

---

## 🎯 TP Pratique Complet (45min)

### Objectif
Créer une structure organisationnelle complète avec permissions granulaires.

### Tâche 1: Créer les Organisations (10min)

```bash
# Via script
cat > create-orgs.sh << 'EOF'
#!/bin/bash
BASE_URL="http://localhost:3000"
ADMIN_CREDS="admin:GrafanaSecure123!Change@Me"

# Créer organisations
curl -X POST "$BASE_URL/api/orgs" \
  -u "$ADMIN_CREDS" \
  -H "Content-Type: application/json" \
  -d '{"name": "Production"}'

curl -X POST "$BASE_URL/api/orgs" \
  -u "$ADMIN_CREDS" \
  -H "Content-Type: application/json" \
  -d '{"name": "Development"}'

curl -X POST "$BASE_URL/api/orgs" \
  -u "$ADMIN_CREDS" \
  -H "Content-Type: application/json" \
  -d '{"name": "Support"}'

echo "✅ Organizations created"
EOF

chmod +x create-orgs.sh
./create-orgs.sh
```

---

### Tâche 2: Créer les Utilisateurs (15min)

**Structure Requise** :

| User | Production | Development | Support |
|------|------------|-------------|---------|
| admin_prod | Admin | - | - |
| dev_prod | Editor | - | - |
| support_prod | Viewer | - | Viewer |
| admin_dev | - | Admin | - |
| dev_team | - | Editor | - |
| support_l1 | Viewer | - | Editor |
| support_l2 | Viewer | - | Admin |

Créer le script `create-users.sh` :

```bash
#!/bin/bash
BASE_URL="http://localhost:3000"
ADMIN_CREDS="admin:GrafanaSecure123!Change@Me"

# Function to create user
create_user() {
  local name=$1
  local email=$2
  local login=$3
  local password=$4
  
  curl -X POST "$BASE_URL/api/admin/users" \
    -u "$ADMIN_CREDS" \
    -H "Content-Type: application/json" \
    -d "{\"name\":\"$name\",\"email\":\"$email\",\"login\":\"$login\",\"password\":\"$password\"}"
}

# Function to add user to org
add_user_to_org() {
  local orgId=$1
  local email=$2
  local role=$3
  
  curl -X POST "$BASE_URL/api/orgs/$orgId/users" \
    -u "$ADMIN_CREDS" \
    -H "Content-Type: application/json" \
    -d "{\"loginOrEmail\":\"$email\",\"role\":\"$role\"}"
}

# Create users
create_user "Admin Production" "admin.prod@company.com" "admin_prod" "AdminProd123!"
create_user "Dev Production" "dev.prod@company.com" "dev_prod" "DevProd123!"
# ... (continuer pour tous les users)

# Add to organizations
add_user_to_org 2 "admin.prod@company.com" "Admin"  # Org 2 = Production
add_user_to_org 2 "dev.prod@company.com" "Editor"
# ... (continuer pour toutes les assignations)

echo "✅ Users created and assigned"
```

---

### Tâche 3: Configurer les Permissions (10min)

Créer 3 folders dans l'org Production avec permissions différenciées :

```bash
#!/bin/bash
BASE_URL="http://localhost:3000"
# Se connecter en tant que admin_prod

# Critical folder
curl -X POST "$BASE_URL/api/folders" \
  -u "admin_prod:AdminProd123!" \
  -H "Content-Type: application/json" \
  -d '{"uid":"critical","title":"Critical Production"}'

curl -X POST "$BASE_URL/api/folders/critical/permissions" \
  -u "admin_prod:AdminProd123!" \
  -H "Content-Type: application/json" \
  -d '{
    "items": [
      {"role":"Admin","permission":4},
      {"role":"Editor","permission":1},
      {"role":"Viewer","permission":0}
    ]
  }'

# ... (continuer pour standard et public folders)
```

---

### Tâche 4: Tests d'Accès (10min)

**Tests à Effectuer** :

1. **Connexion admin_prod** :
   - [ ] Accès org Production: ✅
   - [ ] Création dashboard dans Critical: ✅
   - [ ] Accès org Development: ❌
   - [ ] Switch org: Non visible

2. **Connexion dev_prod** :
   - [ ] Accès org Production: ✅
   - [ ] View dashboard Critical: ✅
   - [ ] Edit dashboard Critical: ❌
   - [ ] Edit dashboard Standard: ✅
   - [ ] Create datasource: ❌

3. **Connexion support_prod** :
   - [ ] View dashboard Standard: ✅
   - [ ] View dashboard Critical: ❌
   - [ ] Edit anything: ❌
   - [ ] Access settings: ❌

---

## ✅ Critères de Réussite

- [ ] 3 organisations créées (Production, Development, Support)
- [ ] 7 utilisateurs créés avec rôles appropriés
- [ ] Permissions par folder configurées
- [ ] Tests d'accès validés pour chaque profil
- [ ] Audit logs visibles
- [ ] Scripts d'automatisation fonctionnels

---

## 📚 Bonnes Pratiques

### Naming Conventions
- ✅ Organisations: PascalCase ("ProductionEnvironment")
- ✅ Users: Descriptifs avec domaine ("admin.prod@company.com")
- ✅ Folders: Lowercase avec tirets ("critical-production")

### Sécurité
- ✅ Principe du moindre privilège
- ✅ Rotation régulière des mots de passe
- ✅ Audit des accès activé
- ✅ Révocation des sessions inactives
- ✅ MFA activé pour admins (si disponible)

### Organisation
- ✅ Séparer prod/dev/staging
- ✅ Un admin par organisation minimum
- ✅ Documenter la structure des permissions
- ✅ Réviser régulièrement les accès

---

## 🐛 Troubleshooting

### Utilisateur ne voit pas son organisation

**Causes** :
1. Pas ajouté à l'org
2. Org pas définie comme "current"

**Solution** :
```bash
# Vérifier les orgs de l'utilisateur
curl http://admin:password@localhost:3000/api/users/5/orgs

# Switch org
curl -X POST http://jdoe:password@localhost:3000/api/user/using/2
```

---

### Permissions ne s'appliquent pas

**Causes** :
1. Cache Grafana
2. Permissions folder vs dashboard conflictuelles

**Solution** :
```bash
# Redémarrer Grafana
docker compose restart grafana

# Vérifier permissions héritées
curl http://admin:password@localhost:3000/api/dashboards/uid/dash-uid/permissions
```

---

## 🎓 Conclusion

Vous maîtrisez maintenant :
- ✅ La création et gestion d'organisations
- ✅ Le user management complet
- ✅ Les permissions RBAC granulaires
- ✅ L'audit des accès
- ✅ L'automatisation via API

**Prochaine étape** : Implémenter une authentification SSO (LDAP, OAuth, SAML) !
