import pytest
from comunidades.models import Comunidad, MiembrosComunidad, TagComunidad
from tests.factories import ComunidadFactory, TagComunidadFactory, UsuarioFactory, MiembrosComunidadFactory

pytestmark = pytest.mark.django_db

def test_tag_comunidad_creation():
    tag = TagComunidadFactory(nombre="Gaming")
    assert tag.nombre == "Gaming"
    assert tag.slug == "gaming"

def test_comunidad_creation():
    creador = UsuarioFactory()
    comunidad = ComunidadFactory(nombre="Comunidad Test", creador=creador)
    assert comunidad.nombre == "Comunidad Test"
    assert comunidad.creador == creador
    assert comunidad.es_publica is True

def test_comunidad_str():
    comunidad = ComunidadFactory()
    assert str(comunidad) == comunidad.nombre

def test_miembro_comunidad_str():
    miembro = MiembrosComunidadFactory()
    expected_str = f"{miembro.usuario.nombre_usuario} en {miembro.comunidad.nombre}"
    assert str(miembro) == expected_str

def test_rating_medio():
    comunidad = ComunidadFactory()
    assert comunidad.rating_medio == 0.0
