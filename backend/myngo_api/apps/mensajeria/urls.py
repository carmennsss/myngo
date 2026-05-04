"""Configuración de rutas de URL para el módulo de mensajería."""

from django.urls import path

from .views import (
    MensajesChatList,
    SalaChatListCreate,
    SalaChatDetail,
    agregar_miembro,
    conteo_no_leidos,
    marcar_leidos,
    editar_mensaje,
    borrar_mensaje,
    actualizar_sala,
    actualizar_participante,
    actualizar_apodo_personalizado,
    obtener_sala_general_comunidad,
    subir_avatar_sala,
)

urlpatterns = [
    # Gestión de Salas
    path('salas/', SalaChatListCreate.as_view(), name='lista_salas'),
    path('salas/<int:pk>/', SalaChatDetail.as_view(), name='detalle_sala'),
    path('salas/<int:pk>/agregar_miembro/', agregar_miembro, name='agregar_miembro'),
    path('salas/<int:pk>/actualizar/', actualizar_sala, name='actualizar_sala'),
    path('salas/comunidad/<int:comunidad_id>/general/', obtener_sala_general_comunidad, name='sala_general_comunidad'),
    path('salas/<int:pk>/subir-avatar/', subir_avatar_sala, name='subir_avatar_sala'),
    path('salas/<int:sala_id>/participante/', actualizar_participante, name='actualizar_participante'),
    path('salas/<int:sala_id>/apodo-personalizado/', actualizar_apodo_personalizado, name='actualizar_apodo_personalizado'),

    # Mensajes e Historial
    path('salas/<int:sala_id>/mensajes/', MensajesChatList.as_view(), name='historial_mensajes'),
    path('salas/<int:sala_id>/marcar-leidos/', marcar_leidos, name='marcar_leidos'),
    path('mensajes/<int:mensaje_id>/editar/', editar_mensaje, name='editar_mensaje'),
    path('mensajes/<int:mensaje_id>/borrar/', borrar_mensaje, name='borrar_mensaje'),

    # Estadísticas
    path('no-leidos/', conteo_no_leidos, name='conteo_no_leidos'),
]
