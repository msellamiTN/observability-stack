# 📅 Jour 3 : Optimisation et Production

**Durée totale** : 7 heures | **Niveau** : Avancé

---

## 🎯 Objectifs du Jour

À la fin de cette journée, vous serez capable de :

✅ Optimiser les performances de la stack d'observabilité  
✅ Sécuriser Grafana avec RBAC et authentification  
✅ Mettre en place des backups automatisés  
✅ Déployer en production avec haute disponibilité  
✅ Monitorer la stack elle-même  
✅ Gérer les incidents et la maintenance  

---

## 📚 Liste des Labs

### ⚡ Lab 3.1 : Performance et Optimisation (2h)
**Type** : Pratique  
**Fichier** : [Lab-3.1-Performance](./Lab-3.1-Performance/)

**Contenu** :
- Optimisation des requêtes (Flux, PromQL, SQL)
- Gestion du cache Grafana
- Downsampling et agrégation
- Tuning des datasources
- Monitoring des performances

**Prérequis** :
- Jours 1 et 2 complétés
- Dashboards créés avec des requêtes

---

### 🔐 Lab 3.2 : Sécurité et RBAC (1h30)
**Type** : Pratique  
**Fichier** : [Lab-3.2-Security](./Lab-3.2-Security/)

**Contenu** :
- Gestion des utilisateurs et équipes
- Permissions et rôles (RBAC)
- Authentification (LDAP, OAuth, SAML)
- Sécurisation des datasources
- Audit et logs de sécurité

**Prérequis** :
- Grafana opérationnel
- Compréhension des besoins organisationnels

---

### 📦 Lab 3.3 : Backup et Disaster Recovery (1h30)
**Type** : Pratique  
**Fichier** : [Lab-3.3-Backup](./Lab-3.3-Backup/)

**Contenu** :
- Sauvegarde des dashboards et alertes
- Export/Import de configuration
- Backup des volumes Docker
- Plan de reprise d'activité (DRP)
- Tests de restauration

**Prérequis** :
- Dashboards et alertes configurés
- Accès aux volumes Docker

---

### 🚀 Lab 3.4 : Déploiement en Production (2h)
**Type** : Pratique  
**Fichier** : [Lab-3.4-Production](./Lab-3.4-Production/)

**Contenu** :
- Configuration production-ready
- SSL/TLS avec reverse proxy (Nginx)
- Haute disponibilité (HA)
- Scalabilité horizontale
- Monitoring de la stack

**Prérequis** :
- Compréhension complète de la stack
- Tous les labs précédents complétés

---

## ⏱️ Planning Recommandé

| Horaire | Activité | Durée |
|---------|----------|-------|
| 09:00 - 11:00 | Lab 3.1 : Performance | 2h |
| 11:00 - 11:15 | ☕ Pause | 15min |
| 11:15 - 12:45 | Lab 3.2 : Sécurité | 1h30 |
| 12:45 - 14:00 | 🍽️ Déjeuner | 1h15 |
| 14:00 - 15:30 | Lab 3.3 : Backup | 1h30 |
| 15:30 - 15:45 | ☕ Pause | 15min |
| 15:45 - 17:45 | Lab 3.4 : Production | 2h |
| 17:45 - 18:00 | 🎓 Conclusion et Certification | 15min |

---

## 🛠️ Prérequis

### Connaissances
- ✅ Jours 1 et 2 complétés avec succès
- ✅ Maîtrise des datasources et dashboards
- ✅ Compréhension de l'observabilité complète
- ✅ Notions de sécurité et réseau

### Outils Supplémentaires
- **Nginx** (pour le reverse proxy)
- **OpenSSL** (pour les certificats SSL)
- **Scripts de backup** (fournis)

---

## 📊 Métriques de Performance

### Objectifs de Performance

| Métrique | Objectif | Critique |
|----------|----------|----------|
| **Dashboard Load Time** | < 2s | < 5s |
| **Query Response Time** | < 1s | < 3s |
| **Grafana CPU Usage** | < 50% | < 80% |
| **Grafana Memory** | < 2GB | < 4GB |
| **Prometheus Scrape Duration** | < 100ms | < 500ms |
| **InfluxDB Write Latency** | < 10ms | < 50ms |

