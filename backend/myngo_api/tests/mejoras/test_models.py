import pytest
from mejoras.models import Voto, CatalogoMejoras, PeticionMejora, MejoraUsuario
from tests.factories import VotoFactory, CatalogoMejorasFactory, PeticionMejoraFactory, MejoraUsuarioFactory

pytestmark = pytest.mark.django_db

def test_voto_creation():
    voto = VotoFactory(estrellas=4)
    assert voto.estrellas == 4
    assert voto.votante is not None

def test_catalogo_mejoras_creation():
    mejora = CatalogoMejorasFactory(tipo="AVATAR_MARCO", precio_puntos=500)
    assert mejora.tipo == "AVATAR_MARCO"
    assert mejora.precio_puntos == 500

def test_peticion_mejora_creation():
    peticion = PeticionMejoraFactory()
    assert peticion.estado == 'PENDIENTE'

def test_mejora_usuario_str():
    mejora_usuario = MejoraUsuarioFactory()
    expected_str = f"{mejora_usuario.usuario.nombre_usuario} - {mejora_usuario.mejora.tipo} {mejora_usuario.mejora.id}"
    assert str(mejora_usuario) == expected_str
