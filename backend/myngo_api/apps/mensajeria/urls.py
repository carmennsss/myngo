from django.urls import path
from .views import SalaChatList, MensajeChatList

urlpatterns = [
    path('salas/', SalaChatList.as_view(), name='sala-chat-list'),
    path('mensajes/', MensajeChatList.as_view(), name='mensaje-chat-list'),
]
