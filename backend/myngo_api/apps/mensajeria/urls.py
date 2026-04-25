from django.urls import path
from . import views

urlpatterns = [
    path('salas/', views.SalaChatListCreate.as_view(), name='lista_salas'),
    path('salas/<int:pk>/agregar_miembro/', views.agregar_miembro, name='agregar_miembro'),
    path('salas/<int:sala_id>/mensajes/', views.MensajesChatList.as_view(), name='historial_mensajes'),
]
