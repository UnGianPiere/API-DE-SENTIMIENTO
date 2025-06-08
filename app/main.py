import spacy
import pytextrank
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from transformers import AutoTokenizer, AutoModelForSequenceClassification
import torch
import os

# Inicializar FastAPI
app = FastAPI()

# Configurar CORS para permitir acceso desde cualquier origen
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Variables globales para los modelos
tokenizer = None
model = None
nlp = None

@app.on_event("startup")
async def load_models():
    global tokenizer, model, nlp
    try:
        # Cargar modelo local de sentimiento
        model_path = os.path.join(os.path.dirname(__file__), "modelo_roberta")
        
        # Intentar cargar el modelo primero
        model = AutoModelForSequenceClassification.from_pretrained(
            model_path,
            local_files_only=True,
            trust_remote_code=True
        )
        
        # Luego cargar el tokenizer con la configuración específica
        tokenizer = AutoTokenizer.from_pretrained(
            model_path,
            local_files_only=True,
            trust_remote_code=True,
            use_fast=False  # Usar el tokenizer lento pero más estable
        )
        
        # Cargar modelo spaCy
        nlp = spacy.load("es_core_news_sm")
        nlp.add_pipe("textrank")
        print("Modelos cargados exitosamente")
    except Exception as e:
        print(f"Error al cargar los modelos: {str(e)}")
        raise e

# Mapeo etiquetas del modelo a términos amigables
mapping = {
    "negative": "Negativo",
    "neutral": "Crítico",
    "positive": "Positivo"
}

# Artículos comunes para limpiar frases clave
articulos = {"el", "la", "los", "las", "un", "una", "unos", "unas"}

class ComentarioEntrada(BaseModel):
    comentario: str

def limpiar_articulos(frase):
    palabras = frase.split()
    if palabras and palabras[0].lower() in articulos:
        palabras.pop(0)
    return " ".join(palabras)

def extraer_palabras_clave(texto):
    doc = nlp(texto)
    keywords = []
    for phrase in doc._.phrases[:3]:
        kw_limpia = limpiar_articulos(phrase.text)
        if kw_limpia:
            keywords.append(kw_limpia)
    if not keywords:
        keywords = ["(sin palabras clave)"]
    return keywords

def analizar_sentimiento(comentario):
    inputs = tokenizer(comentario, return_tensors="pt", truncation=True, padding=True, max_length=512)
    outputs = model(**inputs)
    probs = torch.softmax(outputs.logits, dim=1)[0]
    idx = torch.argmax(probs).item()
    etiqueta_modelo = model.config.id2label[idx]
    etiqueta = mapping.get(etiqueta_modelo, etiqueta_modelo)
    confianza = float(probs[idx])
    return etiqueta, round(confianza, 2)

@app.post("/analizar")
def analizar_comentario(data: ComentarioEntrada):
    comentario = data.comentario.strip()
    if not comentario or len(comentario.split()) < 3:
        return {"error": "Comentario muy corto o vacío. Proporcione una oración más descriptiva."}

    etiqueta, confianza = analizar_sentimiento(comentario)
    palabras_clave = extraer_palabras_clave(comentario)

    return {
        "sentimiento": etiqueta,
        "confianza": confianza,
        "palabras_clave": palabras_clave
    }

@app.get("/ping")
def ping():
    return "OK"

