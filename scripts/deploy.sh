#!/bin/bash
# ============================================================
# deploy.sh — Despliega servicios en el servidor
#
# Las apps viven en sus propios repositorios Git.
# Este script lee apps.yml y clona/actualiza cada uno.
#
# Uso:
#   bash scripts/deploy.sh                  # Despliega todo
#   bash scripts/deploy.sh traefik          # Solo Traefik
#   bash scripts/deploy.sh portainer        # Solo Portainer
#   bash scripts/deploy.sh apps             # Todas las apps (desde apps.yml)
#   bash scripts/deploy.sh app mi-api       # Una app específica
# ============================================================
set -euo pipefail

INSTALL_DIR="/opt/container-apps"
APPS_DIR="/opt/apps"          # Directorio donde se clonan los repos de las apps
APPS_MANIFEST="$INSTALL_DIR/apps.yml"

# ── Dependencias mínimas ───────────────────────────────────
if ! command -v python3 &>/dev/null; then
    apt-get install -y -qq python3 2>/dev/null || true
fi

# Parsear apps.yml sin dependencias externas (python3 está en Ubuntu por defecto)
parse_apps() {
    python3 - "$APPS_MANIFEST" <<'PYEOF'
import sys, re

with open(sys.argv[1]) as f:
    content = f.read()

# Parseo simple de YAML de lista plana (no requiere PyYAML)
apps = []
current = {}
for line in content.splitlines():
    line = line.rstrip()
    m = re.match(r'\s+-\s+name:\s+(.+)', line)
    if m:
        if current:
            apps.append(current)
        current = {'name': m.group(1).strip(), 'branch': 'main', 'enabled': 'true'}
        continue
    for key in ('repo', 'branch', 'enabled'):
        m = re.match(rf'\s+{key}:\s+(.+)', line)
        if m:
            current[key] = m.group(1).strip().strip('"\'')

if current:
    apps.append(current)

for app in apps:
    if app.get('enabled', 'true').lower() == 'true':
        print(f"{app['name']}|{app.get('repo','')}|{app.get('branch','main')}")
PYEOF
}

# ── Infraestructura ────────────────────────────────────────
deploy_traefik() {
    echo "→ Desplegando Traefik..."
    docker compose --project-directory "$INSTALL_DIR" \
        -f "$INSTALL_DIR/traefik/docker-compose.yml" up -d
}

deploy_portainer() {
    echo "→ Desplegando Portainer..."
    docker compose --project-directory "$INSTALL_DIR" \
        -f "$INSTALL_DIR/portainer/docker-compose.yml" up -d
}

# ── Apps desde sus repos Git ───────────────────────────────
sync_and_deploy_app() {
    local name="$1"
    local repo="$2"
    local branch="${3:-main}"
    local app_dir="$APPS_DIR/$name"

    echo ""
    echo "┌─ App: $name"
    echo "│  Repo:   $repo"
    echo "│  Branch: $branch"

    mkdir -p "$APPS_DIR"

    if [ ! -d "$app_dir/.git" ]; then
        echo "│  Clonando por primera vez..."
        git clone --branch "$branch" "$repo" "$app_dir"
    else
        echo "│  Actualizando..."
        git -C "$app_dir" fetch origin
        git -C "$app_dir" checkout "$branch"
        git -C "$app_dir" pull origin "$branch"
    fi

    if [ ! -f "$app_dir/docker-compose.yml" ]; then
        echo "│  ADVERTENCIA: No se encontró docker-compose.yml en $app_dir"
        echo "│  Asegúrate de que el repo tenga un docker-compose.yml con labels de Traefik."
        echo "└─ Saltando $name"
        return
    fi

    echo "│  Construyendo y desplegando..."
    # Arma los args de env-file solo si el archivo existe
    local compose_env_args=()
    local env_file="$app_dir/.env"
    if [ ! -f "$env_file" ]; then
        env_file="$INSTALL_DIR/.env"
    fi
    if [ -f "$env_file" ]; then
        compose_env_args=("--env-file" "$env_file")
    fi

    # Pull de imágenes pre-compiladas; si no existen en registry, build local
    if docker compose "${compose_env_args[@]}" \
        -f "$app_dir/docker-compose.yml" \
        pull --quiet 2>/dev/null; then
        docker compose "${compose_env_args[@]}" \
            -f "$app_dir/docker-compose.yml" \
            up -d --no-build --remove-orphans --force-recreate
    else
        docker compose "${compose_env_args[@]}" \
            -f "$app_dir/docker-compose.yml" \
            up -d --build --remove-orphans --force-recreate
    fi

    echo "└─ $name desplegado correctamente"
}

deploy_app_by_name() {
    local target_name="$1"
    local found=0

    while IFS='|' read -r name repo branch; do
        if [ "$name" = "$target_name" ]; then
            sync_and_deploy_app "$name" "$repo" "$branch"
            found=1
            break
        fi
    done < <(parse_apps)

    if [ "$found" -eq 0 ]; then
        echo "ERROR: App '$target_name' no encontrada en apps.yml o está desactivada."
        exit 1
    fi
}

deploy_all_apps() {
    echo "→ Desplegando todas las apps desde apps.yml..."
    local count=0

    while IFS='|' read -r name repo branch; do
        sync_and_deploy_app "$name" "$repo" "$branch"
        count=$((count + 1))
    done < <(parse_apps)

    echo ""
    echo "→ $count app(s) desplegada(s)."
}

# ── Pull del repositorio de infraestructura ────────────────
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Iniciando deploy..."
cd "$INSTALL_DIR"
git pull origin "$(git rev-parse --abbrev-ref HEAD)"

# ── Ejecutar deploy según argumentos ──────────────────────
TARGET="${1:-all}"

case "$TARGET" in
    all)
        deploy_traefik
        deploy_portainer
        deploy_all_apps
        ;;
    traefik)
        deploy_traefik
        ;;
    portainer)
        deploy_portainer
        ;;
    apps)
        deploy_all_apps
        ;;
    app)
        if [ -z "${2:-}" ]; then
            echo "ERROR: Especifica el nombre de la app. Ej: deploy.sh app mi-api"
            exit 1
        fi
        deploy_app_by_name "$2"
        ;;
    *)
        echo "ERROR: Objetivo desconocido '$TARGET'"
        echo "Uso: deploy.sh [all|traefik|portainer|apps|app <nombre>]"
        exit 1
        ;;
esac

# ── Limpiar imágenes no usadas ─────────────────────────────
echo ""
echo "→ Limpiando imágenes Docker no utilizadas..."
docker image prune -f

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Deploy completado!"
