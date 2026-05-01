"""Configuración de rutas de URL para el módulo de comunidades."""

from django.urls import path

from .views import (
    AdminDashboardView,
    ComunidadDetail,
    ComunidadListCreate,
    GestionarRolMiembro,
    MisComunidadesList,
    ObtenerRolUsuarioEnComunidad,
    ResponderPeticionUnion,
    UnirseComunidad,
)

urlpatterns = [
    # Listado y Creación
    path('', ComunidadListCreate.as_view(), name='comunidad-list'),
    path('mis-comunidades/', MisComunidadesList.as_view(), name='mis-comunidades'),
    path('propias/', MisComunidadesList.as_view(), name='comunidades-propias'),

    # Detalles e Interacción
    path('<int:pk>/', ComunidadDetail.as_view(), name='comunidad-detail'),
    path('<int:pk>/unirse/', UnirseComunidad.as_view(), name='unirse-comunidad'),
    path('responder-peticion/<int:pk>/', ResponderPeticionUnion.as_view(), name='responder-peticion'),

    # Administración y Roles
    path('<int:pk>/admin-dashboard/', AdminDashboardView.as_view(), name='admin-dashboard'),
    path('<int:pk>/gestionar-rol-miembro/', GestionarRolMiembro.as_view(), name='gestionar-rol-miembro'),
    path('<int:pk>/obtener-rol-usuario/', ObtenerRolUsuarioEnComunidad.as_view(), name='obtener-rol-usuario'),
]
