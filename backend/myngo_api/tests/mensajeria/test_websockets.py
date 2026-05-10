import pytest
import json
from channels.testing import WebsocketCommunicator
from core.asgi import application
from mensajeria.models import SalaChat
from rest_framework.authtoken.models import Token
from tests.factories import UsuarioFactory, SalaChatFactory, ParticipanteChatFactory

pytestmark = pytest.mark.asyncio

@pytest.fixture
def auth_token():
    def _get_token(user):
        token, _ = Token.objects.get_or_create(user=user)
        return str(token.key)
    return _get_token

@pytest.mark.django_db(transaction=True)
async def test_chat_consumer_connect_denied_anonymous():
    communicator = WebsocketCommunicator(application, "/ws/chat/1/?token=invalid")
    connected, _ = await communicator.connect()
    assert not connected
    if connected:
        await communicator.disconnect()

@pytest.mark.django_db(transaction=True)
async def test_presence_consumer(auth_token):
    # Setup user
    from asgiref.sync import sync_to_async
    usuario = await sync_to_async(UsuarioFactory)()
    token = await sync_to_async(auth_token)(usuario)
    
    communicator = WebsocketCommunicator(application, f"/ws/presence/?token={token}")
    connected, _ = await communicator.connect()
    assert connected

    # We should receive presence_connection_established
    response = await communicator.receive_json_from()
    assert response['type'] == 'presence_connection_established'
    assert response['user_id'] == usuario.id

    # Send heartbeat
    await communicator.send_json_to({"type": "heartbeat"})
    
    await communicator.disconnect()

@pytest.mark.django_db(transaction=True)
async def test_chat_consumer_message(auth_token):
    from asgiref.sync import sync_to_async
    usuario = await sync_to_async(UsuarioFactory)()
    sala = await sync_to_async(SalaChatFactory)()
    await sync_to_async(ParticipanteChatFactory)(sala=sala, usuario=usuario)
    
    token = await sync_to_async(auth_token)(usuario)
    
    communicator = WebsocketCommunicator(application, f"/ws/chat/{sala.id}/?token={token}")
    connected, _ = await communicator.connect()
    assert connected

    # Enviar mensaje
    await communicator.send_json_to({
        "type": "message",
        "content": "Hello World",
        "tipo": "TEXTO"
    })

    # Recibir el mensaje procesado
    response = await communicator.receive_json_from()
    assert response['type'] == 'chat_message'
    assert response['content'] == "Hello World"
    
    await communicator.disconnect()
