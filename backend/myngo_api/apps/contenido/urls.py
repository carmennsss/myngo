from django.urls import path
from .views import DocumentosUtilidad

urlpatterns = [
    path('reglas_comunidad/',DocumentosUtilidad.as_view(),name="reglas_comunidad"),
   
]