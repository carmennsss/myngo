"""Modelos del dominio de usuarios.

Incluye el gestor de usuarios personalizado, el modelo Usuario
(basado en AbstractBaseUser con email como identificador único),
el modelo Perfil (datos extendidos 1:1) y el modelo Seguimiento
(relaciones entre usuarios y comunidades).
"""

from django.db import models
from django.contrib.auth.models import AbstractBaseUser, BaseUserManager
from django.core.validators import MaxValueValidator, MinValueValidator
from django.utils import timezone


class UsuarioManager(BaseUserManager):
    """Gestor personalizado para el modelo Usuario.

    Permite crear usuarios normales y superusuarios usando el
    email como campo de identificación en lugar del nombre de usuario.
    """

    def create_user(self, email, password=None, **extra_fields):
        """Crea y guarda un usuario con email y contraseña.

        Args:
            email: Dirección de correo electrónico del usuario (obligatoria).
            password: Contraseña en texto plano (se almacena hasheada).
            **extra_fields: Campos adicionales del modelo Usuario.

        Returns:
            Instancia de Usuario guardada en la base de datos.

        Raises:
            ValueError: Si el email no se proporciona.
        """
        if not email:
            raise ValueError('El email es obligatorio')
        email = self.normalize_email(email)
        user = self.model(email=email, **extra_fields)
        user.set_password(password)
        user.save(using=self._db)
        return user

    def create_superuser(self, email, password=None, **extra_fields):
        """Crea y guarda un superusuario con is_staff e is_superuser activos.

        Args:
            email: Dirección de correo electrónico.
            password: Contraseña en texto plano.
            **extra_fields: Campos adicionales del modelo.

        Returns:
            Instancia de Usuario con privilegios de administrador.
        """
        extra_fields.setdefault('is_staff', True)
        extra_fields.setdefault('is_superuser', True)
        return self.create_user(email, password, **extra_fields)


class Usuario(AbstractBaseUser):
    """Modelo principal de usuario de la plataforma Myngo.

    Utiliza email como identificador único en lugar del nombre de usuario
    estándar de Django. El rating se actualiza mediante el sistema de votos.
    """

    class Meta:
        db_table = 'usuarios'

    nombre_usuario = models.CharField(max_length=150)
    email = models.EmailField(max_length=255, unique=True)
    es_verificado = models.BooleanField(default=False, null=True, blank=True)
    rating_actual = models.DecimalField(
        max_digits=3,
        decimal_places=2,
        default=0.00,
        null=True,
        blank=True,
    )
    fecha_registro = models.DateTimeField(auto_now_add=True)
    is_active = models.BooleanField(default=True)
    is_staff = models.BooleanField(default=False)

    objects = UsuarioManager()

    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = ['nombre_usuario']

    def __str__(self):
        return f"{self.id} - {self.nombre_usuario}"

    @property
    def url_avatar(self):
        """Retorna la URL del avatar desde el perfil asociado.

        Returns:
            URL del avatar como cadena, o None si no existe perfil o avatar.
        """
        try:
            perfil = getattr(self, 'perfil', None)
            if perfil and perfil.avatar:
                return perfil.avatar
        except Exception:
            pass
        return None

    @property
    def rating_medio(self):
        """Calcula la media de estrellas recibidas por este usuario.

        Solo se calcula si el usuario tiene al menos 10 votos; en caso
        contrario devuelve 0.0 para indicar "sin calificación suficiente".

        Returns:
            Media de estrellas redondeada a 2 decimales, o 0.0.
        """
        from mejoras.models import Voto
        votos = Voto.objects.filter(receptor_usuario=self)
        if votos.count() < 10:
            return 0.0
        media = votos.aggregate(models.Avg('estrellas'))['estrellas__avg']
        return round(float(media), 2)


