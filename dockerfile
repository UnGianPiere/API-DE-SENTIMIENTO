# Usa una imagen base de Python
FROM python:3.11-slim
# Establece el directorio de trabajo dentro del contenedor
WORKDIR /app

# Copia el archivo de requisitos al contenedor
COPY requirements.txt .

# Instala las dependencias
RUN pip install --no-cache-dir -r requirements.txt

# Descarga el modelo de spaCy
RUN python -m spacy download es_core_news_sm

# Copia el código de la aplicación al contenedor
COPY app/ /app

# Expone el puerto en el que la aplicación correrá
EXPOSE 8000

# Comando para ejecutar la aplicación
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
