# Mini-Heroku con DigitalOcean + Docker + Traefik + Portainer

Servidor personal que funciona como una plataforma tipo Heroku: despliega múltiples aplicaciones con HTTPS automático, panel de administración visual y CI/CD desde GitHub.

```
┌────────────────────────────────────────────────────────────┐
│                    DigitalOcean Droplet                     │
│                                                            │
│  Internet ──► Traefik (80/443) ──► hello.tudominio.com    │
│                    │           ──► api.tudominio.com       │
│                    │           ──► portainer.tudominio.com │
│                    │           ──► traefik.tudominio.com   │
│                    │                                       │
│               Red Docker "proxy"                           │
│                    │                                       │
│        ┌───────────┼───────────┐                          │
│     Portainer  App 1      App 2 ...                        │
└────────────────────────────────────────────────────────────┘
```

---

## 📋 Documentación

- **[Apps Desplegadas](DEPLOYED_APPS.md)** - Lista completa de aplicaciones activas con URLs, tecnologías y estado
- **[Medidas de Seguridad](../SECURITY_MEASURES.md)** - Guía de seguridad post-incidente y mejores prácticas

---

## Stack

| Componente | Función | URL |
|---|---|---|
| **Traefik v3** | Reverse proxy + SSL automático (Let's Encrypt) | `traefik.tudominio.com` |
| **Portainer CE** | Dashboard visual para gestionar Docker | `portainer.tudominio.com` |
| **GitHub Actions** | CI/CD: despliega en cada push a `main` | — |
| **Docker + Compose** | Runtime de contenedores | — |

---

## Estructura del repositorio

```
container-apps/
├── .github/
│   └── workflows/
│       └── deploy.yml          # CI/CD automático
├── traefik/
│   ├── docker-compose.yml      # Servicio Traefik
│   ├── traefik.yml             # Configuración estática
│   ├── config/
│   │   └── middlewares.yml     # Middlewares reutilizables
│   └── acme.json               # Certificados SSL (gitignored, crear en server)
├── portainer/
│   └── docker-compose.yml      # Servicio Portainer
├── apps/
│   └── hello-world/            # App de ejemplo (Node.js)
│       ├── Dockerfile
│       ├── docker-compose.yml
│       ├── app.js
│       └── package.json
├── scripts/
│   ├── setup-server.sh         # Setup inicial del Droplet
│   ├── deploy.sh               # Script de deploy
│   └── new-app.sh              # Crear estructura nueva app
├── Makefile                    # Comandos de conveniencia
├── .env.example                # Plantilla de variables de entorno
└── .gitignore
```

---

## Requisitos previos

- Cuenta en [DigitalOcean](https://digitalocean.com)
- Un dominio con DNS apuntando al Droplet
- Git instalado localmente

---

## 1. Crear el Droplet en DigitalOcean

**Especificaciones recomendadas:**

| Plan | vCPU | RAM | Disco | $/mes | Apps estimadas |
|------|------|-----|-------|-------|----------------|
| Basic | 1 | 1 GB | 25 GB | ~$6 | 2-3 apps ligeras |
| Basic | 1 | 2 GB | 50 GB | ~$12 | 5-8 apps |
| Basic | 2 | 4 GB | 80 GB | ~$24 | 10+ apps |

**Configuración:**
1. Imagen: **Ubuntu 22.04 LTS**
2. Datacenter: el más cercano a tus usuarios
3. Autenticación: **SSH Key** (obligatorio, no usar password)
4. Nombre del host: `mini-heroku` o como prefieras

**DNS:** Crea registros A en tu proveedor de dominio:
```
A    @              → IP_DEL_DROPLET
A    *              → IP_DEL_DROPLET   (wildcard para todos los subdominios)
```

O por separado:
```
A    traefik        → IP_DEL_DROPLET
A    portainer      → IP_DEL_DROPLET
A    hello          → IP_DEL_DROPLET
```

---

## 2. Setup inicial del servidor

Conecta por SSH y ejecuta el script de configuración:

```bash
ssh root@IP_DEL_DROPLET

# Clona el repositorio
git clone https://github.com/TU-USUARIO/container-apps.git /opt/container-apps
cd /opt/container-apps

# Ejecuta el setup (instala Docker, configura firewall, etc.)
bash scripts/setup-server.sh
```

El script hace:
- Actualiza el sistema
- Instala Docker y Git
- Configura UFW (firewall: puertos 22, 80, 443)
- Crea la red Docker `proxy`
- Crea `traefik/acme.json` con permisos correctos
- Deshabilita login SSH por contraseña

---

## 3. Configurar variables de entorno

```bash
cp /opt/container-apps/.env.example /opt/container-apps/.env
nano /opt/container-apps/.env
```

Rellena los valores:

```env
DOMAIN=tudominio.com
ACME_EMAIL=tu-email@ejemplo.com
TRAEFIK_DASHBOARD_AUTH=admin:$$apr1$$...
```

**Generar el hash de contraseña para el dashboard de Traefik:**

```bash
# Instala apache2-utils si no lo tienes
apt-get install -y apache2-utils

# Genera el hash (reemplaza 'TU_PASSWORD')
echo $(htpasswd -nb admin TU_PASSWORD) | sed -e s/\\$/\\$\\$/g
```

Copia el resultado y pégalo en `TRAEFIK_DASHBOARD_AUTH` en tu `.env`.

---

## 4. Iniciar la infraestructura

```bash
cd /opt/container-apps

# Iniciar Traefik
docker compose -f traefik/docker-compose.yml up -d

# Iniciar Portainer
docker compose -f portainer/docker-compose.yml up -d

# Verificar que todo corre
docker ps
```

Accede a:
- **Traefik Dashboard:** `https://traefik.tudominio.com` (usuario/contraseña del .env)
- **Portainer:** `https://portainer.tudominio.com` (crea una cuenta en el primer acceso)

---

## 5. Desplegar la app de ejemplo

```bash
cd /opt/container-apps

docker compose --project-directory . \
  -f apps/hello-world/docker-compose.yml up -d --build
```

Accede a `https://hello.tudominio.com` y deberías ver:

```json
{
  "message": "Hola desde hello-world!",
  "service": "hello-world",
  "timestamp": "2026-03-14T12:00:00.000Z"
}
```

---

## 6. Configurar CI/CD con GitHub Actions

### Secrets requeridos en GitHub

Ve a tu repositorio → **Settings → Secrets and variables → Actions** y añade:

| Secret | Valor |
|--------|-------|
| `DO_HOST` | IP de tu Droplet |
| `DO_USER` | `root` (o el usuario SSH) |
| `DO_SSH_KEY` | Contenido de tu clave privada SSH (`cat ~/.ssh/id_rsa`) |
| `DO_PORT` | `22` (puerto SSH, opcional) |

### Cómo funciona el CI/CD

```
push a main
    │
    ├─ cambios en traefik/** → redeploy Traefik
    ├─ cambios en portainer/** → redeploy Portainer
    └─ cambios en apps/** → rebuild + redeploy todas las apps
```

El workflow también se puede disparar **manualmente** desde GitHub:
- `Actions → Deploy a DigitalOcean → Run workflow`
- Especifica el target: `all`, `traefik`, `portainer`, `apps`, o `app hello-world`

---

## 7. Agregar una nueva aplicación

### Opción A: Script automático

```bash
bash scripts/new-app.sh mi-api api.tudominio.com 4000
```

### Opción B: Manual

Crea `apps/mi-api/docker-compose.yml`:

```yaml
services:
  mi-api:
    build: .
    container_name: mi-api
    restart: unless-stopped
    networks:
      - proxy
    environment:
      - PORT=4000
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.mi-api-http.entrypoints=http"
      - "traefik.http.routers.mi-api-http.rule=Host(`api.${DOMAIN}`)"
      - "traefik.http.routers.mi-api-http.middlewares=https-redirect@file"
      - "traefik.http.routers.mi-api.entrypoints=https"
      - "traefik.http.routers.mi-api.rule=Host(`api.${DOMAIN}`)"
      - "traefik.http.routers.mi-api.tls=true"
      - "traefik.http.routers.mi-api.tls.certresolver=letsencrypt"
      - "traefik.http.routers.mi-api.middlewares=secure-headers@file,rate-limit@file"
      - "traefik.http.services.mi-api.loadbalancer.server.port=4000"

networks:
  proxy:
    external: true
```

Haz commit y push → GitHub Actions desplegará automáticamente.

---

## Comandos útiles (Makefile)

Desde el servidor en `/opt/container-apps`:

```bash
make help           # Ver todos los comandos
make infra          # Iniciar Traefik + Portainer
make apps           # Desplegar todas las apps
make app-up APP=mi-api          # Desplegar una app específica
make app-down APP=mi-api        # Detener una app
make logs APP=hello-world       # Ver logs de una app
make ps             # Ver contenedores activos
make clean          # Detener todo y limpiar imágenes
```

---

## Middlewares disponibles para tus apps

Declarados en `traefik/config/middlewares.yml` y disponibles con `@file`:

| Middleware | Label | Descripción |
|---|---|---|
| `https-redirect@file` | Redirección HTTP→HTTPS | Siempre activo en routers HTTP |
| `secure-headers@file` | Cabeceras de seguridad | HSTS, XSS, Content-Type etc. |
| `rate-limit@file` | Rate limiting | 100 req/s con burst de 50 |
| `compress@file` | Compresión gzip | Reduce tamaño de respuestas |

---

## Solución de problemas

**Los certificados SSL no se generan:**
```bash
docker logs traefik
# Asegúrate de que el DNS apunta al Droplet y los puertos 80/443 están abiertos
ufw status
```

**Una app no aparece en Traefik:**
```bash
# Verifica que el contenedor está en la red 'proxy'
docker inspect <contenedor> | grep -A 20 Networks

# Verifica los labels
docker inspect <contenedor> | grep -A 30 Labels
```

**Reiniciar un servicio:**
```bash
docker compose --project-directory /opt/container-apps \
  -f traefik/docker-compose.yml restart
```

**Ver todos los logs:**
```bash
docker compose --project-directory /opt/container-apps \
  -f traefik/docker-compose.yml logs -f
```

---

## Seguridad

- Traefik corre con `no-new-privileges` 
- El socket Docker se monta en **solo lectura** en Traefik
- El dashboard de Traefik está protegido con Basic Auth
- Portainer usa su propio sistema de autenticación
- SSH solo acepta claves (no contraseñas)
- UFW activo con solo puertos 22, 80, 443 abiertos
- Let's Encrypt HTTPS en todos los servicios
- Cabeceras de seguridad aplicadas via middleware

---

## Costos estimados en DigitalOcean

| Recurso | Costo mensual |
|---------|---------------|
| Droplet 1GB RAM | ~$6/mes |
| Droplet 2GB RAM | ~$12/mes |
| IP flotante (opcional) | ~$4/mes |
| **Total** | **~$6–16/mes** |

vs. Heroku equivalente: $25–50+/mes por app

---

## Licencia

MIT
