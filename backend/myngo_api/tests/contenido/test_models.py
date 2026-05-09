import pytest
from contenido.models import ImagenGaleria, Publicacion, Coleccion, MeGusta, Comentario, Reporte, PostGuardado, _definir_ruta_almacenamiento
from tests.factories import ImagenGaleriaFactory, PublicacionFactory, ColeccionFactory, ComentarioFactory, UsuarioFactory

pytestmark = pytest.mark.django_db

def test_definir_ruta_almacenamiento_publicacion():
    class DummyInstance:
        pass
    instance = DummyInstance()
    ruta = _definir_ruta_almacenamiento(instance, 'test image.jpg')
    assert ruta == 'publicaciones/archivos/test_image.jpg'

def test_definir_ruta_almacenamiento_avatar():
    class DummyInstance:
        _es_avatar = True
    instance = DummyInstance()
    ruta = _definir_ruta_almacenamiento(instance, 'avatar.jpg')
    assert ruta == 'perfiles/avatar/avatar.jpg'

def test_publicacion_creation():
    publicacion = PublicacionFactory(titulo="Test Title")
    assert publicacion.titulo == "Test Title"
    assert publicacion.es_valido_ia is True

def test_comentario_str():
    comentario = ComentarioFactory()
    assert str(comentario) == f"Comentario de {comentario.autor.nombre_usuario}"

def test_coleccion_creation():
    coleccion = ColeccionFactory(nombre_coleccion="Vacaciones")
    assert coleccion.nombre_coleccion == "Vacaciones"
    assert coleccion.es_privada is False

def test_post_guardado_str():
    usuario = UsuarioFactory()
    publicacion = PublicacionFactory()
    post_guardado = PostGuardado.objects.create(usuario=usuario, publicacion=publicacion)
    expected_str = f"Post {publicacion.id} guardado por {usuario.nombre_usuario}"
    assert str(post_guardado) == expected_str
