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
LABEL_THRESHOLDS = {
    'toxic': 0.35,
    'severe_toxic': 0.20,
    'obscene': 0.30,
    'threat': 0.20,
    'insult': 0.30,
    'identity_hate': 0.25,
    'toxicity': 0.35, # Fallback
    'severe_toxicity': 0.20,
    'identity_attack': 0.25,
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
    """Normaliza la respuesta de la API de Hugging Face a una lista plana."""
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
    """Determina si una predicción supera el umbral de toxicidad."""
    if not isinstance(prediccion, dict):
        return False

    label = str(prediccion.get('label', '')).lower()
    try:
        score = float(prediccion.get('score', 0.0))
    except (TypeError, ValueError):
        return False

    umbral = LABEL_THRESHOLDS.get(label, 0.35) # Más estricto por defecto
    return score >= umbral


def validar_contenido_toxico(texto):
    """Valida si un texto contiene contenido tóxico o inapropiado.

    Realiza hasta 3 intentos (con espera en caso de 503 - modelo cargando).
    Si la API falla por cualquier motivo, permite el contenido por defecto.

    Args:
        texto (str): Texto a analizar.

    Returns:
        bool: True si el contenido es válido, False si es tóxico.
    """
    if not texto or len(texto.strip()) < 3:
        return True

    headers = _get_headers()
    payload = {
        'inputs': texto,
        'options': {'wait_for_model': True},
    }

    try:
        print(f'Moderación IA: analizando texto "{texto[:80]}..."')
        for intento in range(3):
            response = requests.post(API_URL, headers=headers, json=payload, timeout=20)

            if response.status_code == 200:
                resultado = response.json()
                print(f'Moderación IA: respuesta raw = {resultado}')

                predictions = _normalize_predictions(resultado)
                if predictions is None:
                    print('Moderación IA: formato inesperado, permitiendo contenido')
                    return True

                for prediccion in predictions:
                    if _es_malicioso(prediccion):
                        label = prediccion.get('label')
                        score = prediccion.get('score')
                        print(f'Moderación IA: BLOQUEADO por {label} (score={score:.3f})')
                        return False

                print('Moderación IA: contenido aprobado')
                return True

            elif response.status_code == 503:
                # Modelo cargando — esperamos y reintentamos
                print(f'Moderación IA: modelo cargando (503), intento {intento + 1}/3...')
                time.sleep(2)
                continue

            else:
                print(f'Moderación IA: error HTTP {response.status_code} - {response.text[:200]}')
                return True

    except Exception as e:
        print(f'Moderación IA: error de conexión ({e}), permitiendo contenido')

    return True