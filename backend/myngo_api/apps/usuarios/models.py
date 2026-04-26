from django.db import models
from django.contrib.auth.models import AbstractBaseUser, BaseUserManager
from django.core.validators import MaxValueValidator, MinValueValidator
from django.utils import timezone
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

    @property
    def url_avatar(self):
        """
        Retorna la URL del avatar desde el perfil asociado.
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
        from mejoras.models import Voto
        """
        Calcula la media de estrellas recibidas por este usuario.
        """
        votos = Voto.objects.filter(receptor_usuario=self)
        if votos.count() < 10:
            return 0.0 # O podrías devolver None, pero 0.0 indica "sin calificar" en la UI de Myngo
        
        media = votos.aggregate(models.Avg('estrellas'))['estrellas__avg']
        return round(float(media), 2)

class Perfil(models.Model):

    class Meta:
        db_table = 'perfiles'
    usuario=models.OneToOneField(Usuario, on_delete=models.CASCADE, related_name='perfil')
    biografia=models.TextField(blank=True, null=True)
    avatar=models.CharField(max_length=255,null=True,blank=True)
    fondo=models.CharField(max_length=255,null=True,blank=True)
    marco=models.CharField(max_length=255,null=True,blank=True)
    estilo_post=models.JSONField(null=True,blank=True)
    puntos = models.IntegerField(
        default=0,
        validators=[
            MinValueValidator(0),       # No permite puntos negativos
            MaxValueValidator(5000)     # Máximo permitido: 5,000
        ],
        help_text="Los puntos no pueden exceder los 5,000."
    )
    es_publico=models.BooleanField(default=True)
    last_seen=models.DateTimeField(null=True, blank=True)
    esta_online=models.BooleanField(default=False)
    fecha_actualizacion=models.DateTimeField(auto_now_add=True)
    estado=models.CharField(max_length=20, default='DESCONECTADO', choices=[
        ('ACTIVO', 'Activo'),
        ('DESCONECTADO', 'Desconectado'),
        ('OCUPADO', 'Ocupado'),
    ])
    #Metodo que recalcula los puntos generados por ese perfil en los días inactivos
    #sin pasarse del limite de 5.000 puntos
    def recalcular_puntos(self):
        last_login=Usuario.objects.values_list('last_login', flat=True).get(pk=self.usuario_id)
        fecha_actual=timezone.now().date()#saco la fecha actual
        if last_login is None or last_login.date() < fecha_actual:#si no hay ultimo login o no es hoy
            rating=self.usuario.rating_actual#saco el rating
            dias_inactivo=1#dias inactivo por defecto 1 para que sume algo la primera vez
            if last_login is not None:#si hay login
                dias_inactivo=(fecha_actual-last_login.date()).days#saco la diferencia en dias
            puntos=0#para almacenar los puntos a sumar
            #dependiendo del rating genera unos puntos
            match rating:
                case m if 0 <= m <= 1:
                    puntos+=20
                case m if 1 < m <= 2:
                    puntos+=80
                case m if 2 < m <= 3:
                    puntos+=100
                case m if 3< m <=4:
                    puntos+=150
                case m if 4<m <=4.5:
                    puntos+=170
                case m if m > 4.5:
                    puntos+=200
            #los nuevos puntos a sumar son los puntos por los dias inactivos
            puntos_nuevos=puntos*dias_inactivo
            #sacamos el minimo para nunca tener mas de 5.000 puntos
            self.puntos = min(self.puntos + puntos_nuevos, 5000)
            #actualizamos la base de datos
            self.save()
    def __str__(self):
        return f"Perfil de {self.usuario.nombre_usuario}"
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
