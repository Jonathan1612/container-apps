INSTALL_DIR ?= /opt/container-apps
COMPOSE     := docker compose --project-directory $(INSTALL_DIR)
APP         ?= hello-world

.PHONY: help setup network traefik portainer app-up app-down apps deploy clean logs

help: ## Muestra esta ayuda
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2}'

# ── Servidor ────────────────────────────────────────────────
setup: ## Prepara el servidor (ejecutar en el Droplet)
	bash scripts/setup-server.sh

network: ## Crea la red Docker 'proxy'
	docker network create proxy 2>/dev/null || true

# ── Infraestructura ─────────────────────────────────────────
traefik: network ## Inicia/actualiza Traefik
	$(COMPOSE) -f traefik/docker-compose.yml up -d

portainer: network ## Inicia/actualiza Portainer
	$(COMPOSE) -f portainer/docker-compose.yml up -d

infra: traefik portainer ## Inicia toda la infraestructura

# ── Aplicaciones ────────────────────────────────────────────
app-up: ## Despliega una app (APP=nombre, default: hello-world)
	$(COMPOSE) -f apps/$(APP)/docker-compose.yml up -d --build

app-down: ## Detiene una app (APP=nombre)
	$(COMPOSE) -f apps/$(APP)/docker-compose.yml down

apps: ## Despliega todas las apps
	@for dir in apps/*/; do \
		if [ -f "$$dir/docker-compose.yml" ]; then \
			app=$$(basename "$$dir"); \
			echo "Desplegando $$app..."; \
			$(COMPOSE) -f "$$dir/docker-compose.yml" up -d --build; \
		fi \
	done

new-app: ## Crea estructura para nueva app (APP=nombre SUBDOMAIN=sub.dominio.com)
	bash scripts/new-app.sh $(APP) $(SUBDOMAIN) $(PORT)

# ── Deploy ──────────────────────────────────────────────────
deploy: ## Deploy completo (git pull + todo)
	bash scripts/deploy.sh all

deploy-app: ## Deploy de una app (APP=nombre)
	bash scripts/deploy.sh app $(APP)

# ── Utilidades ──────────────────────────────────────────────
logs: ## Ver logs de un servicio (APP=traefik|portainer|nombre-app)
	docker logs -f $(APP)

ps: ## Ver todos los contenedores corriendo
	docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

clean: ## Detiene TODOS los servicios y limpia imágenes
	@echo "Deteniendo todas las apps..."
	@for dir in apps/*/; do \
		if [ -f "$$dir/docker-compose.yml" ]; then \
			$(COMPOSE) -f "$$dir/docker-compose.yml" down 2>/dev/null || true; \
		fi \
	done
	$(COMPOSE) -f portainer/docker-compose.yml down 2>/dev/null || true
	$(COMPOSE) -f traefik/docker-compose.yml down 2>/dev/null || true
	docker image prune -f
