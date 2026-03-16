#!/bin/bash
# ============================================================
# new-app.sh — Crea la estructura para una nueva aplicación
#
# Uso: bash scripts/new-app.sh mi-app mi-app.tudominio.com 3000
# ============================================================
set -euo pipefail

APP_NAME="${1:-}"
SUBDOMAIN="${2:-}"
PORT="${3:-3000}"

if [ -z "$APP_NAME" ] || [ -z "$SUBDOMAIN" ]; then
    echo "Uso: $0 <nombre-app> <subdominio> [puerto]"
    echo "Ej:  $0 mi-api api.tudominio.com 4000"
    exit 1
fi

APP_DIR="apps/$APP_NAME"

if [ -d "$APP_DIR" ]; then
    echo "ERROR: La carpeta $APP_DIR ya existe."
    exit 1
fi

echo "Creando app '$APP_NAME' en $APP_DIR..."
mkdir -p "$APP_DIR"

# docker-compose.yml
cat > "$APP_DIR/docker-compose.yml" << EOF
services:
  ${APP_NAME}:
    build: .
    container_name: ${APP_NAME}
    restart: unless-stopped
    networks:
      - proxy
    environment:
      - APP_NAME=${APP_NAME}
      - PORT=${PORT}
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.${APP_NAME}-http.entrypoints=http"
      - "traefik.http.routers.${APP_NAME}-http.rule=Host(\`${SUBDOMAIN}\`)"
      - "traefik.http.routers.${APP_NAME}-http.middlewares=https-redirect@file"
      - "traefik.http.routers.${APP_NAME}.entrypoints=https"
      - "traefik.http.routers.${APP_NAME}.rule=Host(\`${SUBDOMAIN}\`)"
      - "traefik.http.routers.${APP_NAME}.tls=true"
      - "traefik.http.routers.${APP_NAME}.tls.certresolver=letsencrypt"
      - "traefik.http.routers.${APP_NAME}.middlewares=secure-headers@file,rate-limit@file"
      - "traefik.http.services.${APP_NAME}.loadbalancer.server.port=${PORT}"

networks:
  proxy:
    external: true
EOF

# Dockerfile de ejemplo
cat > "$APP_DIR/Dockerfile" << 'EOF'
FROM node:20-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
EXPOSE 3000
USER node
CMD ["node", "app.js"]
EOF

echo "✓ App '$APP_NAME' creada en $APP_DIR"
echo ""
echo "Próximos pasos:"
echo "  1. Edita $APP_DIR/Dockerfile con tu imagen/lenguaje"
echo "  2. Añade el código de tu app en $APP_DIR/"
echo "  3. Haz commit y push → GitHub Actions lo desplegará automáticamente"
echo "  4. O despliega manualmente: bash scripts/deploy.sh app $APP_NAME"
