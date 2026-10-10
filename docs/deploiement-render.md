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
3. **Désactiver la Data API** : décocher *Enable Data API* dans les options avancées à la création du projet ; sur un projet existant, aller dans *Integrations → Data API* (ou *Project Settings → API* selon la version du tableau de bord) et désactiver l'option. HARMONY passe uniquement par son API Laravel. Laissée active, la Data API pourrait exposer les tables publiquement avec la clé `anon`.
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

## 6. Démonstration et espace de gestion

À saisir dans **Render → harmony-api → Environment**, puis **Save changes** : le service redémarre. Si le service a été créé à la main et non depuis le blueprint, chaque variable s'ajoute ici avec **Add Environment Variable**.

| Variable | Valeur | Rôle |
|---|---|---|
| `HARMONY_SEED_DEMO` | `true` | Charge les 5 zones et les 8 biens de démonstration au premier démarrage, uniquement si la base ne contient encore aucun bien. |
| `OTP_EXPOSE_CODE` | `true` | Aucun SMS n'est branché : l'app affiche le code de connexion. À passer à `false` dès qu'un prestataire SMS est configuré. |
| `PAYMENTS_SANDBOX` | `true` | Paiement simulé (aucun débit réel). À passer à `false` quand FedaPay est configuré. |
| `HARMONY_ADMIN_EMAIL` | votre e-mail | Identifiant du premier compte administrateur. |
| `HARMONY_ADMIN_PASSWORD` | 12 caractères minimum | Mot de passe de ce compte. **À supprimer de Render une fois connecté** : il ne sert qu'à la création du compte et n'écrase jamais un compte existant. |
| `HARMONY_BANK_TRANSFER_INSTRUCTIONS` | texte | Coordonnées bancaires affichées au client qui choisit le virement. |

L'espace de gestion est ensuite à l'adresse `https://<URL de l'API>/gestion`. On s'y connecte avec l'e-mail et le mot de passe ci-dessus. Les autres comptes (concierges, propriétaires) se créent depuis **Clients et comptes** : changer le rôle du compte et lui donner un mot de passe. Un client crée d'abord son compte dans l'app avec son numéro.

Ce que chaque rôle peut faire :

- **Administrateur** : tout, y compris les rôles et les mots de passe.
- **Concierge** : biens, zones, réservations, validation des virements et des remboursements, ménage et maintenance, avis. Il consulte les comptes sans pouvoir les modifier.
- **Propriétaire** : ses biens uniquement (fiche, photos, blocages de calendrier, prix saisonniers), les réservations et le ménage qui s'y rapportent, sans les coordonnées des clients.

## 7. Paiements réels (FedaPay)

Dans le tableau de bord FedaPay, créer un webhook vers `https://<URL de l'API>/api/v1/payments/webhooks/fedapay`, puis renseigner dans Render :

| Variable | Valeur |
|---|---|
| `FEDAPAY_ENVIRONMENT` | `sandbox` pour les essais, `live` en production |
| `FEDAPAY_SECRET_KEY` | clé secrète FedaPay |
| `FEDAPAY_WEBHOOK_SECRET` | secret de signature du webhook |
| `PAYMENTS_SANDBOX` | `false` |

## 8. Photos téléversées (stockage)

Le disque de Render est effacé à chaque déploiement : une photo téléversée depuis l'espace de gestion disparaîtrait. Avant d'en ajouter de vraies, utiliser un stockage compatible S3, par exemple Supabase Storage :

1. Supabase → **Storage** → **New bucket** `harmony-media`, en cochant **Public bucket**.
2. Supabase → **Project Settings → Storage → S3 access keys** → **New access key**.
3. Dans Render : `MEDIA_DISK=s3`, puis `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` (la clé créée), `AWS_DEFAULT_REGION=eu-central-1`, `AWS_BUCKET=harmony-media`, `AWS_ENDPOINT=https://<référence>.supabase.co/storage/v1/s3`, `AWS_URL=https://<référence>.supabase.co/storage/v1/object/public/harmony-media` et `AWS_USE_PATH_STYLE_ENDPOINT=true`.

Les photos de démonstration sont embarquées dans l'app et ne dépendent pas de ce stockage.

## Variables qui seront ajoutées plus tard

| Étape | Variables |
|---|---|
| SMS (codes de connexion) | Identifiants du prestataire SMS |
| Notifications | Identifiants Firebase (FCM) et jeton WhatsApp Cloud API |

Sur le plan gratuit, aucun processus planifié ne tourne. L'expiration des réservations impayées et le passage des séjours en « terminé » se font donc à la consultation des réservations. En plan payant, ajouter un *Background Worker* Render avec la commande `php artisan schedule:work`.

## Dépannage

| Symptôme | Cause probable |
|---|---|
| Le contrôle de santé de Render échoue dès le démarrage | `APP_KEY` absente ou mal copiée (elle doit commencer par `base64:`). |
| `database: unavailable`, ou erreur de connexion dans les logs Render | Mauvais `DB_HOST` ou `DB_USERNAME`. Vérifier qu'ils viennent bien du **Session pooler** et non de la connexion directe, et que le port est `5432`. |
| Erreur d'authentification à la base | Mot de passe erroné. Il peut être réinitialisé dans *Supabase → Project Settings → Database*, puis mis à jour dans Render. |
| L'API répondait puis ne répond plus après quelques jours | Projet Supabase en pause : le relancer depuis son tableau de bord, puis vérifier que la variable `HARMONY_API_URL` est bien définie sur GitHub. |
| Les liens générés par l'API sont en `http://` | `APP_URL` n'est pas renseignée. |
