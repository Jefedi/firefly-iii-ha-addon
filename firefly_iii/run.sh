#!/bin/bash
set -e

# ==============================================================================
# Firefly III HA Add-on — Script d'init + démarrage
# Surcharge l'entrypoint de fireflyiii/core pour ajouter l'init HA
# ==============================================================================

DATA_DIR="/data"
DB_FILE="${DATA_DIR}/database.sqlite"
UPLOAD_DIR="${DATA_DIR}/uploads"
APP_KEY_FILE="${DATA_DIR}/app_key.txt"
FIREFLY_DIR="/var/www/html"

mkdir -p "${DATA_DIR}" "${UPLOAD_DIR}"

# 1. APP_KEY persistant
if [ ! -f "${APP_KEY_FILE}" ]; then
    echo "[Firefly III] Génération d'un APP_KEY aléatoire (premier démarrage)..."
    # Laravel需要一个32字节的密钥，base64编码后是44个字符
    APP_KEY="base64:$(cat /dev/urandom | head -c 32 | base64 | tr -d '\n' | head -c 44)"
    echo "${APP_KEY}" > "${APP_KEY_FILE}"
fi
APP_KEY=$(cat "${APP_KEY_FILE}")
export APP_KEY

# 2. Variables d'environnement pour Firefly III
export FIREFLY_III_ENV=production
export DB_CONNECTION=sqlite
export DB_DATABASE="${DB_FILE}"
export APP_URL=http://localhost
export SHOW_ERROR_MESSAGES=false
export APP_DEBUG=false
export LOG_CHANNEL=stack

# 3. Écrire le .env (au cas où certains scripts le liraient)
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

# 4. Préparer le dossier uploads (sans rm -rf qui peut échouer)
mkdir -p "${FIREFLY_DIR}/storage/upload"
chown -R www-data:www-data "${UPLOAD_DIR}" 2>/dev/null || true

# 5. Créer la DB SQLite si elle n'existe pas
if [ ! -f "${DB_FILE}" ]; then
    echo "[Firefly III] Premier démarrage — initialisation de la base SQLite..."
    mkdir -p "$(dirname "${DB_FILE}")"
    touch "${DB_FILE}"
fi

# 6. Permissions
chown -R www-data:www-data "${DATA_DIR}" 2>/dev/null || true
chown -R www-data:www-data "${FIREFLY_DIR}/storage" 2>/dev/null || true
chmod -R 775 "${FIREFLY_DIR}/storage" 2>/dev/null || true

echo "[Firefly III] Démarrage du serveur web..."

# Générer nginx.conf depuis le template (l'entrypoint original le fait normalement)
if [ -f /etc/nginx/nginx.conf.template ] && [ ! -f /etc/nginx/nginx.conf ]; then
    # Définir les variables par défaut si absentes
    export NGINX_ERROR_LOG="${NGINX_ERROR_LOG:-/dev/stderr}"
    export LOG_OUTPUT_LEVEL="${LOG_OUTPUT_LEVEL:-warn}"
    export NGINX_SERVER_TOKENS="${NGINX_SERVER_TOKENS:-off}"
    export NGINX_ACCESS_LOG="${NGINX_ACCESS_LOG:-/dev/stdout}"
    export NGINX_CLIENT_MAX_BODY_SIZE="${NGINX_CLIENT_MAX_BODY_SIZE:-50m}"
    export HEALTHCHECK_PATH="${HEALTHCHECK_PATH:-/health}"
    envsubst < /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf
fi

# Démarrer php-fpm + nginx
php-fpm --allow-to-run-as-root -D
exec nginx -g 'daemon off;'