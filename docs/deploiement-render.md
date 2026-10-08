# Déployer HARMONY : base Supabase + API Render

Ce guide s'adresse à la personne qui administre les comptes Supabase, Render et GitHub du projet. Comptez une vingtaine de minutes la première fois.

| Élément | Hébergeur | Plan |
|---|---|---|
| Base PostgreSQL | Supabase, région Central EU (Frankfurt) | Gratuit |
| API Laravel (conteneur Docker) | Render, région Frankfurt | Gratuit |
| Ping quotidien de l'API | GitHub Actions | Gratuit |

Les deux hébergeurs sont dans la même région, la plus proche de Lomé, pour limiter la latence entre l'API et la base.

## 1. Supabase : créer la base

1. Créer un projet nommé `harmony`, région **Central EU (Frankfurt)**.
2. Générer un **mot de passe de base** fort et le ranger dans un gestionnaire de mots de passe. Il ne doit jamais être envoyé en clair dans une messagerie ni commité.
3. **Désactiver la Data API** : *Project Settings → Data API*, puis désactiver l'option. HARMONY passe uniquement par son API Laravel. Laissée active, la Data API pourrait exposer les tables publiquement avec la clé `anon`.
4. **Activer l'extension `btree_gist`** : *Database → Extensions*, rechercher `btree_gist`, puis l'activer. Elle permet à la base d'interdire les réservations qui se chevauchent.
5. Récupérer les paramètres de connexion : bouton **Connect**, onglet **Session pooler**. Noter :
   - **Host**, de la forme `aws-0-eu-central-1.pooler.supabase.com` ;
   - **User**, de la forme `postgres.<référence-du-projet>`.

   Il faut bien choisir le *Session pooler* : la connexion directe n'est disponible qu'en IPv6, ce que les serveurs gratuits de Render ne gèrent pas. Le port est `5432`, pas `6543`.

## 2. Générer la clé de l'application

Depuis le dossier `harmony-api` du dépôt, sur un poste où PHP est installé :

```
php artisan key:generate --show
```

Copier la valeur affichée, qui commence par `base64:`. C'est un secret, à ranger au même endroit que le mot de passe de la base.

## 3. Render : créer l'API

Un Blueprint `harmony` existe déjà ; sa première synchronisation avait échoué sur la base Render, qui n'est plus utilisée.

1. Ouvrir le Blueprint `harmony`, puis lancer **Manual sync** sur le dernier commit de `main`. Render ne crée plus que le service `harmony-api`.
2. Renseigner les valeurs demandées :

   | Variable | Valeur |
   |---|---|
   | `APP_KEY` | La clé générée à l'étape 2 |
   | `DB_HOST` | Le *Host* du Session pooler |
   | `DB_USERNAME` | Le *User* du Session pooler (`postgres.…`) |
   | `DB_PASSWORD` | Le mot de passe de la base |
   | `APP_URL` | Laisser vide pour l'instant |

3. Valider. Render construit l'image puis démarre l'API ; les tables sont créées automatiquement au démarrage.
4. Copier l'URL publique du service (`https://harmony-api-xxxx.onrender.com`), la saisir dans **harmony-api → Environment → `APP_URL`**, puis enregistrer. Render redéploie.

## 4. GitHub : activer le ping quotidien

Sur le dépôt `ADIBOLOGottlieb/Harmony` : *Settings → Secrets and variables → Actions → onglet Variables → New repository variable*.

- Nom : `HARMONY_API_URL`
- Valeur : l'URL de l'API, sans `/` final.

Chaque jour, GitHub appelle alors l'API. Cela évite la mise en pause automatique du projet Supabase gratuit après 7 jours sans activité. En cas de panne de l'API ou de la base, l'exécution échoue et GitHub envoie un e-mail. On peut la lancer à la main depuis l'onglet **Actions → Keepalive → Run workflow**.

## 5. Vérifier

- `https://<URL de l'API>/up` répond avec le code 200.
- `https://<URL de l'API>/api/v1/health` renvoie `"status":"ok"` et `"database":"ok"`.

Si `database` vaut `unavailable` (code 503), voir le tableau de dépannage ci-dessous.

## Déploiements suivants

Ils sont automatiques : chaque push sur `main` qui modifie `harmony-api/` redéploie l'API. Les nouvelles tables sont créées au démarrage.

## Limites des plans gratuits

À connaître avant de montrer l'application à de vrais clients :

- **Render** met l'API en veille après une période sans visite. La première requête suivante peut prendre près d'une minute.
- **Supabase** met le projet en pause après 7 jours sans activité. Le ping quotidien l'évite, mais un projet en pause doit être relancé à la main depuis le tableau de bord. Les sauvegardes du plan gratuit sont limitées.
- Avant l'ouverture au public, passer les deux services en plan payant, puis désactiver le workflow *Keepalive*.

## Variables qui seront ajoutées plus tard

Au fil du projet, le développeur indiquera les secrets à ajouter dans **Render → Environment**. Ils ne sont jamais écrits dans le dépôt.

| Étape | Variables |
|---|---|
| Paiement | Clés FedaPay et secret de signature du webhook |
| Notifications | Identifiants Firebase (FCM) et jeton WhatsApp Cloud API |
| Temps réel | Configuration Laravel Reverb |

Il faudra aussi un traitement des files d'attente et une tâche planifiée (expiration des réservations impayées). Ce guide sera mis à jour à ce moment-là.

## Dépannage

| Symptôme | Cause probable |
|---|---|
| Le contrôle de santé de Render échoue dès le démarrage | `APP_KEY` absente ou mal copiée (elle doit commencer par `base64:`). |
| `database: unavailable`, ou erreur de connexion dans les logs Render | Mauvais `DB_HOST` ou `DB_USERNAME`. Vérifier qu'ils viennent bien du **Session pooler** et non de la connexion directe, et que le port est `5432`. |
| Erreur d'authentification à la base | Mot de passe erroné. Il peut être réinitialisé dans *Supabase → Project Settings → Database*, puis mis à jour dans Render. |
| L'API répondait puis ne répond plus après quelques jours | Projet Supabase en pause : le relancer depuis son tableau de bord, puis vérifier que la variable `HARMONY_API_URL` est bien définie sur GitHub. |
| Les liens générés par l'API sont en `http://` | `APP_URL` n'est pas renseignée. |
