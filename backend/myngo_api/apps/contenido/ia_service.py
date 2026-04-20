import requests
import time
from django.conf import settings

# Modelo multilingüe para toxicidad, insultos, odio y sexualidad implícita
API_URL = "https://router.huggingface.co/hf-inference/models/unitary/multilingual-toxic-xlm-roberta"

LABEL_THRESHOLDS = {
    'toxicity': 0.40,
    'severe_toxicity': 0.25,
    'obscene': 0.30,
    'threat': 0.20,
    'insult': 0.25,
    'identity_attack': 0.25,
    'sexual_explicit': 0.25,
    'sexual_harassment': 0.25,
    'sexual': 0.25,
}


def _get_hf_token():
    """Lee el token fresco de settings en cada llamada."""
    return getattr(settings, 'HUGGING_FACE_TOKEN', '')


def _normalize_predictions(resultado):
    if isinstance(resultado, dict):
        if 'error' in resultado:
            return None
        if 'label' in resultado and 'score' in resultado:
            return [resultado]
        return None

    if isinstance(resultado, list):
        if not resultado:
            return []
        first = resultado[0]
        if isinstance(first, dict) and 'label' in first:
            return resultado
        if isinstance(first, list):
            return first
    return None


def _es_malicioso(prediccion):
    if not isinstance(prediccion, dict):
        return False

    label = str(prediccion.get('label', '')).lower()
    try:
        score = float(prediccion.get('score', 0.0))
    except (TypeError, ValueError):
        return False

    if label in LABEL_THRESHOLDS:
        return score >= LABEL_THRESHOLDS[label]

    return score >= 0.70


def validar_contenido_toxico(texto):
    if not texto or len(texto.strip()) < 3:
        return True

    hf_token = _get_hf_token()
    if not hf_token or hf_token == 'hf_placeholder':
        print('Moderación IA: token de Hugging Face faltante, permitiendo contenido sin moderación')
        return True

    headers = {"Authorization": f"Bearer {hf_token}"}
    payload = {
        'inputs': texto,
        'options': {'wait_for_model': True}
    }

    try:
        print(f'Moderación IA: analizando texto "{texto[:80]}..."')
        response = requests.post(API_URL, headers=headers, json=payload, timeout=30)
        
        if response.status_code != 200:
            print(f'Moderación IA: status inesperado {response.status_code} - {response.text[:200]}')
            return True

        resultado = response.json()
        print(f'Moderación IA: respuesta raw = {resultado}')
        
        predictions = _normalize_predictions(resultado)
        if predictions is None:
            print('Moderación IA: formato inesperado, permitiendo contenido', resultado)
            return True

        for prediccion in predictions:
            if _es_malicioso(prediccion):
                label = prediccion.get('label')
                score = prediccion.get('score')
                print(f"Moderación IA: BLOQUEADO por {label} (score={score})")
                return False
        
        print('Moderación IA: contenido aprobado')
        return True
    except Exception as e:
        print(f'Error conexión moderación IA: {e}, permitiendo contenido')
        return True