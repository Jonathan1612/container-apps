#!/bin/bash
# ============================================================
# setup-server.sh — Configura un Droplet de DigitalOcean desde cero
# Probado en: Ubuntu 22.04 / 24.04 LTS
#
# Uso: bash scripts/setup-server.sh
# ============================================================
set -euo pipefail

REPO_URL="${REPO_URL:-}"      # Ej: https://github.com/tu-usuario/container-apps.git
INSTALL_DIR="/opt/container-apps"

echo "=================================================="
echo "  Mini-Heroku — Setup en DigitalOcean Droplet"
echo "=================================================="

# ── 1. Actualizar sistema ──────────────────────────────────
echo "[1/7] Actualizando sistema..."
apt-get update -qq && apt-get upgrade -y -qq

apt-get install -y -qq \
    curl \
    git \
    htop \
    ca-certificates \
    gnupg \
    lsb-release \
    fail2ban \
    ufw

# ── 2. Instalar Docker ─────────────────────────────────────
echo "[2/7] Instalando Docker..."
if ! command -v docker &>/dev/null; then
    curl -fsSL https://get.docker.com | sh
    systemctl enable docker
    systemctl start docker
    echo "   Docker instalado correctamente."
else
    echo "   Docker ya está instalado. Saltando."
fi

# ── 3. Configurar Firewall (UFW) ───────────────────────────
echo "[3/7] Configurando firewall UFW..."
ufw allow 22/tcp   comment 'SSH'
ufw allow 80/tcp   comment 'HTTP'
ufw allow 443/tcp  comment 'HTTPS'
ufw --force enable
echo "   Reglas: SSH(22), HTTP(80), HTTPS(443) permitidas."

# ── 4. Clonar repositorio ──────────────────────────────────
echo "[4/7] Configurando directorio de trabajo..."
mkdir -p "$INSTALL_DIR"

if [ -n "$REPO_URL" ]; then
    if [ ! -d "$INSTALL_DIR/.git" ]; then
        git clone "$REPO_URL" "$INSTALL_DIR"
        echo "   Repositorio clonado en $INSTALL_DIR"
    else
        echo "   Repositorio ya existe. Ejecutando git pull..."
        git -C "$INSTALL_DIR" pull origin main
    fi
else
    echo "   ADVERTENCIA: REPO_URL no definida. Copia los archivos manualmente a $INSTALL_DIR"
fi

# ── 5. Crear red Docker ────────────────────────────────────
echo "[5/7] Creando red Docker 'proxy'..."
docker network create proxy 2>/dev/null || echo "   La red 'proxy' ya existe."

# ── 6. Preparar acme.json para Let's Encrypt ──────────────
echo "[6/7] Preparando almacenamiento de certificados SSL..."
touch "$INSTALL_DIR/traefik/acme.json"
chmod 600 "$INSTALL_DIR/traefik/acme.json"
echo "   acme.json creado con permisos 600."

# ── 7. Configurar seguridad SSH ────────────────────────────
echo "[7/7] Endureciendo configuración SSH..."
# Deshabilitar login con password (solo claves SSH)
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
systemctl reload sshd

echo ""
echo "=================================================="
echo "  Setup completado!"
echo "=================================================="
echo ""
echo "PRÓXIMOS PASOS:"
echo ""
echo "  1. Copia .env.example a .env y rellena tus valores:"
echo "     cp $INSTALL_DIR/.env.example $INSTALL_DIR/.env"
echo "     nano $INSTALL_DIR/.env"
echo ""
echo "  2. Inicia la infraestructura:"
echo "     cd $INSTALL_DIR"
echo "     docker compose -f traefik/docker-compose.yml up -d"
echo "     docker compose -f portainer/docker-compose.yml up -d"
echo ""
echo "  3. Despliega tu primera app:"
echo "     docker compose --project-directory . -f apps/hello-world/docker-compose.yml up -d --build"
echo ""
echo "  4. Verifica que todo funciona:"
echo "     docker ps"
echo "     docker compose -f traefik/docker-compose.yml logs"
echo ""
