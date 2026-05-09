import pytest
from django.urls import reverse
from rest_framework import status
from comunidades.models import Comunidad, MiembrosComunidad, TagComunidad
from tests.factories import ComunidadFactory, TagComunidadFactory, UsuarioFactory

pytestmark = pytest.mark.django_db

def test_comunidad_list_unauthenticated(api_client):
    url = reverse('comunidad-list')
    response = api_client.get(url)
    assert response.status_code == status.HTTP_200_OK

def test_comunidad_create_authenticated(auth_client, usuario):
    url = reverse('comunidad-list')
    data = {
        "nombre": "Nueva Comunidad",
        "descripcion": "Descripción test",
        "es_publica": True
    }
    response = auth_client.post(url, data)
    assert response.status_code == status.HTTP_201_CREATED
    assert Comunidad.objects.filter(nombre="Nueva Comunidad").exists()

def test_mis_comunidades(auth_client, usuario):
    comunidad = ComunidadFactory()
    MiembrosComunidad.objects.create(usuario=usuario, comunidad=comunidad, rol='Miembro')
    
    url = reverse('mis-comunidades')
    response = auth_client.get(url)
    assert response.status_code == status.HTTP_200_OK
    assert len(response.data) >= 1

def test_comunidad_detail(api_client):
    comunidad = ComunidadFactory()
    url = reverse('comunidad-detail', kwargs={'pk': str(comunidad.pk)})
    response = api_client.get(url)
    assert response.status_code == status.HTTP_200_OK
    assert response.data['nombre'] == comunidad.nombre

def test_unirse_comunidad_publica(auth_client, usuario):
    comunidad = ComunidadFactory(es_publica=True)
    url = reverse('unirse-comunidad', kwargs={'pk': comunidad.pk})
    response = auth_client.post(url)
    assert response.status_code == status.HTTP_201_CREATED
    assert MiembrosComunidad.objects.filter(usuario=usuario, comunidad=comunidad).exists()

def test_tag_list(api_client):
    TagComunidadFactory.create_batch(3)
    url = reverse('tag-list')
    response = api_client.get(url)
    assert response.status_code == status.HTTP_200_OK
    assert len(response.data) >= 3
