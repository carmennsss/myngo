import os
import sys
from pathlib import Path

# Setup Django environment
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
BASE_DIR = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(BASE_DIR / 'apps'))

import django
django.setup()

import pytest
from rest_framework.test import APIClient
from rest_framework_simplejwt.tokens import RefreshToken

@pytest.fixture
def api_client():
    """Retorna un cliente API de DRF."""
    return APIClient()

@pytest.fixture
def auth_client(api_client, usuario):
    """Retorna un cliente API autenticado para el usuario dado."""
    refresh = RefreshToken.for_user(usuario)
    api_client.credentials(HTTP_AUTHORIZATION=f'Bearer {refresh.access_token}')
    return api_client

@pytest.fixture
def admin_client(api_client, superusuario):
    """Retorna un cliente API autenticado para un superusuario."""
    refresh = RefreshToken.for_user(superusuario)
    api_client.credentials(HTTP_AUTHORIZATION=f'Bearer {refresh.access_token}')
    return api_client
