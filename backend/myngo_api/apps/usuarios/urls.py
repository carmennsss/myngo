from django.urls import path
from .views import RegistroUsuarios, LoginUsuario,SeguimientoUsuarios,DatosUsuarios,RecuperarPassword,GestionPerfiles

urlpatterns = [
    path('',DatosUsuarios.as_view(),name="datos_usuarios"),
    path('registrar/', RegistroUsuarios.as_view(), name="registrar"),
    path('login/', LoginUsuario.as_view(), name="login"),
    path('enviar_solicitud/',SeguimientoUsuarios.as_view(),name="enviar_solicitud"),
  path('recuperar-password/', RecuperarPassword.as_view(), name='recuperar-password'),
    path('actualizar_solicitud/', SeguimientoUsuarios.as_view(), name='actualizar_solicitud'),
    path('actualizar_usuario/',DatosUsuarios.as_view(),name="actualizar_usuario"),
    path('confirmar/<str:token>/', RegistroUsuarios.as_view()),
    path('perfiles/', GestionPerfiles.as_view(), name='listar-perfiles'),
    path('perfiles/<str:nombre_usuario>/', GestionPerfiles.as_view(), name='detalle-perfil'),
   
]