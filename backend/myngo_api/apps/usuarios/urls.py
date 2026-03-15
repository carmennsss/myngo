from django.urls import path
from . import views

urlpatterns = [
    path('registrar/', views.RegistroUsuarios.as_view(), name='registrar'),
    path('login/', views.LoginUsuario.as_view(), name='login'),
    path('recuperar-password/', views.RecuperarPassword.as_view(), name='recuperar-password'),
]