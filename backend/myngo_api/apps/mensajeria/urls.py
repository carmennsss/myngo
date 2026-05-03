"""Configuración de rutas de URL para el módulo de mensajería."""

from django.urls import path

from .views import (
    MensajesChatList,
    SalaChatListCreate,
    agregar_miembro,
    conteo_no_leidos,
    marcar_leidos,
    editar_mensaje,
    borrar_mensaje,
)

urlpatterns = [
    # Gestión de Salas
    path('salas/', SalaChatListCreate.as_view(), name='lista_salas'),
    path('salas/<int:pk>/agregar_miembro/', agregar_miembro, name='agregar_miembro'),

    # Mensajes e Historial
    path('salas/<int:sala_id>/mensajes/', MensajesChatList.as_view(), name='historial_mensajes'),
    path('salas/<int:sala_id>/marcar-leidos/', marcar_leidos, name='marcar_leidos'),
    path('mensajes/<int:mensaje_id>/editar/', editar_mensaje, name='editar_mensaje'),
    path('mensajes/<int:mensaje_id>/borrar/', borrar_mensaje, name='borrar_mensaje'),

    # Estadísticas
    path('no-leidos/', conteo_no_leidos, name='conteo_no_leidos'),
]
