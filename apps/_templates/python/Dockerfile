# ============================================================
# Plantilla: App Python / FastAPI / Flask / Django
# ============================================================
FROM python:3.12-slim

WORKDIR /app

# Instalar dependencias primero (cache de capas)
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

RUN useradd --create-home --shell /usr/sbin/nologin appuser \
    && chown -R appuser:appuser /app

USER appuser

EXPOSE 8000

# Cambia el comando según tu framework:
#   FastAPI:  uvicorn main:app --host 0.0.0.0 --port 8000
#   Flask:    gunicorn -b 0.0.0.0:8000 app:app
#   Django:   gunicorn -b 0.0.0.0:8000 mi_proyecto.wsgi:application
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
