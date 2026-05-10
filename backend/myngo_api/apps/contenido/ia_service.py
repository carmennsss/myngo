"""Servicio de validación de contenido mediante IA bilingüe (ESP/ENG).

Utiliza modelos de Hugging Face con sistema de reintento y un filtro local
de emergencia para asegurar la moderación incluso si la API falla.
"""

import time
import requests
from django.conf import settings

# Modelos multilingües (Inglés + Español + Otros)
API_URLS = [
    "https://api-inference.huggingface.co/models/unitary/multilingual-toxic-xlm-roberta",
    "https://api-inference.huggingface.co/models/Hate-speech-CNERG/dehatebert-mono-spanish"
]

# Lista de seguridad bilingüe (Fallback si la IA falla)
PALABRAS_PROHIBIDAS = [
    # Español
    'puto', 'puta', 'mierda', 'cabron', 'cabrona', 'maricon', 'gilipollas', 
    'pendejo', 'pendeja', 'zorra', 'maldito', 'maldita', 'estupido', 'estupida',
    'idiota', 'subnormal', 'follar', 'odio', 'matar', 'muere', 'hijo de puta',
    # Inglés
    'fuck', 'shit', 'asshole', 'bitch', 'bastard', 'idiot', 'stupid', 'hate',
    'kill', 'die', 'dick', 'pussy', 'faggot', 'nigger', 'motherfucker'
]

def _get_headers():
    """Devuelve las cabeceras HTTP."""
    hf_token = getattr(settings, 'HUGGING_FACE_TOKEN', '') or ''
    if hf_token and hf_token not in ('', 'hf_placeholder'):
        return {"Authorization": f"Bearer {hf_token}"}
    return {}

def _normalize_predictions(resultado):
    """Normaliza la respuesta de la API."""
    if not resultado: return []
    if isinstance(resultado, dict):
        if 'label' in resultado: return [resultado]
        return []
    if isinstance(resultado, list):
        if not resultado: return []
        if isinstance(resultado[0], list): return resultado[0]
        if isinstance(resultado[0], dict): return resultado
    return []

def _es_malicioso(prediccion):
    """Determina si la predicción indica contenido tóxico."""
    label = str(prediccion.get('label', '')).lower()
    score = float(prediccion.get('score', 0.0))
    
    # Etiquetas comunes de toxicidad en varios modelos
    toxic_labels = ['toxic', 'severe_toxic', 'insult', 'hate', 'hate_speech', 'obscene']
    
    if any(tl in label for tl in toxic_labels):
        if score > 0.5: # Umbral de seguridad
            print(f'Moderación IA: BLOQUEO por "{label}" (score {score:.3f})', flush=True)
            return True
    return False

def _filtro_local_emergencia(texto):
    """Filtro básico bilingüe para cuando la IA no está disponible."""
    t = texto.lower()
    for palabra in PALABRAS_PROHIBIDAS:
        if palabra in t:
            print(f'Moderación EMERGENCIA: Bloqueo local por palabra "{palabra}"', flush=True)
            return False
    return True

def validar_contenido_toxico(texto):
    """Valida el contenido en varios idiomas. Si la IA falla, usa el filtro local."""
    if not texto or len(texto.strip()) < 2:
        return True

    headers = _get_headers()
    payload = {'inputs': texto, 'options': {'wait_for_model': True}}

    # Intentamos con los modelos disponibles
    for url in API_URLS:
        try:
            print(f'Moderación IA: analizando con {url.split("/")[-1]}...', flush=True)
            response = requests.post(url, headers=headers, json=payload, timeout=8)
            
            if response.status_code == 200:
                resultado = response.json()
                predictions = _normalize_predictions(resultado)
                if not predictions: continue
                
                for prediccion in predictions:
                    if _es_malicioso(prediccion):
                        return False
                print('Moderación IA: Contenido aprobado', flush=True)
                return True
            
            print(f'Moderación IA: El modelo {url.split("/")[-1]} devolvió error {response.status_code}', flush=True)
        except Exception as e:
            print(f'Moderación IA: Error de conexión con {url.split("/")[-1]}: {e}', flush=True)
            continue

    # Si todos los modelos fallan o dan error (como el 404), usamos el filtro local
    print('Moderación IA: Sin respuesta de API. Aplicando filtro local bilingüe...', flush=True)
    return _filtro_local_emergencia(texto)