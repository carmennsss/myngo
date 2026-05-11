import pytest
from django.urls import reverse
from rest_framework import status
from usuarios.models import Usuario, Perfil, Seguimiento
from tests.factories import UsuarioFactory, PerfilFactory

pytestmark = pytest.mark.django_db

def test_login_success(api_client):
    usuario = UsuarioFactory(email="testlogin@example.com", password="password123")
    url = reverse('login')
    response = api_client.post(url, {"email": "testlogin@example.com", "password": "password123"})
    assert response.status_code == status.HTTP_200_OK
    assert 'token' in response.data

def test_login_invalid_credentials(api_client):
    UsuarioFactory(email="testlogin@example.com", password="password123")
    url = reverse('login')
    response = api_client.post(url, {"email": "testlogin@example.com", "password": "wrongpassword"})
    assert response.status_code == status.HTTP_401_UNAUTHORIZED

def test_get_perfiles_list(api_client):
    PerfilFactory.create_batch(3)
    url = reverse('listar-perfiles')
    response = api_client.get(url)
    assert response.status_code == status.HTTP_200_OK
    assert len(response.data) >= 3

def test_editar_perfil_unauthenticated(api_client):
    url = reverse('editar_perfil')
    response = api_client.put(url, {"biografia": "New bio"})
    assert response.status_code == status.HTTP_401_UNAUTHORIZED

def test_editar_perfil_authenticated(auth_client, usuario):
    PerfilFactory(usuario=usuario, biografia="Old bio")
    url = reverse('editar_perfil')
    response = auth_client.patch(url, {"perfil_id": usuario.perfil.id, "biografia": "New bio"}, format='json')
    assert response.status_code == status.HTTP_200_OK
    usuario.perfil.refresh_from_db()
    assert usuario.perfil.biografia == "New bio"

def test_seguir_perfil_not_found(auth_client):
    url = reverse('seguir-perfil', kwargs={'nombre_usuario': 'nonexistent'})
    response = auth_client.post(url)
    assert response.status_code == status.HTTP_404_NOT_FOUND

def test_seguir_perfil_success(auth_client, usuario):
    target = UsuarioFactory()
    PerfilFactory(usuario=target)
    url = reverse('seguir-perfil', kwargs={'nombre_usuario': target.nombre_usuario})
    response = auth_client.post(url)
    assert response.status_code == status.HTTP_201_CREATED
    assert Seguimiento.objects.filter(seguidor=usuario, seguido_usuario=target).exists()
