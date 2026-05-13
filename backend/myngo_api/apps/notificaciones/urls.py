"""Configuración de rutas de URL para el módulo de notificaciones."""

from django.urls import path

from .views import (
    MarcarNotificacionLeida,
    MarcarTodasLeidas,
    MarcarLeidasPorTipo,
    NotificacionList,
    NotificacionesNoLeidasCount,
    ResponderSolicitudUnion,
)

urlpatterns = [
    # Listado y Respuestas
    path('', NotificacionList.as_view(), name='notificacion-list'),
    path('<int:pk>/responder/', ResponderSolicitudUnion.as_view(), name='responder-solicitud'),

    # Estado de Lectura
    path('no-leidas/count/', NotificacionesNoLeidasCount.as_view(), name='notificaciones-count'),
    path('marcar-leidas/', MarcarTodasLeidas.as_view(), name='marcar-leidas'),
    path('marcar-leidas-por-tipo/', MarcarLeidasPorTipo.as_view(), name='marcar-leidas-por-tipo'),
    path('<int:pk>/marcar-leida/', MarcarNotificacionLeida.as_view(), name='marcar-una-leida'),
]
