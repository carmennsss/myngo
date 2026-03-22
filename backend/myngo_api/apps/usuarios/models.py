from django.db import models
from django.contrib.auth.models import AbstractBaseUser, BaseUserManager
from django.core.validators import MaxValueValidator, MinValueValidator

class UsuarioManager(BaseUserManager):
    def create_user(self, email, password=None, **extra_fields):
        if not email:
            raise ValueError('El email es obligatorio')
        email = self.normalize_email(email)
        user = self.model(email=email, **extra_fields)
        user.set_password(password)
        user.save(using=self._db)
        return user

    def create_superuser(self, email, password=None, **extra_fields):
        extra_fields.setdefault('is_staff', True)
        extra_fields.setdefault('is_superuser', True)
        return self.create_user(email, password, **extra_fields)

class Usuario(AbstractBaseUser):
    class Meta:
        db_table = 'usuarios'
    nombre_usuario = models.CharField(max_length=150)
    email = models.EmailField(max_length=255, unique=True)
    # Django utiliza 'password' internamente, pero mantendremos una referencia 
    # si es necesario o simplemente usaremos el de AbstractBaseUser.
    es_verificado = models.BooleanField(default=False, null=True, blank=True)
    rating_actual = models.DecimalField(max_digits=3, decimal_places=2, default=0.00, 
        null=True, 
        blank=True)
    fecha_registro = models.DateTimeField(auto_now_add=True)
    is_active = models.BooleanField(default=True)
    is_staff = models.BooleanField(default=False)

    objects = UsuarioManager()

    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = ['nombre_usuario']

    def __str__(self):
        return f"{self.id} - {self.nombre_usuario}"

class Perfil(models.Model):
    class Meta:
        db_table = 'perfiles'
    usuario=models.OneToOneField(Usuario, on_delete=models.CASCADE, related_name='perfil')
    biografia=models.TextField(blank=True, null=True)
    url_avatar=models.URLField(max_length=500, blank=True, null=True)
    puntos = models.IntegerField(
        default=0,
        validators=[
            MinValueValidator(0),       # No permite puntos negativos
            MaxValueValidator(5000)     # Máximo permitido: 5,000
        ],
        help_text="Los puntos no pueden exceder los 5,000."
    )
    es_publico=models.BooleanField(default=True)
    fecha_actualizacion=models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self # TODO
class Seguimiento(models.Model):
    class Meta:
        db_table = 'seguimientos'
    seguidor=models.ForeignKey(Usuario,on_delete=models.CASCADE,related_name='siguiendo')
    seguido_usuario=models.ForeignKey(Usuario, on_delete=models.CASCADE, related_name='seguidores', null=True, blank=True)
    seguida_comunidad = models.ForeignKey('comunidades.Comunidad', on_delete=models.CASCADE, related_name='seguidores', null=True, blank=True)
    estado = models.CharField(
        max_length=20, 
        default='SOLICITUD',
        choices=[
            ('ACEPTADO', 'Aceptado'),
            ('SOLICITUD', 'Solicitud'),
            ('DENEGADO', 'Denegado'),
        ]
    )
    fecha_seguimiento=models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self # TODO
