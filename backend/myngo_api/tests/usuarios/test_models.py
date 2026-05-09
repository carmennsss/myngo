import pytest
from usuarios.models import Usuario, Perfil, Seguimiento
from tests.factories import UsuarioFactory, PerfilFactory, ComunidadFactory, SeguimientoFactory

pytestmark = pytest.mark.django_db

def test_create_usuario():
    usuario = UsuarioFactory.create(email="test@example.com")
    assert usuario.email == "test@example.com"
    assert str(usuario) == f"{usuario.id} - {usuario.nombre_usuario}"
    assert usuario.is_active is True

def test_usuario_manager_create_superuser():
    superusuario = Usuario.objects.create_superuser("admin@example.com", "admin123", nombre_usuario="admin")
    assert superusuario.is_superuser is True
    assert superusuario.is_staff is True

def test_recalcular_puntos(monkeypatch):
    from django.utils import timezone
    import datetime
    
    perfil = PerfilFactory(puntos=0)
    perfil.usuario.rating_actual = 5.0
    perfil.usuario.last_login = timezone.now() - datetime.timedelta(days=2)
    perfil.usuario.save()
    
    perfil.recalcular_puntos()
    # 2 días a 200 puntos/día = 400
    perfil.refresh_from_db()
    assert perfil.puntos == 400

def test_seguimiento_str():
    seguimiento = SeguimientoFactory()
    expected_str = f"{seguimiento.seguidor.nombre_usuario} → {seguimiento.seguido_usuario.nombre_usuario} ({seguimiento.estado})"
    assert str(seguimiento) == expected_str
