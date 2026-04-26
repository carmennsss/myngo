from django.urls import re_path
from . import consumers

websocket_urlpatterns = [
    re_path(r'chat/(?P<room_id>\d+)/?', consumers.ChatConsumer.as_asgi()),
    re_path(r'presence/?', consumers.PresenceConsumer.as_asgi()),
    re_path(r'chat-notificaciones/?', consumers.NotificacionesChatConsumer.as_asgi()),
]
