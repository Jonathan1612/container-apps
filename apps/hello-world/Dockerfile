FROM node:20-alpine

WORKDIR /app

# Copiar dependencias primero (cache de capas Docker)
COPY package*.json ./
RUN npm ci --only=production

# Copiar código fuente
COPY . .

EXPOSE 3000

# Ejecutar como usuario no-root
USER node

CMD ["node", "app.js"]
