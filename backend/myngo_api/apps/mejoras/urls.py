from django.urls import path
from .views import VotoAPIView, RankingUsuariosView, RankingComunidadesView

urlpatterns = [
    path('votar/', VotoAPIView.as_view(), name='votar'),
    path('ranking/usuarios/', RankingUsuariosView.as_view(), name='ranking-usuarios'),
    path('ranking/comunidades/', RankingComunidadesView.as_view(), name='ranking-comunidades'),
]
