"""Servicio de validación de contenido mediante IA.

Utiliza modelos de Hugging Face para detectar toxicidad, insultos y contenido
inapropiado en los textos de las publicaciones.
"""

import requests
from django.conf import settings

# Modelo multilingüe para toxicidad, insultos, odio y sexualidad implícita
API_URL = "https://router.huggingface.co/hf-inference/models/unitary/multilingual-toxic-xlm-roberta"

# Umbrales de decisión para cada categoría de toxicidad
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
    """Obtiene el token de Hugging Face desde la configuración de Django.

    Returns:
        str: Token de API.
    """
    return getattr(settings, 'HUGGING_FACE_TOKEN', '')


def _normalize_predictions(resultado):
    """Normaliza la respuesta de la API de Hugging Face a una lista de diccionarios.

    Args:
        resultado: Respuesta JSON de la API.

    Returns:
        list: Lista de predicciones normalizada o None si el formato es inválido.
    """
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
    """Determina si una predicción individual supera los umbrales de toxicidad.

    Args:
        prediccion (dict): Diccionario con 'label' y 'score'.

    Returns:
        bool: True si el contenido se considera malicioso.
    """
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
    """Valida si un texto contiene contenido tóxico o inapropiado.

    Realiza una petición a la API de inferencia de Hugging Face. Si falla la conexión
    o el token no está configurado, permite el contenido por defecto.

    Args:
        texto (str): Texto a analizar.

    Returns:
        bool: True si el contenido es válido, False si es tóxico.
    """
    if not texto or len(texto.strip()) < 3:
        return True

    hf_token = _get_hf_token()
    if not hf_token or hf_token == 'hf_placeholder':
        # Silenciamos el log en producción si no hay token, permitiendo flujo normal
        return True

    headers = {"Authorization": f"Bearer {hf_token}"}
    payload = {
        'inputs': texto,
        'options': {'wait_for_model': True}
    }

    try:
        response = requests.post(API_URL, headers=headers, json=payload, timeout=30)

        if response.status_code != 200:
            return True

        resultado = response.json()
        predictions = _normalize_predictions(resultado)

        if predictions is None:
            return True

        for prediccion in predictions:
            if _es_malicioso(prediccion):
                return False

        return True
    except Exception:
        return True