import pytest
from django.urls import reverse
from rest_framework import status
from mensajeria.models import SalaChat, ParticipanteChat, MensajeChat
from tests.factories import SalaChatFactory, ParticipanteChatFactory, MensajeChatFactory, UsuarioFactory

pytestmark = pytest.mark.django_db

def test_lista_salas_unauthenticated(api_client):
    url = reverse('lista_salas')
    response = api_client.get(url)
    assert response.status_code == status.HTTP_401_UNAUTHORIZED

def test_lista_salas_authenticated(auth_client, usuario):
    sala = SalaChatFactory()
    ParticipanteChatFactory(sala=sala, usuario=usuario)
    url = reverse('lista_salas')
    response = auth_client.get(url)
    assert response.status_code == status.HTTP_200_OK
    assert len(response.data) >= 1

def test_crear_sala(auth_client, usuario):
    url = reverse('lista_salas')
    data = {
        "nombre": "Nueva Sala DM",
        "es_grupal": False,
        "miembros_ids": []
    }
    response = auth_client.post(url, data)
    assert response.status_code == status.HTTP_201_CREATED
    assert SalaChat.objects.filter(nombre="Nueva Sala DM").exists()

def test_historial_mensajes(auth_client, usuario):
    sala = SalaChatFactory()
    ParticipanteChatFactory(sala=sala, usuario=usuario)
    MensajeChatFactory.create_batch(5, sala=sala)
    
    url = reverse('historial_mensajes', kwargs={'sala_id': sala.id})
    response = auth_client.get(url)
    assert response.status_code == status.HTTP_200_OK
    assert 'results' in response.data or isinstance(response.data, list)

def test_marcar_leidos(auth_client, usuario):
    sala = SalaChatFactory()
    ParticipanteChatFactory(sala=sala, usuario=usuario)
    url = reverse('marcar_leidos', kwargs={'sala_id': sala.id})
    response = auth_client.post(url)
    assert response.status_code == status.HTTP_200_OK
    assert response.data.get('status') == 'ok'

def test_conteo_no_leidos(auth_client, usuario):
    url = reverse('conteo_no_leidos')
    response = auth_client.get(url)
    assert response.status_code == status.HTTP_200_OK
    assert 'total' in response.data
