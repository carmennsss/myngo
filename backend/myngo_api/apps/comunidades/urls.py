from django.urls import path
from .views import (
    ComunidadListCreate, MisComunidadesList, UnirseComunidad, 
    ResponderPeticionUnion, ComunidadDetail, AdminDashboardView
)

urlpatterns = [
    path('', ComunidadListCreate.as_view(), name='comunidad-list'),
    path('mis-comunidades/', MisComunidadesList.as_view(), name='mis-comunidades'),
    path('<int:pk>/', ComunidadDetail.as_view(), name='comunidad-detail'),
    path('<int:pk>/unirse/', UnirseComunidad.as_view(), name='unirse-comunidad'),
    path('<int:pk>/admin-dashboard/', AdminDashboardView.as_view(), name='admin-dashboard'),
    path('responder-peticion/<int:pk>/', ResponderPeticionUnion.as_view(), name='responder-peticion'),
]
