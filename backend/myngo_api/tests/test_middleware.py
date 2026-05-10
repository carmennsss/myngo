import pytest
from mensajeria.middleware import TokenAuthMiddleware
from channels.testing import WebsocketCommunicator
from django.urls import re_path
from channels.routing import URLRouter
from channels.generic.websocket import AsyncWebsocketConsumer
from rest_framework.authtoken.models import Token
from .factories import UsuarioFactory

pytestmark = pytest.mark.asyncio

class DummyConsumer(AsyncWebsocketConsumer):
    async def connect(self):
        if self.scope['user'].is_anonymous:
            await self.close()
        else:
            await self.accept()

application = TokenAuthMiddleware(
    URLRouter([
        re_path(r'^ws/test/$', DummyConsumer.as_asgi()),
    ])
)

@pytest.mark.django_db(transaction=True)
async def test_token_auth_middleware_valid_token():
    from asgiref.sync import sync_to_async
    usuario = await sync_to_async(UsuarioFactory)()
    token_obj, _ = await sync_to_async(Token.objects.get_or_create)(user=usuario)
    token = token_obj.key
    
    communicator = WebsocketCommunicator(application, f"/ws/test/?token={token}")
    connected, _ = await communicator.connect()
    assert connected
    await communicator.disconnect()

@pytest.mark.django_db(transaction=True)
async def test_token_auth_middleware_invalid_token():
    communicator = WebsocketCommunicator(application, "/ws/test/?token=invalid")
    connected, _ = await communicator.connect()
    assert not connected
    await communicator.disconnect()

@pytest.mark.django_db(transaction=True)
async def test_token_auth_middleware_missing_token():
    communicator = WebsocketCommunicator(application, "/ws/test/")
    connected, _ = await communicator.connect()
    assert not connected
    await communicator.disconnect()
