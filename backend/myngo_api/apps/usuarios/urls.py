from django.urls import path
from .views import RegistroUsuarios, LoginUsuario

urlpatterns = [
    path('registrar/', RegistroUsuarios.as_view(), name="registrar"),
    path('login/', LoginUsuario.as_view(), name="login"),
]