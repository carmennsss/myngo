"""Servicio de validación de contenido mediante IA bilingüe (ESP/ENG).

Utiliza modelos de Hugging Face con sistema de reintento y un filtro local
de emergencia para asegurar la moderación incluso si la API falla.
"""

import time
import requests
from django.conf import settings

API_URLS = [
    "https://api-inference.huggingface.co/models/unitary/multilingual-toxic-xlm-roberta",
    "https://api-inference.huggingface.co/models/Hate-speech-CNERG/dehatebert-mono-spanish"
]

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
    """Configura las llaves de acceso para la API de Hugging Face."""
    hf_token = getattr(settings, 'HUGGING_FACE_TOKEN', '') or ''
    if hf_token and hf_token not in ('', 'hf_placeholder'):
        return {"Authorization": f"Bearer {hf_token}"}
    return {}

def _normalize_predictions(resultado):
    """Limpia y organiza la respuesta de la IA para que sea fácil de leer."""
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
    """Comprueba si la IA ha detectado insultos o contenido tóxico con alta seguridad."""
    label = str(prediccion.get('label', '')).lower()
    score = float(prediccion.get('score', 0.0))
    
    toxic_labels = ['toxic', 'severe_toxic', 'insult', 'hate', 'hate_speech', 'obscene']
    
    if any(tl in label for tl in toxic_labels):
        if score > 0.5:
            return True
    return False

def _filtro_local_emergencia(texto):
    """Busca palabras prohibidas a mano por si la IA no responde."""
    t = texto.lower()
    for palabra in PALABRAS_PROHIBIDAS:
        if palabra in t:
            return False
    return True

def validar_contenido_toxico(texto):
    """El filtro principal: pregunta a la IA si el texto es apto y, si no responde, aplica el filtro manual."""
    if not texto or len(texto.strip()) < 2:
        return True

    headers = _get_headers()
    payload = {'inputs': texto, 'options': {'wait_for_model': True}}

    for url in API_URLS:
        try:
            response = requests.post(url, headers=headers, json=payload, timeout=8)
            
            if response.status_code == 200:
                resultado = response.json()
                predictions = _normalize_predictions(resultado)
                if not predictions: continue
                
                for prediccion in predictions:
                    if _es_malicioso(prediccion):
                        return False
                return True
            
            continue
        except:
            continue

    return _filtro_local_emergencia(texto)