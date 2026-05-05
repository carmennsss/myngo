"""Configuración de rutas de URL para el módulo de usuarios."""

from django.urls import path

from .views import (
    DatosUsuarios,
    EditarPerfil,
    GestionPerfiles,
    LoginUsuario,
    RankingUsuarios,
    RecuperarPassword,
    RegistroUsuarios,
    ResponderPeticionUnion,
    SeguimientoUsuarios,
    SeguirPerfil,
)

urlpatterns = [
    # Autenticación y Registro
    path('registrar/', RegistroUsuarios.as_view(), name="registrar"),
    path('confirmar/<str:token>/', RegistroUsuarios.as_view()),
    path('login/', LoginUsuario.as_view(), name="login"),
    path('recuperar-password/', RecuperarPassword.as_view(), name='recuperar-password'),

    # Perfiles y Datos de Usuario
    path('datos/', DatosUsuarios.as_view(), name="listar_datos_usuarios"),
    path('datos/<str:usuario_id>/', DatosUsuarios.as_view(), name="detalle_datos_usuario"),
    path('actualizar_usuario/', DatosUsuarios.as_view(), name="actualizar_usuario"),
    path('perfil/editar/', EditarPerfil.as_view(), name='editar_perfil'),
    path('ranking/', RankingUsuarios.as_view(), name='ranking_usuarios'),
    path('', GestionPerfiles.as_view(), name='listar-perfiles'),
    path('<str:nombre_usuario>/', SeguirPerfil.as_view(), name='detalle-perfil'),

    # Relaciones Sociales (Seguimiento)
    path('enviar_solicitud/', SeguimientoUsuarios.as_view(), name="enviar_solicitud"),
    path('actualizar_solicitud/', SeguimientoUsuarios.as_view(), name='actualizar_solicitud'),
    path('<str:nombre_usuario>/solicitud', SeguirPerfil.as_view(), name='seguir-perfil'),
    path('peticiones/<int:pk>/responder/', ResponderPeticionUnion.as_view(), name='responder-peticion'),
]