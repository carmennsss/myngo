import os
import sys
from pathlib import Path

# Añadir la carpeta apps al path ANTES de cualquier import de Django
BASE_DIR = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(BASE_DIR / 'apps'))

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')

from django.core.asgi import get_asgi_application
from channels.routing import ProtocolTypeRouter, URLRouter
from django.urls import re_path, path
from mensajeria import consumers
from mensajeria.middleware import TokenAuthMiddleware

application = ProtocolTypeRouter({
    "http": get_asgi_application(),
    "websocket": TokenAuthMiddleware(
        URLRouter([
            # Rutas oficiales con path (más seguras)
            path('ws/chat/<int:room_id>/', consumers.ChatConsumer.as_asgi()),
            path('ws/presence/', consumers.PresenceConsumer.as_asgi()),
            path('ws/chat-notificaciones/', consumers.NotificacionesChatConsumer.as_asgi()),
            
            # Versiones sin barra final (por si acaso)
            path('ws/chat/<int:room_id>', consumers.ChatConsumer.as_asgi()),
            path('ws/presence', consumers.PresenceConsumer.as_asgi()),
            path('ws/chat-notificaciones', consumers.NotificacionesChatConsumer.as_asgi()),
        ])
    ),
})