FROM python:3.8-slim

# Establecer variables de entorno
ENV PORT=8000
ENV HOST=0.0.0.0
ENV TRANSFORMERS_CACHE=/app/cache
ENV PYTHONUNBUFFERED=1

# Instalar dependencias del sistema
RUN apt-get update && apt-get install -y \
    build-essential gcc g++ curl ca-certificates git \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copiar requirements e instalar dependencias
COPY requirements.txt .

# Actualizar pip e instalar dependencias
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Descargar spaCy model
RUN python -m spacy download es_core_news_sm

# Crear y configurar directorio para cache
RUN mkdir -p /app/cache && \
    chmod -R 777 /app/cache

# Copiar el código de la aplicación
COPY ./app ./app

# Exponer el puerto
EXPOSE 8000

# Comando para iniciar la aplicación
CMD uvicorn app.main:app --host ${HOST} --port ${PORT}

EXPOSE 8000

# Usar un script de inicio
COPY start.sh .
RUN chmod +x start.sh
CMD ["./start.sh"]