---

## 🔐 Checklist Sécurité

### Configuration Minimale

- [ ] Mot de passe admin changé (complexe)
- [ ] Inscription anonyme désactivée
- [ ] HTTPS activé (production)
- [ ] Authentification 2FA activée
- [ ] Permissions RBAC configurées
- [ ] Datasources avec credentials sécurisés
- [ ] Logs d'audit activés
- [ ] Firewall configuré
- [ ] Certificats SSL valides
- [ ] Secrets dans variables d'environnement

---

## 💾 Stratégie de Backup

### Éléments à Sauvegarder

```
📦 Backup Complet
├── 📊 Dashboards (JSON)
├── 🔔 Alert Rules (YAML)
├── 🔌 Datasources (YAML)
├── 👥 Users & Teams (DB)
├── 🗄️ Grafana Database (SQLite/MySQL/PostgreSQL)
├── 📈 Prometheus Data (TSDB)
├── 🗄️ InfluxDB Data (Buckets)
├── 💾 MS SQL Data (Databases)
└── ⚙️ Configuration Files (.env, grafana.ini, etc.)
```

### Fréquence Recommandée

| Élément | Fréquence | Rétention |
|---------|-----------|-----------|
| **Dashboards** | Quotidien | 30 jours |
| **Alertes** | Quotidien | 30 jours |
| **Grafana DB** | Quotidien | 7 jours |
| **Prometheus** | Hebdomadaire | 4 semaines |
| **InfluxDB** | Quotidien | 14 jours |
| **MS SQL** | Quotidien | 30 jours |
| **Config Files** | À chaque changement | Illimité (Git) |

---

## 🚀 Architecture Production

### Stack Haute Disponibilité

```
┌─────────────────────────────────────────────────────────────┐
│                    PRODUCTION ARCHITECTURE                   │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  🌐 INTERNET                                                 │
│      ↓                                                        │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  Load Balancer (HAProxy / Nginx)                     │   │
│  │  - SSL Termination                                    │   │
│  │  - Rate Limiting                                      │   │
│  └──────────────────────────────────────────────────────┘   │
│      ↓                                                        │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  Grafana Cluster (2+ instances)                      │   │
│  │  ├─ grafana-1 (Active)                               │   │
│  │  └─ grafana-2 (Active)                               │   │
│  └──────────────────────────────────────────────────────┘   │
│      ↓                                                        │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  PostgreSQL (Primary + Replica)                      │   │
│  │  - Shared Grafana Database                           │   │
│  └──────────────────────────────────────────────────────┘   │
│      ↓                                                        │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  Data Sources (HA)                                    │   │
│  │  ├─ Prometheus (Federated / Thanos)                  │   │
│  │  ├─ Loki (Distributed)                               │   │
│  │  ├─ Tempo (Distributed)                              │   │
│  │  └─ InfluxDB (Clustered)                             │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

---

## ✅ Checklist de Fin de Formation

À la fin du Jour 3, vous devriez avoir :

### Compétences Techniques
- [ ] Maîtrise complète de Grafana
- [ ] Configuration de toutes les datasources
- [ ] Création de dashboards avancés
- [ ] Configuration d'alertes multi-canaux
- [ ] Implémentation de l'observabilité complète
- [ ] Optimisation des performances
- [ ] Sécurisation de la stack
- [ ] Mise en place de backups
- [ ] Déploiement production-ready

### Livrables
- [ ] Stack complète opérationnelle
- [ ] Dashboards de monitoring
- [ ] Alertes configurées et testées
- [ ] Documentation personnalisée
- [ ] Scripts de backup automatisés
- [ ] Configuration production
- [ ] Plan de disaster recovery

---

## 🎓 Certification et Évaluation

### Projet Final (Optionnel)

Créez une stack d'observabilité complète pour un cas d'usage réel :

1. **Architecture** : Diagramme de la solution
2. **Datasources** : Configuration de 3+ sources
3. **Dashboards** : 5+ dashboards avec variables
4. **Alerting** : 10+ règles d'alerte
5. **Documentation** : Guide d'utilisation
6. **Sécurité** : RBAC et authentification
7. **Backup** : Stratégie et scripts
8. **Production** : Configuration HA

### Critères d'Évaluation

| Critère | Points | Description |
|---------|--------|-------------|
| **Fonctionnalité** | 30% | La stack fonctionne correctement |
| **Qualité** | 25% | Code propre, bonnes pratiques |
| **Sécurité** | 20% | Configuration sécurisée |
| **Documentation** | 15% | Documentation complète |
| **Innovation** | 10% | Solutions créatives |

---

## 💡 Bonnes Pratiques Production

### Configuration
1. **Utilisez PostgreSQL** au lieu de SQLite
2. **Activez HTTPS** partout
3. **Configurez des backups** automatisés
4. **Monitoring de la stack** elle-même
5. **Logs centralisés** pour audit

### Performance
1. **Limitez les requêtes** lourdes
2. **Utilisez le cache** intelligemment
3. **Agrégez les anciennes** données
4. **Optimisez les dashboards** (max 20 panels)
5. **Downsampling** pour les métriques anciennes

### Sécurité
1. **Principe du moindre privilège**
2. **Rotation des secrets** régulière
3. **Audit des accès**
4. **Mise à jour** régulière
5. **Segmentation réseau**

---

## 🐛 Troubleshooting Production

### Performance Dégradée

```bash
# Vérifier les ressources
docker stats

