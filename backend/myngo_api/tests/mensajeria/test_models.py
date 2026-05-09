import pytest
from mensajeria.models import SalaChat, ParticipanteChat, MensajeChat, PersonalizacionChat, chat_image_path
from tests.factories import SalaChatFactory, UsuarioFactory, ComunidadFactory, ParticipanteChatFactory, MensajeChatFactory

pytestmark = pytest.mark.django_db

def test_chat_image_path():
    class DummyInstance:
        pass
    instance = DummyInstance()
    ruta = chat_image_path(instance, 'test.jpg')
    assert ruta.startswith('chats/contenido/')
    assert ruta.endswith('/test.jpg')

def test_sala_chat_creation():
    sala = SalaChatFactory(nombre="Sala General")
    assert sala.nombre == "Sala General"
    assert sala.es_grupal is False

def test_participante_chat_str():
    participante = ParticipanteChatFactory()
    expected_str = f"{participante.usuario.nombre_usuario} en {participante.sala.nombre}"
    assert str(participante) == expected_str

def test_mensaje_chat_str():
    mensaje = MensajeChatFactory()
    expected_str = f"Mensaje #{mensaje.id} ({mensaje.tipo}) en {mensaje.sala.nombre}"
    assert str(mensaje) == expected_str

def test_personalizacion_chat_creation():
    sala = SalaChatFactory()
    personalizacion = PersonalizacionChat.objects.create(sala=sala, color_fondo="#FFFFFF")
    assert personalizacion.color_fondo == "#FFFFFF"
    assert str(personalizacion) == f"Personalización de {sala.nombre}"
