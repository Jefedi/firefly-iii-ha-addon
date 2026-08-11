#!/bin/bash
set -e

# ==============================================================================
# Firefly III HA Add-on — Script d'init + démarrage
# ==============================================================================

export FIREFLY_III_ENV=production
export DB_CONNECTION=sqlite

DATA_DIR="/data"
DB_FILE="${DATA_DIR}/database.sqlite"
UPLOAD_DIR="${DATA_DIR}/uploads"
APP_KEY_FILE="${DATA_DIR}/app_key.txt"
FIREFLY_DIR="/var/www/html"

mkdir -p "${DATA_DIR}" "${UPLOAD_DIR}"

# 1. APP_KEY persistant
if [ ! -f "${APP_KEY_FILE}" ]; then
    echo "[Firefly III] Génération d'un APP_KEY aléatoire (premier démarrage)..."
    APP_KEY=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | head -c 32)
    echo "base64:${APP_KEY}" > "${APP_KEY_FILE}"
fi
APP_KEY=$(cat "${APP_KEY_FILE}")

# 2. Écrire le .env
cat > "${FIREFLY_DIR}/.env" << EOF
FIREFLY_III_ENV=production
DB_CONNECTION=sqlite
DB_DATABASE=${DB_FILE}
APP_KEY=${APP_KEY}
APP_URL=http://localhost
SHOW_ERROR_MESSAGES=false
LOG_CHANNEL=stack
APP_DEBUG=false
EOF

# 3. Lier uploads vers /data
if [ -d "${FIREFLY_DIR}/storage/upload" ] && [ ! -L "${FIREFLY_DIR}/storage/upload" ]; then
    cp -a "${FIREFLY_DIR}/storage/upload/." "${UPLOAD_DIR}/" 2>/dev/null || true
    rm -rf "${FIREFLY_DIR}/storage/upload"
fi
ln -sf "${UPLOAD_DIR}" "${FIREFLY_DIR}/storage/upload"

# 4. Lier la DB SQLite vers /data
mkdir -p "${FIREFLY_DIR}/storage/db"
ln -sf "${DB_FILE}" "${FIREFLY_DIR}/storage/db/database.sqlite"

# 5. Premier démarrage = migrations
if [ ! -f "${DB_FILE}" ] || [ ! -s "${DB_FILE}" ]; then
    echo "[Firefly III] Premier démarrage — initialisation de la base SQLite..."
    touch "${DB_FILE}"
    cd "${FIREFLY_DIR}"
    php artisan migrate --force
    php artisan firefly-iii:upgrade-database
    php artisan passport:install
    echo "[Firefly III] Base de données initialisée ✓"
fi

# 6. Permissions
chown -R www-data:www-data "${DATA_DIR}" 2>/dev/null || true
chown -R www-data:www-data "${FIREFLY_DIR}/storage" 2>/dev/null || true

echo "[Firefly III] Démarrage du serveur web..."

# Lancer php-fpm + nginx (entrypoint de l'image officielle)
exec /usr/local/bin/entrypoint.sh "$@"