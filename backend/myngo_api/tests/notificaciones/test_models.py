import pytest
from notificaciones.models import Notificacion
from tests.factories import NotificacionFactory

pytestmark = pytest.mark.django_db

def test_notificacion_creation():
    notificacion = NotificacionFactory(tipo="LIKE", mensaje="A alguien le gustó tu foto")
    assert notificacion.tipo == "LIKE"
    assert notificacion.mensaje == "A alguien le gustó tu foto"
    assert notificacion.leida is False

def test_notificacion_str():
    notificacion = NotificacionFactory()
    expected_str = f"{notificacion.tipo} para {notificacion.usuario.nombre_usuario}"
    assert str(notificacion) == expected_str
