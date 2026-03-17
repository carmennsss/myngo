from django.urls import path
from .views import ComunidadListCreate, MisComunidadesList, UnirseComunidad, ResponderPeticionUnion

urlpatterns = [
    path('', ComunidadListCreate.as_view(), name='comunidad-list-create'),
    path('propias/', MisComunidadesList.as_view(), name='mis-comunidades'),
    path('<int:pk>/unirse/', UnirseComunidad.as_view(), name='unirse-comunidad'),
    path('peticiones/<int:pk>/responder/', ResponderPeticionUnion.as_view(), name='responder-peticion'),
]
