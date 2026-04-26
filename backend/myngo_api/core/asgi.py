import os
import sys
from pathlib import Path

# Añadir la carpeta apps al path ANTES de cualquier import de Django
BASE_DIR = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(BASE_DIR / 'apps'))

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')

from django.core.asgi import get_asgi_application
from channels.routing import ProtocolTypeRouter, URLRouter
from django.urls import re_path
from mensajeria import consumers
from mensajeria.middleware import TokenAuthMiddleware

application = ProtocolTypeRouter({
    "http": get_asgi_application(),
    "websocket": TokenAuthMiddleware(
        URLRouter([
            re_path(r'ws/chat/(?P<room_id>\d+)/?', consumers.ChatConsumer.as_asgi()),
            re_path(r'ws/presence/?', consumers.PresenceConsumer.as_asgi()),
            re_path(r'ws/chat-notificaciones/?', consumers.NotificacionesChatConsumer.as_asgi()),
            # Fallbacks con barra inicial
            re_path(r'/ws/chat/(?P<room_id>\d+)/?', consumers.ChatConsumer.as_asgi()),
            re_path(r'/ws/presence/?', consumers.PresenceConsumer.as_asgi()),
            re_path(r'/ws/chat-notificaciones/?', consumers.NotificacionesChatConsumer.as_asgi()),
        ])
    ),
})