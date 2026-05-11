import pytest
from django.urls import reverse
from rest_framework import status
from contenido.models import Publicacion, ImagenGaleria, Coleccion, MeGusta
from tests.factories import PublicacionFactory, ImagenGaleriaFactory, ColeccionFactory, UsuarioFactory, ComunidadFactory

pytestmark = pytest.mark.django_db

def test_publicacion_list_unauthenticated(api_client):
    url = reverse('publicacion-list')
    response = api_client.get(url)
    assert response.status_code == status.HTTP_200_OK

def test_publicacion_list_authenticated(auth_client):
    PublicacionFactory.create_batch(3)
    url = reverse('publicacion-list')
    response = auth_client.get(url)
    assert response.status_code == status.HTTP_200_OK
    assert len(response.data) >= 3

def test_publicacion_create(auth_client, usuario):
    comunidad = ComunidadFactory()
    url = reverse('publicacion-create')
    data = {
        "titulo": "New Post",
        "contenido_texto": "Content here",
        "comunidad_id": comunidad.id
    }
    response = auth_client.post(url, data)
    assert response.status_code == status.HTTP_201_CREATED
    assert Publicacion.objects.filter(titulo="New Post").exists()

def test_publicacion_detail(auth_client):
    pub = PublicacionFactory()
    url = reverse('publicacion-detail', kwargs={'pk': pub.pk})
    response = auth_client.get(url)
    assert response.status_code == status.HTTP_200_OK
    assert response.data['titulo'] == pub.titulo

def test_toggle_like(auth_client, usuario):
    pub = PublicacionFactory()
    url = reverse('publicacion-like', kwargs={'pk': pub.pk})
    
    # Add like
    response = auth_client.post(url)
    assert response.status_code == status.HTTP_201_CREATED
    assert MeGusta.objects.filter(usuario=usuario, publicacion=pub).exists()
    
    # Remove like
    response = auth_client.post(url)
    assert response.status_code == status.HTTP_200_OK
    assert not MeGusta.objects.filter(usuario=usuario, publicacion=pub).exists()

def test_galeria_list(auth_client):
    ImagenGaleriaFactory.create_batch(2)
    url = reverse('galeria-list')
    response = auth_client.get(url)
    assert response.status_code == status.HTTP_200_OK
    assert len(response.data) >= 2

def test_colecciones_list(auth_client, usuario):
    ColeccionFactory(usuario=usuario)
    url = reverse('coleccion-list')
    response = auth_client.get(url)
    assert response.status_code == status.HTTP_200_OK
    assert len(response.data) >= 1
