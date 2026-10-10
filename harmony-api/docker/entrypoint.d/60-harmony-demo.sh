#!/bin/sh
# Après les migrations (50-laravel-automations).
# 1. Premier administrateur si HARMONY_ADMIN_EMAIL et HARMONY_ADMIN_PASSWORD sont définis.
# 2. Catalogue de démonstration, une seule fois, si HARMONY_SEED_DEMO=true.
php /var/www/html/artisan harmony:bootstrap-admin --no-interaction || true
if [ "${HARMONY_SEED_DEMO:-false}" = "true" ]; then
    php /var/www/html/artisan harmony:seed-demo --no-interaction || true
fi
