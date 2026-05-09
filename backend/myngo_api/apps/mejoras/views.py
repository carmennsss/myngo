"""Punto de entrada del módulo de vistas de mejoras.

Re-exporta todas las vistas desde los submódulos para mantener
la compatibilidad con las URLs existentes.
"""

from .views_catalogo import (
    CatalogoMejorasGlobales,
    CatalogoMejorasComunidad,
    GestionCatalogoComunidad
)
from .views_peticiones import (
    PeticionMejoraCreate,
    PeticionMejoraModeracionList,
    PeticionMejoraModerar
)
from .views_compras import (
    ComprarMejoraView,
    MisMejorasView,
    EquipacionMejorasGlobales,
    EquipacionMejoraComunidad
)
from .views_votos import (
    VotoAPIView,
    RankingUsuariosView,
    RankingComunidadesView
)

__all__ = [
    'CatalogoMejorasGlobales',
    'CatalogoMejorasComunidad',
    'GestionCatalogoComunidad',
    'PeticionMejoraCreate',
    'PeticionMejoraModeracionList',
    'PeticionMejoraModerar',
    'ComprarMejoraView',
    'MisMejorasView',
    'EquipacionMejorasGlobales',
    'EquipacionMejoraComunidad',
    'VotoAPIView',
    'RankingUsuariosView',
    'RankingComunidadesView',
]
