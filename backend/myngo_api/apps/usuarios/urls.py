from django.urls import path
from .views import RegistroUsuarios, LoginUsuario,SeguimientoUsuarios,DatosUsuarios,RecuperarPassword,GestionPerfiles,SeguirPerfil,ResponderPeticionUnion

urlpatterns = [
    path('registrar/', RegistroUsuarios.as_view(), name="registrar"),
    path('login/', LoginUsuario.as_view(), name="login"),
    path('enviar_solicitud/',SeguimientoUsuarios.as_view(),name="enviar_solicitud"),
  path('recuperar-password/', RecuperarPassword.as_view(), name='recuperar-password'),
    path('actualizar_solicitud/', SeguimientoUsuarios.as_view(), name='actualizar_solicitud'),
    path('actualizar_usuario/',DatosUsuarios.as_view(),name="actualizar_usuario"),
    path('confirmar/<str:token>/', RegistroUsuarios.as_view()),
    path('', GestionPerfiles.as_view(), name='listar-perfiles'),
    path('<str:nombre_usuario>/', SeguirPerfil.as_view(), name='detalle-perfil'),
    path('<str:nombre_usuario>/solicitud', SeguirPerfil.as_view(), name='seguir-perfil'),
    path('peticiones/<int:pk>/responder/', ResponderPeticionUnion.as_view(), name='responder-peticion'),
]