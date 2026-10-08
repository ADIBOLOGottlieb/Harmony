# Déployer l'API HARMONY sur Render

Ce guide s'adresse à la personne qui administre le compte Render. Il crée l'API et sa base PostgreSQL à partir du fichier `render.yaml` du dépôt : une fois le blueprint connecté, il n'y a rien à configurer à la main en dehors de deux variables.

## Ce qui sera créé

| Ressource | Nom | Rôle |
|---|---|---|
| Base PostgreSQL 17 | `harmony-db` | Données de l'application (réservations, chambres, comptes). |
| Service web (Docker) | `harmony-api` | API Laravel, construite depuis `harmony-api/Dockerfile`. |

Les deux sont placés dans la région **Frankfurt**, la plus proche de Lomé.

## Prérequis

- Un compte Render avec accès au dépôt GitHub `ADIBOLOGottlieb/Harmony`.
- La clé d'application Laravel (`APP_KEY`). Le développeur peut la fournir, ou vous pouvez la générer depuis le dossier `harmony-api` avec `php artisan key:generate --show`. Elle ressemble à `base64:…` et ne doit jamais être commitée ni envoyée en clair dans une messagerie.

## Mise en place (une seule fois)

1. Dans Render, choisir **New → Blueprint**, puis sélectionner le dépôt `ADIBOLOGottlieb/Harmony` et la branche `main`.
2. Render lit `render.yaml` et affiche la base `harmony-db` et le service `harmony-api`. Il demande deux valeurs :
   - **`APP_KEY`** : coller la clé générée ci-dessus.
   - **`APP_URL`** : laisser vide pour l'instant si l'URL n'est pas encore connue.
3. Valider avec **Apply**. Render crée la base, construit l'image Docker, puis démarre l'API. Au démarrage, les migrations de base de données s'exécutent automatiquement.
4. Une fois le service en ligne, copier son URL publique (par exemple `https://harmony-api-xxxx.onrender.com`). La renseigner dans **harmony-api → Environment → `APP_URL`**, puis enregistrer : Render redéploie le service.

## Vérifier que tout fonctionne

- `https://<URL du service>/up` répond avec le code 200.
- `https://<URL du service>/api/v1/health` renvoie `{"status":"ok","service":"harmony-api",…}`.
- L'onglet **Logs** du service ne montre pas d'erreur de connexion à la base.

## Déploiements suivants

Ils sont automatiques : chaque push sur `main` qui modifie le dossier `harmony-api/` reconstruit et redéploie l'API. Les modifications limitées à l'application mobile ne déclenchent pas de déploiement.

## Avant l'ouverture au public

Le blueprint utilise les plans **gratuits** pour démarrer. Avant d'accueillir de vrais clients :

- **Base de données** : passer `harmony-db` sur un plan payant. Les bases gratuites sont supprimées après 30 jours et n'ont pas de sauvegardes.
- **Service web** : passer `harmony-api` sur un plan payant. En gratuit, le service se met en veille après une période d'inactivité, et la première requête suivante peut prendre près d'une minute.
- Garder l'accès externe à la base fermé (`ipAllowList` vide). Seule l'API doit pouvoir s'y connecter.

## Variables qui seront ajoutées plus tard

Au fil des étapes du projet, le développeur indiquera les variables à ajouter dans **Environment**, toujours en tant que secrets. Elles ne sont jamais écrites dans le dépôt.

| Étape | Variables |
|---|---|
| Paiement | Clés FedaPay et secret de signature du webhook |
| Notifications | Identifiants Firebase (FCM) et jeton WhatsApp Cloud API |
| Temps réel | Configuration Laravel Reverb |

Il faudra aussi ajouter un **worker** (traitement des files d'attente) et une **tâche planifiée** (expiration des réservations impayées). Ce guide sera mis à jour à ce moment-là.

## En cas de problème

| Symptôme | Cause probable |
|---|---|
| Le contrôle de santé échoue dès le démarrage | `APP_KEY` absente ou mal copiée (elle doit commencer par `base64:`). |
| Erreur de connexion à la base dans les logs | La base `harmony-db` n'est pas encore prête : attendre puis redéployer. |
| Les liens générés par l'API sont en `http://` | `APP_URL` n'est pas renseignée. |
