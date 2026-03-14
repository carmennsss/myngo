from django.urls import path
from .views import RegistroUsuarios
urlpatterns = [
    path('registrar/', RegistroUsuarios.as_view(),name="registrar"),
]