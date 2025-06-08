FROM python:3.8-slim

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

# Copiar toda la aplicación incluyendo el modelo
COPY ./app ./app

# Verificar que los archivos del modelo existan
RUN ls -la /app/app/modelo_roberta/

EXPOSE 8000

# Usar un script de inicio
COPY start.sh .
RUN chmod +x start.sh
CMD ["./start.sh"]
