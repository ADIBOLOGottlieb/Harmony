# HARMONY HOME — Conventions du projet

Plateforme de **conciergerie immobilière** type Airbnb pour Lomé et l'Afrique de l'Ouest francophone : gestion d'un parc d'appartements (location, réservation en ligne, paiement). Phase 2 : biens à vendre et programmes de construction.

## Structure et hébergement
- `/harmony-api` : Laravel 13 (PHP 8.4, fixé via `config.platform` de Composer), PostgreSQL 17, Sanctum, queues + scheduler, admin Filament. Laravel 11 est en fin de vie et bloqué par Composer pour failles connues : ne pas y revenir.
- `/harmony-app` : Flutter 3 / Dart 3.
- Hébergement (plans gratuits pour l'instant) :
  - **Base : Supabase**, région Central EU (Frankfurt), via le **Session pooler** (IPv4, port 5432 ; jamais le port 6543 du mode transaction, incompatible avec les requêtes préparées de PDO). Data API Supabase désactivée : tout passe par l'API Laravel.
  - **API : Render**, région Frankfurt, conteneur `harmony-api/Dockerfile`, blueprint `render.yaml`. URL : https://harmony-api-sfap.onrender.com (sonde : `/api/v1/health`).
  - **Keepalive** : `.github/workflows/keepalive.yml` appelle la sonde chaque jour (pause Supabase après 7 jours). À retirer lors du passage aux plans payants.
  - **La configuration de Supabase, Render et des variables GitHub est faite par l'administrateur** : on prépare le dépôt et `docs/deploiement-render.md`, on ne touche pas aux tableaux de bord.
- Dépôt : https://github.com/ADIBOLOGottlieb/Harmony (monorepo, branche `main`). CI dans `.github/workflows/ci.yml` ; APK de test publié à chaque push sur `harmony-app/` (`android-apk.yml`, onglet Releases).
- Français par défaut, textes prêts pour l'i18n. Devise FCFA en entiers (jamais de décimales ni de float). Fuseau `Africa/Lome` (UTC+0) ; stocker en UTC, afficher en heure locale.

## Produit
- **Zones** (quartier/ville : nom, ville, pays, couverture) et **appartements** (titre, description, type, chambres, salles de bain, capacité, surface, équipements, prix par nuit, caution, galerie, statut disponible/occupé/maintenance, GPS, adresse, zone, propriétaire).
- **Durées** : nuitées par défaut ; **créneaux de 3 h et journée en option**, activés par appartement par le propriétaire, avec leurs propres prix.
- **Calendrier par appartement** : jours libres, réservés, bloqués ; blocages et prix saisonniers par le propriétaire ou l'admin.
- **Réservation** : dates → récapitulatif (prix, frais, caution, total FCFA) → paiement → confirmation avec référence unique, reçu (PDF ou écran), push et e-mail/SMS. Statuts : `pending`, `confirmed`, `cancelled`, `completed`, `refunded`. Politique d'annulation configurable.
- **Rôles** : client, propriétaire, concierge/gestionnaire, admin.
- **Espace de gestion** : occupation, revenus, réservations à venir, arrivées/départs du jour ; CRUD biens, photos, tarifs, calendrier ; ménage et maintenance (tâches, statut, responsable) ; clients, historique, avis ; exports CSV/PDF.
- **Phase 2** : modèle `Bien` (location / vente / programme) ; section « À vendre / Projets » derrière le flag `FEATURE_SALES` (désactivé).

## Backend (Laravel)
- API REST `/api/v1`, réponses via API Resources, erreurs de validation en HTTP 422. Limitation de débit sur l'auth et la réservation.
- Logique métier dans des Services (`BookingService`, `PricingService`, `PaymentService`…), jamais dans les contrôleurs. Form Requests pour la validation, Policies par rôle.
- Auth : téléphone (E.164, `string`) + OTP, tokens Sanctum avec expiration.
- **Toute modification de schéma passe par une NOUVELLE migration**, jamais en éditant une migration existante.
- **Anti double-réservation** :
  - tout passe par `BookingService` (création, prolongation) ;
  - transaction + `lockForUpdate` sur l'appartement ;
  - chevauchement testé sur `[start_at, end_at)` pour les statuts actifs (`pending`, `confirmed`) ;
  - **double sécurité en base** : extension `btree_gist` + contrainte `EXCLUDE USING gist (apartment_id WITH =, tstzrange(start_at, end_at, '[)') WITH &&) WHERE (statut actif)`. Violation (SQLSTATE `23P01`) → erreur métier « dates indisponibles » (HTTP 409). Migration : `CREATE EXTENSION IF NOT EXISTS btree_gist` (déjà activée par l'admin sur Supabase, nécessaire en CI) ;
  - colonnes horaires en `timestamptz` ; tests de concurrence obligatoires.
- **Prix** : calculé côté serveur (`PricingService`, prix saisonniers). Total, frais, caution et acompte figés sur la réservation à sa création.
- **Paiement** : interface `PaymentGateway`, une implémentation par moyen :
  - Mobile Money Togo (TMoney, Flooz) et carte bancaire via **FedaPay** ;
  - virement bancaire avec validation manuelle par l'admin ;
  - acompte puis solde ; remboursements ; journal des transactions ;
  - webhooks signés et idempotents (identifiant d'événement unique) ;
  - clés d'API uniquement en variables d'environnement, mode **sandbox** par défaut hors production.
- **Tests et base de données** : la CI exécute Pest sur un vrai PostgreSQL 17. En local, sans PostgreSQL, les tests tournent sur SQLite ; ceux qui dépendent de PostgreSQL (contrainte d'exclusion, concurrence) sont ignorés hors PostgreSQL et doivent passer en CI. Tests obligatoires : chevauchements, webhooks de paiement, permissions. Style PSR-12 + Pint.

## Mobile (Flutter)
- Architecture feature-first : `catalog` (domaine, données, état, widgets partagés), `home`, `explore`, `apartment`, `bookings`, `favorites`, `profile`, `shell`, `splash` ; à venir `auth`, `booking_flow`, `payments`, `management`.
- Riverpod, GoRouter (coque à onglets `StatefulShellRoute`), Dio + intercepteur de token, Freezed + json_serializable (à l'arrivée de l'API), `flutter_secure_storage` pour le jeton, `url_launcher` (appel, WhatsApp, carte).
- Les écrans lisent uniquement les providers de `features/catalog/data/catalog_repository.dart` : brancher l'API ne change que ce fichier.
- Configuration par `--dart-define` (`lib/core/config/app_config.dart`) : `API_BASE_URL`, `CONCIERGE_PHONE`, `FEATURE_SALES`. Jamais de secret dans l'app.
- États chargement, erreur, vide et hors-ligne gérés systématiquement ; cache du catalogue ; images à chargement progressif (`HarmonyImage`).
- Widget tests sur les parcours (recherche, fiche, favoris, réservation à venir), en mode « animations réduites ».

## Design (agence immobilière haut de gamme)
- Sobre, rassurant, premium ; photographie d'abord ; beaucoup d'espace ; aucun look « template ».
- Nom : **HARMONY HOME**. Logo : monogramme « H » sous une double arche (`HarmonyMark`) + logotype « HARMONY / HOME ».
- Palette : bleu nuit `#14213D` (principale), champagne `#C8A96A` (accent), ivoire `#F7F3EC` (fond), gris chauds ; texte champagne sur fond clair en `#7A5F2A` (contraste AA). Mode sombre cohérent (fond `#0C1220`).
- Typographie : Playfair Display (titres) et Manrope (texte), **embarquées dans `assets/fonts/`** (OFL) pour fonctionner hors-ligne.
- **Un seul fichier source : `lib/core/theme/design_tokens.dart`** (palette, `HarmonyColors` en extension de thème, espacements, rayons 8–12 px, ombres douces, durées, styles de texte). Les composants Material sont stylés dans `app_theme.dart` ; aucun écran ne redéfinit couleurs ou tailles.
- Composants : `PropertyCard` (photo, statut, favori, zone, caractéristiques, prix FCFA), `StatusBadge`, `SectionHeader`, `EmptyState`, `HarmonyImage` + `Skeleton`, `showHarmonySheet`, boutons/champs/chips/feuilles via le thème.
- Navigation : barre du bas (Accueil, Explorer, Réservations, Favoris, Profil) ; fiche bien en plein écran au-dessus.
- Mouvement : transitions douces (`softPage`), Hero sur les photos, squelettes, retour haptique ; respect du réglage « réduire les animations ».
- Accessibilité : contraste AA, cibles ≥ 48 dp, tailles de texte adaptables, libellés sémantiques ; les boutons posés sur une carte cliquable sont des nœuds sémantiques distincts (`Semantics(container: true)`).
- Photos de démonstration CC0 dans `assets/images/demo/` (voir `CREDITS.md`), à remplacer par les vraies photos servies par l'API.
- Skills de design disponibles : `material-3`, `ux-designer`, `ui-ux-pro-max`, `frontend-design`. Cette charte prime sur leurs suggestions.

## Sécurité
- Aucune donnée sensible dans les logs (téléphone, OTP, coordonnées de paiement). Secrets uniquement dans `.env` / variables d'environnement, jamais commités.
- L'adresse exacte et l'itinéraire détaillé ne sont communiqués qu'après confirmation de la réservation ; la fiche publique n'affiche que le quartier.
- Ne jamais réutiliser d'identifiants trouvés dans un dépôt cloné.

## Plan d'exécution
1. ✅ Design system agence et refonte de tous les écrans (catalogue de démonstration).
2. ✅ Modèles et API : zones, appartements, photos, `Bien` (flag), rôles et Policies, limitation de débit, seeders Lomé, endpoints catalogue.
3. ✅ Écrans catalogue branchés sur l'API : filtres complets (budget, équipements), carte, cache hors-ligne, favoris persistés.
4. ✅ Calendrier et réservation : disponibilités, blocages, prix saisonniers, contrainte anti-chevauchement, flux complet, référence, annulation.
5. ✅ Paiement FedaPay (sandbox), virement, acompte/solde, webhooks, remboursements, reçus.
6. ✅ Espace de gestion Filament (`/gestion`) : tableau de bord, CRUD, virements et remboursements, ménage/maintenance, avis, exports CSV/PDF.
7. À venir : prestataire SMS, notifications (FCM, WhatsApp), stockage S3 des photos en production, `Bien` (phase 2).

## Décisions ouvertes
- Numéro WhatsApp/téléphone du concierge (`CONCIERGE_PHONE`).
- Choix provisoires à confirmer par l'agence : frais de service 5 %, acompte 30 % (séjours courts payés en totalité), annulation gratuite jusqu'à J-5, arrivée 14 h, départ 11 h, journée 10 h-18 h, caution réglée à l'arrivée.
- Prestataire SMS pour les codes de connexion.
- Fournisseur de tuiles de carte en production (OSM public interdit en usage intensif : MapTiler, Stadia…), via `MAP_TILE_URL`.
- Confidentialité : le catalogue n'expose que le quartier (`area`) ; l'adresse exacte (`address`) n'est révélée qu'après confirmation.

## Méthode de travail
- Une étape du plan à la fois, commits petits et atomiques (`feat:`, `fix:`, `test:`, `docs:`).
- À chaque étape : `flutter analyze`, `flutter test`, `./vendor/bin/pint --test`, `./vendor/bin/pest` ; corriger avant de continuer. Ne jamais déclarer une tâche terminée sans tests verts.
- Avancer étape par étape avec un APK de test et ses liens à chaque livraison, sauf blocage.
- Avant de modifier du code existant, le lire. Ne poser de question que si une décision est vraiment bloquante ; sinon choisir le plus raisonnable et le signaler.
