from django.urls import re_path
from . import consumers

websocket_urlpatterns = [
    # Usamos re_path sin ancla inicial estricta para ser ultra-permisivos con las barras /
    re_path(r'ws/chat/(?P<room_id>\d+)/?', consumers.ChatConsumer.as_asgi()),
    re_path(r'ws/presence/?', consumers.PresenceConsumer.as_asgi()),
    re_path(r'ws/chat-notificaciones/?', consumers.NotificacionesChatConsumer.as_asgi()),
]
