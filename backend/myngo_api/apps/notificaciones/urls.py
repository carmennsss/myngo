from django.urls import path
from .views import NotificacionList, ResponderSolicitudUnion, NotificacionesNoLeidasCount, MarcarTodasLeidas

urlpatterns = [
    path('', NotificacionList.as_view(), name='notificacion-list'),
    path('<int:pk>/responder/', ResponderSolicitudUnion.as_view(), name='responder-solicitud'),
    path('no-leidas/count/', NotificacionesNoLeidasCount.as_view(), name='notificaciones-count'),
    path('marcar-leidas/', MarcarTodasLeidas.as_view(), name='marcar-leidas'),
]
