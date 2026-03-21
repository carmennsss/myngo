import requests
import time
from django.conf import settings

# Sugerencia: El token debe estar en .env (HUGGING_FACE_TOKEN)
HF_TOKEN = getattr(settings, 'HUGGING_FACE_TOKEN', 'hf_placeholder')
API_URL = "https://api-inference.huggingface.co/models/unitary/toxic-bert"
headers = {"Authorization": f"Bearer {HF_TOKEN}"}

def validar_contenido_toxico(texto):
    """
    Envía el texto a Hugging Face para validar toxicidad.
    Retorna True si el contenido es SEGURO (no tóxico).
    """
    if not texto or len(texto.strip()) < 5:
        return True

    payload = {"inputs": texto}
    
    try:
        # Reintento simple si el modelo está cargando (503)
        for _ in range(3):
            response = requests.post(API_URL, headers=headers, json=payload, timeout=10)
            if response.status_code == 200:
                resultado = response.json()
                # El modelo toxic-bert devuelve una lista de dicts [{'label': 'toxic', 'score': 0.001}, ...]
                # Buscamos 'toxic' o 'obscene' etc.
                for match in resultado[0]:
                    if match['label'] in ['toxic', 'severe_toxic', 'obscene', 'threat', 'insult', 'identity_hate']:
                        if match['score'] > 0.7: # Umbral de tolerancia
                            return False
                return True
            elif response.status_code == 503:
                time.sleep(2)
                continue
            else:
                print(f"Error HF API: {response.status_code} - {response.text}")
                return True # En caso de error de API, permitimos por defecto o marcamos para revisión manual
    except Exception as e:
        print(f"Error conexión IA: {e}")
        return True # Fallback seguro

    return True
