"""Servicio de validación de contenido mediante IA.

Utiliza modelos de Hugging Face para detectar toxicidad, insultos y contenido
inapropiado en los textos de las publicaciones.

Nota: Usa el endpoint clásico (api-inference.huggingface.co) que permite
peticiones anónimas con rate-limit. El token en .env mejora la tasa límite
pero NO es obligatorio para funcionar.
"""

import time
import requests
from django.conf import settings

# Endpoint clásico — funciona sin token (con rate-limit gratuito)
API_URL = "https://api-inference.huggingface.co/models/unitary/multilingual-toxic-xlm-roberta"

# Umbrales de decisión para cada categoría de toxicidad (ajustados al modelo xlm-roberta)
# Bajamos los umbrales para ser más sensibles ante palabras de odio aisladas (como "odio").
LABEL_THRESHOLDS = {
    'toxic': 0.22,
    'severe_toxic': 0.15,
    'obscene': 0.20,
    'threat': 0.15,
    'insult': 0.20,
    'identity_hate': 0.18,
    'toxicity': 0.22,
    'severe_toxicity': 0.15,
    'identity_attack': 0.18,
    'hate': 0.18,
}


def _get_headers():
    """Devuelve las cabeceras HTTP.
    Si hay token en settings lo incluye; si no, hace la petición anónima.
    """
    hf_token = getattr(settings, 'HUGGING_FACE_TOKEN', '') or ''
    if hf_token and hf_token not in ('', 'hf_placeholder'):
        return {"Authorization": f"Bearer {hf_token}"}
    return {}


def _normalize_predictions(resultado):
    """Normaliza la respuesta de la API de Hugging Face a una lista plana de diccionarios."""
    if not resultado:
        return []
    if isinstance(resultado, dict):
        if 'label' in resultado: return [resultado]
        return []
    if isinstance(resultado, list):
        if not resultado: return []
        if isinstance(resultado[0], list): return resultado[0]
        if isinstance(resultado[0], dict): return resultado
    return []


def _es_malicioso(prediccion):
    """Determina si una predicción supera el umbral de toxicidad."""
    if not isinstance(prediccion, dict):
        return False
    label = str(prediccion.get('label', '')).lower()
    try:
        score = float(prediccion.get('score', 0.0))
    except (TypeError, ValueError):
        return False
    umbral = LABEL_THRESHOLDS.get(label, 0.25)
    if score >= umbral:
        print(f'Moderación IA: BLOQUEO por "{label}" (score {score:.3f} >= {umbral})', flush=True)
        return True
    return False


def validar_contenido_toxico(texto):
    """Valida si un texto contiene contenido tóxico o inapropiado mediante IA.
    Realiza hasta 2 intentos (por si el modelo está cargando).
    """
    if not texto or len(texto.strip()) < 2:
        return True

    headers = _get_headers()
    payload = {
        'inputs': texto,
        'options': {'wait_for_model': True},
    }

    try:
        print(f'Moderación IA: analizando "{texto[:60]}..."', flush=True)
        for intento in range(2):
            response = requests.post(API_URL, headers=headers, json=payload, timeout=12)
            if response.status_code == 200:
                resultado = response.json()
                predictions = _normalize_predictions(resultado)
                if not predictions:
                    return True
                for prediccion in predictions:
                    if _es_malicioso(prediccion):
                        return False
                print('Moderación IA: Contenido aprobado', flush=True)
                return True
            elif response.status_code == 503:
                time.sleep(3)
                continue
            else:
                print(f'Moderación IA: Error {response.status_code} - El servicio no está disponible o el token ha fallado. Dejando pasar por seguridad.', flush=True)
                return True
    except Exception as e:
        print(f'Moderación IA: Error {e}', flush=True)
    return True