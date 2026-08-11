#!/bin/bash
set -e

# ==============================================================================
# Firefly III HA Add-on — Script d'init + démarrage
# ==============================================================================

DATA_DIR="/data"
DB_FILE="${DATA_DIR}/database.sqlite"
UPLOAD_DIR="${DATA_DIR}/uploads"
APP_KEY_FILE="${DATA_DIR}/app_key.txt"
FIREFLY_DIR="/var/www/html"

mkdir -p "${DATA_DIR}" "${UPLOAD_DIR}"

# 1. APP_KEY persistant (32 bytes base64 = 44 chars)
if [ ! -f "${APP_KEY_FILE}" ]; then
    echo "[Firefly III] Génération d'un APP_KEY aléatoire (premier démarrage)..."
    APP_KEY="base64:$(cat /dev/urandom | head -c 32 | base64 | tr -d '\n' | head -c 44)"
    echo "${APP_KEY}" > "${APP_KEY_FILE}"
fi
APP_KEY=$(cat "${APP_KEY_FILE}")
export APP_KEY

# 2. Variables d'environnement
export FIREFLY_III_ENV=production
export DB_CONNECTION=sqlite
export DB_DATABASE="${DB_FILE}"
export APP_URL=http://localhost
export SHOW_ERROR_MESSAGES=false
export APP_DEBUG=false
export LOG_CHANNEL=stack

# 3. Écrire le .env
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

# 4. Préparer uploads
mkdir -p "${FIREFLY_DIR}/storage/upload"
chown -R www-data:www-data "${UPLOAD_DIR}" 2>/dev/null || true

# 5. Créer la DB si elle n'existe pas
if [ ! -f "${DB_FILE}" ]; then
    echo "[Firefly III] Premier démarrage — initialisation de la base SQLite..."
    mkdir -p "$(dirname "${DB_FILE}")"
    touch "${DB_FILE}"
fi

# 6. Permissions
chown -R www-data:www-data "${DATA_DIR}" 2>/dev/null || true
chown -R www-data:www-data "${FIREFLY_DIR}/storage" 2>/dev/null || true
chmod -R 775 "${FIREFLY_DIR}/storage" 2>/dev/null || true

# 7. Générer nginx.conf depuis le template
if [ -f /etc/nginx/nginx.conf.template ] && [ ! -f /etc/nginx/nginx.conf ]; then
    export NGINX_ERROR_LOG="${NGINX_ERROR_LOG:-/dev/stderr}"
    export LOG_OUTPUT_LEVEL="${LOG_OUTPUT_LEVEL:-warn}"
    export NGINX_SERVER_TOKENS="${NGINX_SERVER_TOKENS:-off}"
    export NGINX_ACCESS_LOG="${NGINX_ACCESS_LOG:-/dev/stdout}"
    export NGINX_CLIENT_MAX_BODY_SIZE="${NGINX_CLIENT_MAX_BODY_SIZE:-50m}"
    export HEALTHCHECK_PATH="${HEALTHCHECK_PATH:-/health}"
    envsubst '${NGINX_ERROR_LOG} ${LOG_OUTPUT_LEVEL} ${NGINX_SERVER_TOKENS} ${NGINX_ACCESS_LOG} ${NGINX_CLIENT_MAX_BODY_SIZE} ${HEALTHCHECK_PATH}' < /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf
fi

echo "[Firefly III] Démarrage du serveur web..."

# 8. Démarrer php-fpm + nginx (le template a déjà "daemon off;")
php-fpm --allow-to-run-as-root -D
exec nginx