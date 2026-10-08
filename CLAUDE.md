# HARMONY DESIGN — Conventions du projet

Application premium de réservation de chambres par créneaux (3h, nuitée, journée, 2 jours, 3 jours) avec forfaits, pour Lomé (Togo). Fonction clé : guider le client jusqu'à l'établissement sans qu'il ait besoin d'appeler.

## Structure
- `/harmony-api` : Laravel 13 (PHP 8.4, fixé via `config.platform` de Composer), PostgreSQL 17, Sanctum, Reverb, queues + scheduler, admin Filament. Laravel 11 est en fin de vie et bloqué par Composer pour failles connues : ne pas y revenir.
- Hébergement de l'API : Render, région Frankfurt (conteneur Docker `harmony-api/Dockerfile` + PostgreSQL géré, blueprint `render.yaml`). **La configuration Render (compte, services, secrets) est faite par l'administrateur** : on prépare le dépôt et `docs/deploiement-render.md`, on ne touche pas au tableau de bord Render.
- Dépôt : https://github.com/ADIBOLOGottlieb/Harmony (monorepo, branche `main`, CI GitHub Actions dans `.github/workflows/ci.yml`).
- `/harmony-app` : Flutter 3 / Dart 3.
- Interface en français. Devise FCFA en entiers (jamais de décimales ni de float). Fuseau `Africa/Lome` (UTC+0) ; stocker en UTC, afficher en heure locale.

## Produit
- **Créneaux** (`stay_types`, prix par catégorie de chambre) : 3h, nuitée, journée, 2 jours, 3 jours. L'heure exacte de début et de fin est enregistrée.
- Un client ne voit que les disponibilités réelles et les forfaits proposés, jamais les réservations des autres.
- **Forfaits** (noms évocateurs, jamais explicites) :
  - Essentiel : chambre seule.
  - Romantique : décoration, ambiance lumineuse, musique, boisson de bienvenue.
  - Gourmand : chambre + repas ou plateau livré à l'heure choisie.
  - Prestige : Romantique + Gourmand + late check-out + accès prioritaire.
- **Fonctions** :
  - tampon ménage de 45 min (configurable) ;
  - prolongation en un clic si la chambre est libre, avec supplément horaire ;
  - tarification dynamique (week-end, soirée, jours fériés, heures creuses) ;
  - check-in autonome par code à usage unique ;
  - fidélité (points, séjour offert, parrainage) ;
  - avis privés, visibles uniquement par la direction ;
  - upsell après réservation ;
  - liste d'attente avec push dès qu'un créneau se libère.

## Backend (Laravel)
- API REST `/api/v1`, réponses via API Resources, erreurs de validation en HTTP 422.
- Logique métier dans des Services (`BookingService`, `PricingService`, `PaymentService`, `ArrivalService`…), jamais dans les contrôleurs. Form Requests pour la validation, Policies pour les droits.
- Rôles : client, propriétaire, réceptionniste, ménage.
- Auth : téléphone (format E.164, stocké en `string`) + OTP, tokens Sanctum avec expiration. Confirmation 18+ obligatoire à l'inscription.
- Tables principales : `users`, `rooms`, `room_categories`, `stay_types`, `packages`, `package_items`, `bookings`, `booking_extras`, `payments`, `price_rules`, `loyalty_points`, `waitlist`, `arrival_tracking`, `venue_guides`, `reviews`.
- Statuts de réservation : `pending`, `confirmed`, `en_route`, `checked_in`, `completed`, `cancelled`, `expired`.
- **Anti double-réservation** :
  - tout passe par `BookingService` : création, prolongation, late check-out Prestige ;
  - transaction + `lockForUpdate` sur la chambre ;
  - chevauchement testé sur `[start_at, blocked_until)`, où `blocked_until = end_at + tampon`, pour les statuts actifs (`pending`, `confirmed`, `en_route`, `checked_in`) ;
  - **double sécurité en base** : extension `btree_gist` + contrainte `EXCLUDE USING gist (room_id WITH =, tstzrange(start_at, blocked_until, '[)') WITH &&) WHERE (statut actif)`. Une violation (SQLSTATE `23P01`) est traduite en erreur métier « créneau indisponible » (HTTP 409) ;
  - colonnes horaires en `timestamptz` ;
  - tests de concurrence obligatoires.
