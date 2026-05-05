# 🌐 Aplicaciones Desplegadas

Documentación de las aplicaciones actualmente corriendo en el servidor **104.248.126.117**

**Última actualización:** 5 de mayo de 2026

---

## 📋 Resumen de Aplicaciones Activas

| Aplicación | Frontend | Backend | Estado | Repositorio |
|------------|----------|---------|--------|-------------|
| **jacm-portafolio** | https://jacm.com.mx | — | ✅ Activo | [Jonathan1612/jacm-portafolio](https://github.com/Jonathan1612/jacm-portafolio) |
| **plantillas-app** | https://plantillas.jacm.com.mx | https://api.plantillas.jacm.com.mx | ✅ Activo | [Jonathan1612/plantillas-app](https://github.com/Jonathan1612/plantillas-app) |
| **jacm-time-record** | https://time.jacm.com.mx | https://time-api.jacm.com.mx | ✅ Activo | [Jonathan1612/jacm-time-record](https://github.com/Jonathan1612/jacm-time-record) |

---

## 🖥️ Detalles de Cada Aplicación

### 1. jacm-portafolio

**Descripción:** Sitio web de portafolio personal

**URLs:**
- 🌐 **Frontend:** https://jacm.com.mx
- 🌐 **Alternativa:** https://www.jacm.com.mx (redirige a jacm.com.mx)

**Tecnología:**
- Framework: Next.js 15.2.2
- Runtime: Node.js 20
- Puerto interno: 3000

**Información de Deployment:**
- Rama: `main`
- Contenedor: `jacm-portafolio-portfolio-1`
- Directorio: `/opt/apps/jacm-portafolio`
- Estado: Up 51 minutos (redeployado post-incidente de seguridad)

**SSL:** ✅ Let's Encrypt (auto-renovado)

**Seguridad:**
- ✅ Content Security Policy habilitado
- ✅ Auditoría de seguridad automática (GitHub Actions)
- ✅ Headers de seguridad: X-Frame-Options, CSP, etc.

---

### 2. plantillas-app

**Descripción:** Aplicación de gestión de plantillas (desarrollo)

**URLs:**
- 🌐 **Frontend:** https://plantillas.jacm.com.mx
- 🔌 **Backend API:** https://api.plantillas.jacm.com.mx
- 🗄️ **Base de datos:** PostgreSQL (interna)

**Tecnología:**
- Frontend: Next.js
- Backend: Node.js/Express
- Base de datos: PostgreSQL
- Puertos internos: 3000 (frontend), 4000 (backend), 5432 (db)

**Información de Deployment:**
- Rama: `dev`
- Contenedores:
  - `plantillas-app-frontend-1`
  - `plantillas-app-backend-1`
  - `plantillas-app-db-1` (healthy)
- Directorio: `/opt/apps/plantillas-app`
- Estado: Up 6 semanas

**SSL:** ✅ Let's Encrypt (auto-renovado)

**Archivos importantes:**
- Almacenamiento: `/opt/apps/plantillas-app/backend/storage`
- Templates públicos: `/opt/apps/plantillas-app/public/templates`

---

### 3. jacm-time-record

**Descripción:** Sistema de registro y gestión de horas de trabajo

**URLs:**
- 🌐 **Frontend:** https://time.jacm.com.mx
- 🔌 **Backend API:** https://time-api.jacm.com.mx
- 🗄️ **Base de datos:** MongoDB (interna)

**Tecnología:**
- Frontend: Next.js
- Backend: Node.js/Express
- Base de datos: MongoDB
- Puertos internos: 3000 (frontend), 5000 (backend), 27017 (mongodb)

**Información de Deployment:**
- Rama: `main`
- Contenedores:
  - `jacm-time-record-frontend-1` (healthy)
  - `jacm-time-record-backend-1` (healthy)
  - `jacm-time-record-mongodb-1` (unhealthy - revisar)
- Directorio: `/opt/apps/jacm-time-record`
- Estado: Up 6 semanas

**SSL:** ✅ Let's Encrypt (auto-renovado)

**Middlewares de seguridad:**
- ✅ Secure headers
- ✅ Rate limiting

**⚠️ Nota:** MongoDB aparece como `unhealthy` - revisar logs si hay problemas de conexión

---

## 🔧 Infraestructura

### Reverse Proxy: Traefik

**URL Dashboard:** http://104.248.126.117:8080 (solo accesible localmente)