class Perfil(models.Model):
    """Datos extendidos del usuario: avatar, fondo, puntos, estado online, etc.

    Relacionado 1:1 con Usuario. Se crea automáticamente al registrar
    un usuario nuevo mediante la vista de confirmación de email.
    """

    class Meta:
        db_table = 'perfiles'

    usuario = models.OneToOneField(
        Usuario,
        on_delete=models.CASCADE,
        related_name='perfil',
    )
    biografia = models.TextField(blank=True, null=True)
    avatar = models.CharField(max_length=255, null=True, blank=True)
    fondo = models.CharField(max_length=255, null=True, blank=True)
    marco = models.CharField(max_length=255, null=True, blank=True)
    estilo_post = models.JSONField(null=True, blank=True)
    puntos = models.IntegerField(
        default=0,
        validators=[MinValueValidator(0), MaxValueValidator(5000)],
        help_text="Los puntos no pueden exceder los 5,000.",
    )
    es_publico = models.BooleanField(default=True)
    last_seen = models.DateTimeField(null=True, blank=True)
    esta_online = models.BooleanField(default=False)
    fecha_actualizacion = models.DateTimeField(auto_now_add=True)
    estado = models.CharField(
        max_length=20,
        default='DESCONECTADO',
        choices=[
            ('ACTIVO', 'Activo'),
            ('DESCONECTADO', 'Desconectado'),
            ('OCUPADO', 'Ocupado'),
        ],
    )
    orden_comunidades = models.JSONField(null=True, blank=True, default=list)

    def recalcular_puntos(self):
        """Añade puntos acumulados por los días de inactividad desde el último login.

        La cantidad de puntos generados por día depende del rating actual
        del usuario. El total nunca supera el límite de 5,000 puntos.
        """
        last_login = Usuario.objects.values_list('last_login', flat=True).get(
            pk=self.usuario_id
        )
        fecha_actual = timezone.now().date()

        if last_login is None or last_login.date() < fecha_actual:
            rating = self.usuario.rating_actual
            dias_inactivo = 1
            if last_login is not None:
                dias_inactivo = (fecha_actual - last_login.date()).days

            puntos_por_dia = 0
            match rating:
                case m if 0 <= m <= 1:
                    puntos_por_dia = 20
                case m if 1 < m <= 2:
                    puntos_por_dia = 80
                case m if 2 < m <= 3:
                    puntos_por_dia = 100
                case m if 3 < m <= 4:
                    puntos_por_dia = 150
                case m if 4 < m <= 4.5:
                    puntos_por_dia = 170
                case m if m > 4.5:
                    puntos_por_dia = 200

            puntos_nuevos = puntos_por_dia * dias_inactivo
            self.puntos = min(self.puntos + puntos_nuevos, 5000)
            self.save()

    def __str__(self):
        return f"Perfil de {self.usuario.nombre_usuario}"


class Seguimiento(models.Model):
    """Relación de seguimiento entre usuarios o entre usuario y comunidad.

    También se utiliza para gestionar solicitudes pendientes en perfiles
    privados y comunidades privadas (estado 'SOLICITUD' → 'ACEPTADO').
    """

    class Meta:
        db_table = 'seguimientos'

    seguidor = models.ForeignKey(
        Usuario,
        on_delete=models.CASCADE,
        related_name='siguiendo',
    )
    seguido_usuario = models.ForeignKey(
        Usuario,
        on_delete=models.CASCADE,
        related_name='seguidores',
        null=True,
        blank=True,
    )
    seguida_comunidad = models.ForeignKey(
        'comunidades.Comunidad',
        on_delete=models.CASCADE,
        related_name='seguidores',
        null=True,
        blank=True,
    )
    estado = models.CharField(
        max_length=20,
        default='SOLICITUD',
        choices=[
            ('ACEPTADO', 'Aceptado'),
            ('SOLICITUD', 'Solicitud'),
            ('DENEGADO', 'Denegado'),
        ],
    )
    fecha_seguimiento = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        destino = (
            self.seguido_usuario.nombre_usuario
            if self.seguido_usuario
            else getattr(self.seguida_comunidad, 'nombre', '?')
        )
        return f"{self.seguidor.nombre_usuario} → {destino} ({self.estado})"