- **Tests et base de données** : la CI exécute Pest sur un vrai PostgreSQL 17. En local, sans PostgreSQL, les tests tournent sur SQLite ; les tests qui dépendent de PostgreSQL (contrainte d'exclusion, concurrence) sont ignorés hors PostgreSQL et doivent passer en CI avant tout merge.
- **Prix** : calculé par `PricingService` côté serveur. Le total et l'acompte sont figés sur la réservation au moment de sa création ; un changement de règle ne modifie pas une réservation existante.
- **Paiement** : FedaPay (TMoney/Flooz), acompte de 30 %. Webhook signé et idempotent (identifiant d'événement unique). Les réservations impayées expirent après 30 min (scheduler).
- **Notifications** : FCM et WhatsApp Cloud API (modèles de messages approuvés), envoyées via les queues.
- Temps réel : Laravel Reverb, avec polling en repli.
- Tests Pest obligatoires sur les chevauchements, la concurrence, les webhooks, la tarification et les droits d'accès à l'adresse et au code. Style PSR-12 + Pint.

## Guidage jusqu'à l'établissement
- **Écran « Y aller »**, débloqué après paiement de l'acompte :
  - carte avec la position du client, la destination, l'itinéraire, la durée et la distance ;
  - `flutter_map` + OSM + OSRM, derrière un adaptateur de carte (Google Maps en option) ;
  - deep links Google Maps / Waze en secours.
- **Repères** (`venue_guides`) : 3 à 5 photos de l'approche et une description textuelle, ordonnables dans l'admin.
- Boutons « Appeler / WhatsApp l'accueil » et « Je suis perdu » (ce dernier envoie la position au réceptionniste).
- **Lien d'arrivée** `harmony.app/arrivee/{token}` :
  - token aléatoire et non devinable ;
  - expire après le séjour, ne contient jamais le forfait ;
  - ouvre l'app (app_links) ou une page web légère (Laravel + Leaflet).
- **Suivi d'arrivée** :
  - uniquement pendant le trajet, avec consentement explicite et révocable ;
  - envoi toutes les 15 s ;
  - l'admin voit l'ETA en direct ;
  - aucune localisation en arrière-plan permanent.
- **Geofence** : à moins de 100 m, l'app propose « Je suis arrivé » et affiche le code d'accès.
- **Hors-ligne** : itinéraire, photos et code mis en cache (chiffré) dès la confirmation. Le code ne s'affiche que dans la fenêtre du créneau.
- Les permissions de localisation sont demandées au moment où elles servent, avec une explication claire.

## Mobile (Flutter)
- Architecture feature-first : `auth`, `home`, `booking`, `packages`, `payments`, `arrival`, `loyalty`, `profile`.
- Riverpod, Dio + intercepteur de token, GoRouter, Freezed + json_serializable, `flutter_secure_storage` pour le jeton et le code d'accès.
- Paquets : `flutter_map`, `geolocator`, `url_launcher`, `app_links`, `google_fonts`, `flutter_animate`, `lottie`, `cached_network_image`, `firebase_messaging`.
- États chargement, erreur, vide et hors-ligne gérés systématiquement.
- Widget tests sur le parcours de réservation et l'écran « Y aller ».

## Design
- Direction « boutique hotel de nuit ». Sombre par défaut, mode clair optionnel soigné.
- Couleurs : fond `#0E0A0C`, bordeaux `#5A0F2E`, or satiné `#C9A24D`, ivoire `#F4EDE4` pour le texte.
- Thème cinéma : salle obscure, rideaux de velours, enseigne à ampoules, grain de pellicule ; les créneaux sont des « séances » (Court-métrage, Séance de minuit, Plein jour, Double programme, Trilogie).
- Transitions : ouverture (amorce 3-2-1, rideaux, monogramme), iris vers l'intro, entracte (rideaux) vers l'affiche, Hero affiche → fiche. Voir `lib/core/motion/cinematic_transitions.dart`.
- Typographie : Playfair Display (titres) et Manrope (texte), **embarquées dans `assets/fonts/`** (licence OFL) plutôt que `google_fonts`, pour fonctionner hors-ligne et sans appel réseau.
- **Un seul fichier source : `lib/core/theme/design_tokens.dart`** (couleurs, espacements, rayons, ombres, styles de texte). Aucune couleur ni taille en dur ailleurs.
- Material 3 personnalisé :
  - cartes à rayon 24 ;
  - bottom sheets ;
  - boutons pill à léger gradient ;
  - glassmorphism discret, uniquement sur les barres flottantes ;
  - lueurs dorées sur les éléments actifs.
- Mouvement :
  - transitions Hero liste → détail ;
  - `flutter_animate` ;
  - skeleton loaders ;
  - retour haptique sur les actions clés ;
  - Lottie pour la confirmation ;
  - aucune animation gratuite, et respect du réglage « réduire les animations ».
- Accessibilité : contraste AA (l'or sur le bordeaux est à vérifier), tailles de texte dynamiques, cibles tactiles ≥ 48 dp.
- Skills de design disponibles : `material-3`, `ux-designer`, `ui-ux-pro-max`, `frontend-design`. Cette charte prime sur leurs suggestions.

## Discrétion et sécurité
- Notifications, SMS, WhatsApp et factures n'affichent que « HARMONY », jamais le forfait ni le détail de la réservation. Option de titre de notification neutre.
- L'adresse exacte n'est révélée qu'après paiement de l'acompte. Le code d'accès n'est visible que pour une réservation payée, pendant la fenêtre du créneau, et il est à usage unique.
- La position du client n'est stockée que pendant le trajet, puis supprimée au plus tard à la fin du séjour (job planifié).
- Aucune donnée sensible dans les logs : téléphone, position, code, OTP, token d'arrivée.
- Secrets uniquement dans `.env`, jamais commités. Ne jamais réutiliser d'identifiants trouvés dans un dépôt cloné.
- Réservation réservée aux majeurs.

## Plan d'exécution
1. Initialiser `harmony-api` et `harmony-app`, dépôt git, CI de base, `design_tokens.dart`.
2. Migrations, modèles, seeders réalistes (Lomé, 8 chambres, 4 forfaits).
3. `BookingService` + endpoints de disponibilités et de réservation + tests Pest.
4. Auth téléphone/OTP + 18+.
5. Écrans Flutter : onboarding, accueil, détail chambre, choix du créneau, forfaits.
6. Paiement FedaPay + expiration + notifications.
7. Guidage : « Y aller », repères, lien d'arrivée, suivi ETA, geofence, page web de secours.
8. Admin Filament : grille d'occupation, prix, forfaits, repères, ETA des clients en route.
9. Fidélité, liste d'attente, prolongation, avis.
10. Polish design, tests widget, audit sécurité, build release.

## Décisions ouvertes (à trancher avant l'étape concernée)
- Horaires fixes de la nuitée et de la journée, avant l'étape 2.
- Durée du late check-out Prestige et tarif horaire de prolongation, avant l'étape 3.
- Hébergement des tuiles OSM et d'OSRM en production : les serveurs publics sont interdits en usage commercial intensif. Prévoir un fournisseur (MapTiler, Stadia…) ou un auto-hébergement, avant l'étape 7.
- Seuil du séjour offert (X séjours) et règles de parrainage, avant l'étape 9.

## Méthode de travail
- Une étape du plan à la fois. À la fin de chaque étape :
  - lancer les tests ;
  - commit (`feat:`, `fix:`, `test:`) ;
  - résumé en 3 lignes ;
  - enchaîner sur l'étape suivante sans attendre, sauf blocage ou décision ouverte.
- Avant de modifier du code existant, le lire. Proposer un plan seulement si le changement sort du périmètre de l'étape.
- Ne jamais déclarer une tâche terminée sans tests verts.