**Características:**
- ✅ SSL automático con Let's Encrypt
- ✅ HTTP → HTTPS redirect
- ✅ Renovación automática de certificados
- ✅ Logs de acceso y errores

**Puertos:**
- 80 (HTTP)
- 443 (HTTPS)

---

### Administración: Portainer

**URL:** Acceso local únicamente

**Estado:** Up 7 semanas

**Uso:** Gestión visual de contenedores Docker

---

## 🚀 Deployment

Cada aplicación se despliega automáticamente cuando hay push a su rama correspondiente mediante GitHub Actions.

**Comando manual de deployment:**
```bash
ssh root@104.248.126.117
cd /opt/container-apps
bash scripts/deploy.sh app <nombre-app>
```

Ejemplos:
```bash
bash scripts/deploy.sh app jacm-portafolio
bash scripts/deploy.sh app plantillas-app
bash scripts/deploy.sh app jacm-time-record
```

---

## 🗄️ Base de Datos de Registros DNS

| Dominio/Subdominio | Tipo | Valor | TTL | Registrar |
|--------------------|------|-------|-----|-----------|
| jacm.com.mx | A | 104.248.126.117 | 600 | GoDaddy |
| www.jacm.com.mx | A | 104.248.126.117 | 600 | GoDaddy |
| plantillas.jacm.com.mx | A | 104.248.126.117 | 600 | GoDaddy |
| api.plantillas.jacm.com.mx | A | 104.248.126.117 | 600 | GoDaddy |
| time.jacm.com.mx | A | 104.248.126.117 | 600 | GoDaddy |
| time-api.jacm.com.mx | A | 104.248.126.117 | 600 | GoDaddy |

**Nameservers:**
- ns77.domaincontrol.com
- ns78.domaincontrol.com

---

## 📊 Estado del Servidor

**Servidor:** DigitalOcean Droplet  
**IP:** 104.248.126.117  
**OS:** Ubuntu 24.04 LTS  
**Kernel:** 6.8.0-71-generic x86_64  

**Recursos:**
- Memoria: 48% de uso
- Disco: 77% de 23.17GB usado
- Uptime: 6+ semanas

---

## 🔐 Seguridad

### Incidente de Seguridad - 5 mayo 2026

**Estado:** ✅ Resuelto

El sitio jacm.com.mx fue comprometido con código JavaScript malicioso. Se realizó:
- ✅ Limpieza completa del contenedor
- ✅ Redespliegue desde código limpio
- ✅ Implementación de medidas de seguridad

Ver detalles completos en: [SECURITY_MEASURES.md](../SECURITY_MEASURES.md)

### Medidas de Seguridad Activas

- ✅ Content Security Policy en jacm-portafolio
- ✅ GitHub Actions para auditoría de seguridad
- ✅ Rate limiting en jacm-time-record
- ✅ SSL/TLS en todas las aplicaciones
- ⏳ Fail2Ban (pendiente de configurar)
- ⏳ Backups automáticos (pendiente de configurar)

---

## 📝 Mantenimiento

### Tareas Regulares

**Diarias:**
- Revisar logs de errores: `docker logs <container-name>`
- Verificar estado de contenedores: `docker ps -a`

**Semanales:**
- Auditoría de seguridad (automática via GitHub Actions)
- Revisar uso de disco: `df -h`
- Revisar memoria: `free -h`

**Mensuales:**
- Actualizar dependencias de npm
- Revisar y limpiar logs antiguos
- Verificar backups
- Revisar certificados SSL (auto-renovados por Let's Encrypt)

---

## 🆘 Troubleshooting

### App no responde

```bash
# Ver logs del contenedor
docker logs <container-name>

# Reiniciar app específica
cd /opt/apps/<app-name>
docker-compose restart

# Redesplegar completamente
cd /opt/container-apps
bash scripts/deploy.sh app <app-name>
```

### Verificar SSL

```bash
# Verificar certificados
ssh root@104.248.126.117
docker exec traefik cat /letsencrypt/acme.json | jq
```

### Ver logs de Traefik

```bash
docker logs traefik
docker logs traefik -f  # Modo follow
```

---

## 📞 Contactos

**Administrador del servidor:** Jonathan  
**Proveedor:** DigitalOcean  
**Registrar de dominios:** GoDaddy

---

**Nota:** Este documento debe actualizarse cada vez que se agregue, modifique o elimine una aplicación.
