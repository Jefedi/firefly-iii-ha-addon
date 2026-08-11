#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
# ==============================================================================
# Firefly III HA Add-on — Initialisation
# ==============================================================================

set -e

export FIREFLY_III_ENV=production
export DB_CONNECTION=sqlite

# /data est le volume persistant HA
DATA_DIR="/data"
DB_FILE="${DATA_DIR}/database.sqlite"
UPLOAD_DIR="${DATA_DIR}/uploads"
APP_KEY_FILE="${DATA_DIR}/app_key.txt"

mkdir -p "${DATA_DIR}" "${UPLOAD_DIR}"

# 1. Générer un APP_KEY persistant au premier démarrage
if [ ! -f "${APP_KEY_FILE}" ]; then
    bashio::log.info "Génération d'un APP_KEY aléatoire (premier démarrage)..."
    APP_KEY=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | head -c 32)
    echo "base64:${APP_KEY}" > "${APP_KEY_FILE}"
fi
export APP_KEY
APP_KEY=$(cat "${APP_KEY_FILE}")

# 2. Écrire le fichier .env de Firefly III
FIREFLY_DIR="/var/www/html"
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

# 3. Lier le dossier uploads vers /data pour persistance
if [ -d "${FIREFLY_DIR}/storage/upload" ] && [ ! -L "${FIREFLY_DIR}/storage/upload" ]; then
    # Migrer les uploads existants vers /data
    cp -a "${FIREFLY_DIR}/storage/upload/." "${UPLOAD_DIR}/" 2>/dev/null || true
    rm -rf "${FIREFLY_DIR}/storage/upload"
fi
ln -sf "${UPLOAD_DIR}" "${FIREFLY_DIR}/storage/upload"

# 4. Lier la DB SQLite vers /data
if [ -f "${FIREFLY_DIR}/storage/db/database.sqlite" ] && [ ! -L "${FIREFLY_DIR}/storage/db/database.sqlite" ]; then
    cp -a "${FIREFLY_DIR}/storage/db/database.sqlite" "${DB_FILE}" 2>/dev/null || true
fi
mkdir -p "${FIREFLY_DIR}/storage/db"
ln -sf "${DB_FILE}" "${FIREFLY_DIR}/storage/db/database.sqlite"

# 5. Premier démarrage = migrations + init
if [ ! -f "${DB_FILE}" ] || [ ! -s "${DB_FILE}" ]; then
    bashio::log.info "Premier démarrage — initialisation de la base SQLite..."
    touch "${DB_FILE}"
    cd "${FIREFLY_DIR}"
    php artisan migrate --force
    php artisan firefly-iii:upgrade-database
    php artisan passport:install
    bashio::log.info "Base de données initialisée ✓"
fi

# 6. Permissions
chown -R www-data:www-data "${DATA_DIR}" 2>/dev/null || true
chown -R www-data:www-data "${FIREFLY_DIR}/storage" 2>/dev/null || true

bashio::log.info "Firefly III prêt — démarrage du serveur web..."