# Analyser les requêtes lentes
# Dans Grafana → Configuration → Stats

# Vérifier les logs
docker compose logs --tail=100 grafana

# Redémarrer si nécessaire
docker compose restart grafana
```

### Problèmes de Haute Disponibilité

```bash
# Vérifier la synchronisation DB
docker compose exec postgres psql -U grafana -c "SELECT * FROM pg_stat_replication;"

# Vérifier le load balancer
curl -I https://your-domain.com

# Tester le failover
docker compose stop grafana-1
curl https://your-domain.com  # Devrait fonctionner via grafana-2
```

---

## 📚 Ressources Avancées

### Documentation
- [Grafana Enterprise](https://grafana.com/docs/grafana/latest/enterprise/)
- [High Availability Setup](https://grafana.com/docs/grafana/latest/setup-grafana/set-up-for-high-availability/)
- [Security Best Practices](https://grafana.com/docs/grafana/latest/setup-grafana/configure-security/)
- [Performance Tuning](https://grafana.com/docs/grafana/latest/administration/performance/)

### Outils
- [Grafana Backup Tool](https://github.com/ysde/grafana-backup-tool)
- [Terraform Grafana Provider](https://registry.terraform.io/providers/grafana/grafana/latest/docs)
- [Ansible Grafana Role](https://github.com/cloudalchemy/ansible-grafana)

---

## 🎯 Prochaines Étapes

### Après la Formation

1. **Pratiquez** : Déployez sur vos propres projets
2. **Explorez** : Testez les plugins Grafana
3. **Partagez** : Contribuez à la communauté
4. **Certifiez-vous** : [Grafana Certification](https://grafana.com/training/)
5. **Restez à jour** : Suivez les releases Grafana

### Communauté

- [Grafana Community Forums](https://community.grafana.com/)
- [Grafana Slack](https://grafana.slack.com/)
- [GitHub Grafana](https://github.com/grafana/grafana)
- [Grafana Blog](https://grafana.com/blog/)

---

## 🎉 Félicitations !

**Vous avez terminé la formation complète sur la stack d'observabilité Grafana !**

Vous êtes maintenant capable de :
- ✅ Déployer et gérer une stack d'observabilité complète
- ✅ Monitorer des applications en production
- ✅ Créer des dashboards et alertes avancés
- ✅ Optimiser et sécuriser votre infrastructure
- ✅ Gérer des incidents avec confiance

**🚀 Bonne chance dans vos projets d'observabilité !**

---

**📧 Questions ?** Consultez la documentation ou rejoignez la communauté Grafana.
