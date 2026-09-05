# ============================================================
# Plantilla: App React / Vue / cualquier SPA (Nginx)
# Build estático servido con Nginx
# ============================================================

# ── Etapa 1: Build ─────────────────────────────────────────
FROM node:20-alpine AS builder

WORKDIR /app
COPY package*.json ./
RUN npm ci

COPY . .

# Para Vue: npm run build → dist/
# Para React (Vite): npm run build → dist/
# Para React (CRA): npm run build → build/
RUN npm run build

# ── Etapa 2: Servidor Nginx (imagen mínima) ────────────────
FROM nginx:alpine

# Copia el build — ajusta la carpeta si usas CRA (build/) o Vite (dist/)
COPY --from=builder /app/dist /usr/share/nginx/html

# Config de Nginx para SPAs (router de cliente)
COPY nginx.conf /etc/nginx/conf.d/default.conf

RUN chown -R nginx:nginx /usr/share/nginx/html /var/cache/nginx /var/log/nginx \
    && touch /var/run/nginx.pid \
    && chown nginx:nginx /var/run/nginx.pid

USER nginx

EXPOSE 8080
CMD ["nginx", "-g", "daemon off;"]
