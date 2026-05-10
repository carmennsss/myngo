import pytest
from django.urls import reverse
from rest_framework import status
from mejoras.models import Voto, CatalogoMejoras, MejoraUsuario, PeticionMejora
from tests.factories import UsuarioFactory, ComunidadFactory, CatalogoMejorasFactory, MejoraUsuarioFactory

pytestmark = pytest.mark.django_db

def test_votar_usuario(auth_client, usuario):
    target = UsuarioFactory()
    url = reverse('votar')
    data = {
        "receptor_usuario": target.id,
        "estrellas": 5
    }
    response = auth_client.post(url, data)
    assert response.status_code == status.HTTP_200_OK
    assert Voto.objects.filter(votante=usuario, receptor_usuario=target).exists()

def test_tienda_global_list(auth_client):
    CatalogoMejorasFactory.create_batch(3, comunidad=None)
    url = reverse('tienda-global')
    response = auth_client.get(url)
    assert response.status_code == status.HTTP_200_OK
    assert len(response.data) >= 3

def test_comprar_mejora(auth_client, usuario):
    mejora = CatalogoMejorasFactory(precio_puntos=100)
    from tests.factories import PerfilFactory
    PerfilFactory(usuario=usuario, puntos=200)
    
    url = reverse('comprar-mejora', kwargs={'pk': mejora.pk})
    response = auth_client.post(url)
    assert response.status_code == status.HTTP_200_OK
    assert MejoraUsuario.objects.filter(usuario=usuario, mejora=mejora).exists()
    
    usuario.perfil.refresh_from_db()
    assert usuario.perfil.puntos == 100

def test_comprar_mejora_sin_puntos(auth_client, usuario):
    mejora = CatalogoMejorasFactory(precio_puntos=100)
    from tests.factories import PerfilFactory
    PerfilFactory(usuario=usuario, puntos=50)
    
    url = reverse('comprar-mejora', kwargs={'pk': mejora.pk})
    response = auth_client.post(url)
    assert response.status_code == status.HTTP_400_BAD_REQUEST

def test_mis_mejoras(auth_client, usuario):
    MejoraUsuarioFactory(usuario=usuario)
    url = reverse('mis-mejoras')
    response = auth_client.get(url)
    assert response.status_code == status.HTTP_200_OK
    assert len(response.data) >= 1
