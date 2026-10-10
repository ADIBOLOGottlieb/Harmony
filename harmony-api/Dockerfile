# Image de production de l'API HARMONY (Render).
# Base : PHP 8.4 + PHP-FPM + Nginx, maintenue par Server Side Up, pensée pour Laravel
# (pdo_pgsql inclus, utilisateur non root, écoute sur le port 8080).
FROM serversideup/php:8.4-fpm-nginx-alpine

ENV PHP_OPCACHE_ENABLE=1 \
    # Au démarrage : migrations (--force) puis mise en cache config/routes/vues.
    AUTORUN_ENABLED=true \
    AUTORUN_LARAVEL_MIGRATION=true \
    AUTORUN_LARAVEL_STORAGE_LINK=true \
    LOG_CHANNEL=stderr

WORKDIR /var/www/html

# intl : requise par Filament (espace de gestion), absente de l'image de base.
USER root
RUN install-php-extensions intl
USER www-data

# Dépendances d'abord : la couche reste en cache tant que le lock ne change pas.
COPY --chown=www-data:www-data composer.json composer.lock ./
RUN composer install --no-dev --no-interaction --prefer-dist --no-progress --no-scripts --no-autoloader

COPY --chown=www-data:www-data . .
RUN composer dump-autoload --optimize --no-dev \
    && php artisan package:discover --ansi \
    && php artisan filament:assets --ansi

# Catalogue de démonstration au premier démarrage (HARMONY_SEED_DEMO=true).
COPY --chmod=755 docker/entrypoint.d/ /etc/entrypoint.d/

EXPOSE 8080
