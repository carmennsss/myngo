import factory
from django.utils import timezone
from faker import Faker
from usuarios.models import Usuario, Perfil, Seguimiento
from comunidades.models import Comunidad, TagComunidad, MiembrosComunidad
from contenido.models import ImagenGaleria, Publicacion, Coleccion, MeGusta, Comentario
from mejoras.models import Voto, CatalogoMejoras, PeticionMejora, MejoraUsuario
from mensajeria.models import SalaChat, ParticipanteChat, MensajeChat, PersonalizacionChat
from notificaciones.models import Notificacion

fake = Faker('es_ES')

class UsuarioFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = Usuario
        django_get_or_create = ('email',)

    nombre_usuario = factory.LazyFunction(fake.user_name)
    email = factory.LazyFunction(fake.email)
    es_verificado = False
    rating_actual = 0.0
    
    @factory.post_generation
    def password(self, create, extracted, **kwargs):
        password = extracted if extracted else 'password123'
        self.set_password(password)

class SuperUsuarioFactory(UsuarioFactory):
    is_staff = True
    is_superuser = True

class PerfilFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = Perfil

    usuario = factory.SubFactory(UsuarioFactory)
    biografia = factory.LazyFunction(fake.text)
    puntos = 0

class TagComunidadFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = TagComunidad
        django_get_or_create = ('nombre',)
        
    nombre = factory.Sequence(lambda n: f"Tag {n}")

class ComunidadFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = Comunidad
        django_get_or_create = ('nombre',)

    nombre = factory.Sequence(lambda n: f"Comunidad {n}")
    descripcion = factory.LazyFunction(fake.text)
    creador = factory.SubFactory(UsuarioFactory)

class MiembrosComunidadFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = MiembrosComunidad

    usuario = factory.SubFactory(UsuarioFactory)
    comunidad = factory.SubFactory(ComunidadFactory)
    rol = 'Miembro'

class SeguimientoFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = Seguimiento

    seguidor = factory.SubFactory(UsuarioFactory)
    estado = 'ACEPTADO'

class ImagenGaleriaFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = ImagenGaleria

    propietario = factory.SubFactory(UsuarioFactory)
    tipo_archivo = 'I'
    es_publica = True

class PublicacionFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = Publicacion

    autor = factory.SubFactory(UsuarioFactory)
    titulo = factory.LazyFunction(fake.sentence)
    contenido_texto = factory.LazyFunction(fake.text)
    es_valido_ia = True

class ColeccionFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = Coleccion

    usuario = factory.SubFactory(UsuarioFactory)
    nombre_coleccion = factory.Sequence(lambda n: f"Coleccion {n}")

class MeGustaFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = MeGusta

    usuario = factory.SubFactory(UsuarioFactory)
    publicacion = factory.SubFactory(PublicacionFactory)

class ComentarioFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = Comentario

    publicacion = factory.SubFactory(PublicacionFactory)
    autor = factory.SubFactory(UsuarioFactory)
    contenido = factory.LazyFunction(fake.text)
    es_valido_ia = True

class VotoFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = Voto

    votante = factory.SubFactory(UsuarioFactory)
    estrellas = 5

class CatalogoMejorasFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = CatalogoMejoras

    tipo = 'FONDO'
    precio_puntos = 100
    creador = factory.SubFactory(UsuarioFactory)
    esta_activo = True

class PeticionMejoraFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = PeticionMejora

    usuario = factory.SubFactory(UsuarioFactory)
    comunidad = factory.SubFactory(ComunidadFactory)
    tipo = 'FONDO'
    estado = 'PENDIENTE'

class MejoraUsuarioFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = MejoraUsuario

    usuario = factory.SubFactory(UsuarioFactory)
    mejora = factory.SubFactory(CatalogoMejorasFactory)

class SalaChatFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = SalaChat

    nombre = factory.Sequence(lambda n: f"Sala {n}")

class PersonalizacionChatFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = PersonalizacionChat
        
    sala = factory.SubFactory(SalaChatFactory)

class ParticipanteChatFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = ParticipanteChat

    sala = factory.SubFactory(SalaChatFactory)
    usuario = factory.SubFactory(UsuarioFactory)

class MensajeChatFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = MensajeChat

    sala = factory.SubFactory(SalaChatFactory)
    emisor = factory.SubFactory(UsuarioFactory)
    contenido = factory.LazyFunction(fake.text)
    tipo = 'TEXTO'

class NotificacionFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = Notificacion

    usuario = factory.SubFactory(UsuarioFactory)
    tipo = 'LIKE'
    mensaje = factory.LazyFunction(fake.sentence)
