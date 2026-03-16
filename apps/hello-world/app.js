const express = require('express');

const app = express();
const PORT = process.env.PORT || 3000;
const APP_NAME = process.env.APP_NAME || 'hello-world';

app.get('/', (req, res) => {
  res.json({
    message: `Hola desde ${APP_NAME}!`,
    service: APP_NAME,
    timestamp: new Date().toISOString(),
    uptime: `${Math.floor(process.uptime())}s`,
  });
});

app.get('/health', (_req, res) => {
  res.json({ status: 'healthy', service: APP_NAME });
});

app.listen(PORT, () => {
  console.log(`[${APP_NAME}] Servidor corriendo en puerto ${PORT}`);
});
