import pytest
from django.urls import reverse
from rest_framework import status
from notificaciones.models import Notificacion
from tests.factories import NotificacionFactory

pytestmark = pytest.mark.django_db

def test_notificacion_list_unauthenticated(api_client):
    url = reverse('notificacion-list')
    response = api_client.get(url)
    assert response.status_code == status.HTTP_401_UNAUTHORIZED

def test_notificacion_list_authenticated(auth_client, usuario):
    NotificacionFactory.create_batch(3, usuario=usuario)
    url = reverse('notificacion-list')
    response = auth_client.get(url)
    assert response.status_code == status.HTTP_200_OK
    assert len(response.data['results']) >= 3

def test_notificaciones_count(auth_client, usuario):
    NotificacionFactory.create_batch(2, usuario=usuario, leida=False)
    NotificacionFactory(usuario=usuario, leida=True)
    
    url = reverse('notificaciones-count')
    response = auth_client.get(url)
    assert response.status_code == status.HTTP_200_OK
    assert response.data['count'] >= 2

def test_marcar_todas_leidas(auth_client, usuario):
    NotificacionFactory.create_batch(2, usuario=usuario, leida=False)
    url = reverse('marcar-leidas')
    response = auth_client.post(url)
    assert response.status_code == status.HTTP_200_OK
    assert not Notificacion.objects.filter(usuario=usuario, leida=False).exists()

def test_marcar_una_leida(auth_client, usuario):
    notif = NotificacionFactory(usuario=usuario, leida=False)
    url = reverse('marcar-una-leida', kwargs={'pk': notif.pk})
    response = auth_client.post(url)
    assert response.status_code == status.HTTP_200_OK
    notif.refresh_from_db()
    assert notif.leida is True
