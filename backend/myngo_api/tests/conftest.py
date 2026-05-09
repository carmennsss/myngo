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
from rest_framework.authtoken.models import Token
from tests.factories import UsuarioFactory, SuperUsuarioFactory

@pytest.fixture
def usuario(db):
    """Retorna un usuario normal de prueba."""
    return UsuarioFactory()

@pytest.fixture
def superusuario(db):
    """Retorna un superusuario de prueba."""
    return SuperUsuarioFactory()

@pytest.fixture
def api_client():
    """Retorna un cliente API de DRF."""
    return APIClient()

@pytest.fixture
def auth_client(api_client, usuario):
    """Retorna un cliente API autenticado para el usuario dado."""
    token, _ = Token.objects.get_or_create(user=usuario)
    api_client.credentials(HTTP_AUTHORIZATION=f'Token {token.key}')
    return api_client

@pytest.fixture
def admin_client(api_client, superusuario):
    """Retorna un cliente API autenticado para un superusuario."""
    token, _ = Token.objects.get_or_create(user=superusuario)
    api_client.credentials(HTTP_AUTHORIZATION=f'Token {token.key}')
    return api_client
