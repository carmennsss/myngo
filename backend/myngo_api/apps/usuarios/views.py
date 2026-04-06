from django.http import HttpResponse
from .serializers import UsuarioSerializer,SeguimientoSerializer,PerfilSerializer
from .models import Usuario,Seguimiento,Perfil
from notificaciones.models import Notificacion
from rest_framework.response import Response
from rest_framework import status,generics,filters
from rest_framework.views import APIView
from django.core.mail import send_mail
from django.conf import settings
from django.template.loader import render_to_string
from django.utils.html import strip_tags
import random
import string
from rest_framework.permissions import IsAuthenticated, AllowAny, IsAuthenticatedOrReadOnly
from django.core.signing import TimestampSigner, SignatureExpired, BadSignature
from django.core.cache import cache
from contenido.models import Imagenes_galeria
from django.utils import timezone
signer = TimestampSigner()
class RegistroUsuarios(APIView):
    """
    Vista para el registro de nuevos usuarios en la plataforma.
    """
    def post(self, request):
        
        """
        Procesa la creación de un nuevo usuario a partir de los datos recibidos.
        
        Devuelve una respuesta exitosa con los datos del usuario creado o 
        una lista de errores de validación si la solicitud es incorrecta.
        """
        serializer = UsuarioSerializer(data=request.data)
        
        if serializer.is_valid():
        
            datos_usuario = request.data
            token = signer.sign_object(datos_usuario)
            url_activacion = f"http://localhost:8000/usuarios/confirmar/{token}/"
            sujeto = 'Bienvenido a Myngo 🐾 - Activa tu cuenta'
            # Usamos un botón morado como el de tu app
            mensaje_html = f"""
            <div style="font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; max-width: 600px; margin: auto; border: 1px solid #e0e0e0; border-radius: 15px; padding: 25px; text-align: center; background-color: #ffffff;">
                <h2 style="color: #6C63FF; margin-bottom: 10px;">¡Hola de nuevo!</h2>
                <p style="color: #666; font-size: 16px;">Ya casi eres parte de la comunidad de <strong>Myngo</strong>. Solo falta un último paso para activar tu cuenta.</p>
                
                <div style="margin: 30px 0;">
                    <a href="{url_activacion}" 
                    style="background-color: #6C63FF; color: white; padding: 15px 30px; text-decoration: none; border-radius: 10px; font-weight: bold; font-size: 18px; display: inline-block; box-shadow: 0 4px 6px rgba(108, 99, 255, 0.2);">
                    ACTIVAR MI CUENTA 🐾
                    </a>
                </div>
                
                <p style="color: #999; font-size: 12px;">Si no te has registrado en Myngo, puedes ignorar este correo.</p>
                <hr style="border: 0; border-top: 1px solid #eee; margin: 20px 0;">
                <p style="color: #6C63FF; font-weight: bold;">El equipo de Myngo</p>
            </div>
            """
            mensaje_plano = strip_tags(mensaje_html)

            send_mail(
                sujeto,
                mensaje_plano,
                settings.EMAIL_HOST_USER,
                [datos_usuario['email']],
                html_message=mensaje_html, # IMPORTANTE: enviar la versión HTML
                fail_silently=False,
            )
                
            return Response({
                "exito": True,
                "mensaje": "Revisa tu correo para completar el registro."
            }, status=status.HTTP_200_OK)
        return Response({
            "exito": False, 
            "mensaje": "Error en la validación",
            "errores": serializer.errors
        }, status=status.HTTP_400_BAD_REQUEST) 
    def get(self,request,token):
        try:
            # 1. Abrimos el paquete (token). Si alguien lo tocó, saltará BadSignature.
            # max_age=3600 hace que el link caduque en 1 hora.
            datos_usuario = signer.unsign_object(token, max_age=3600)
            
            # 2. Ahora que el email está verificado, CREAMOS al usuario
            datos_limpios = datos_usuario.copy()
            # Quitamos los campos que no son del modelo si existen
            # Para robustez, buscamos tanto 'password' como 'contrasena'
            password = datos_limpios.pop('password', datos_limpios.pop('contrasena', None))
            
            usuario = Usuario.objects.create_user(
                email=datos_limpios['email'],
                password=password,
                nombre_usuario=datos_limpios['nombre_usuario']
            )
            perfil=Perfil.objects.create(usuario=usuario,biografia="",url_avatar="",puntos=0)
            return HttpResponse(f"""
    <html>
        <head>
            <style>
                body {{ font-family: 'Segoe UI', sans-serif; background-color: #F7F4FF; display: flex; align-items: center; justify-content: center; height: 100vh; margin: 0; }}
                .card {{ background: white; padding: 40px; border-radius: 20px; box-shadow: 0 10px 25px rgba(0,0,0,0.1); text-align: center; max-width: 400px; }}
                h1 {{ color: #6C63FF; margin-bottom: 20px; }}
                p {{ color: #666; line-height: 1.6; }}
                .btn {{ display: inline-block; margin-top: 25px; padding: 12px 25px; background: #6C63FF; color: white; text-decoration: none; border-radius: 10px; font-weight: bold; }}
            </style>
        </head>
        <body>
            <div class="card">
                <h1>¡Cuenta Activada! 🐾</h1>
                <p>Tu registro en <b>Myngo</b> se ha completado con éxito. Ya puedes cerrar esta ventana y volver a la aplicación para iniciar sesión.</p>
                <div style="font-size: 50px; margin: 20px 0;">🐱</div>
                <p style="font-size: 12px; color: #aaa;">¡Nos vemos dentro!</p>
            </div>
        </body>
    </html>
    """)
            return HttpResponse("<h1>Error: Los datos ya no son válidos.</h1>", status=400)
            
        except SignatureExpired:
            return HttpResponse("<h1>Enlace caducado o inválido.</h1>", status=400)
        except BadSignature:
            return HttpResponse("<h1>Enlace caducado o inválido.</h1>", status=400)

class LoginUsuario(APIView):
    def post(self, request):
        email = request.data.get('email')
        password = request.data.get('password') or request.data.get('contrasena')
        
        # 1. Clave de intentos
        key = f"login_attempts:{email}"
        
        # 2. Obtener intentos 
        intentos = cache.get(key, 0)

        if intentos >= 3:
            return Response({
                "exito": False,
                "mensaje": "Cuenta bloqueada temporalmente por seguridad. Inténtalo más tarde (máx. 1 hora)."
            }, status=status.HTTP_403_FORBIDDEN)
        
        if not email or not password:
            return Response({
                "exito": False,
                "mensaje": "Email y contraseña son obligatorios"
            }, status=status.HTTP_400_BAD_REQUEST)

        try:
            usuario = Usuario.objects.get(email=email)
            if usuario.check_password(password): 
                # SI EL LOGIN ES CORRECTO -> REINICIAMOS INTENTOS
                cache.delete(key) # Borrar rastro al acertar
                if hasattr(usuario, 'perfil'):
                    usuario.perfil.recalcular_puntos()
                usuario.last_login = timezone.now()
                usuario.save(update_fields=['last_login'])
                from rest_framework.authtoken.models import Token
                token, _ = Token.objects.get_or_create(user=usuario)
                
                serializer = UsuarioSerializer(usuario)
                return Response({
                    "exito": True,
                    "mensaje": "Inicio de sesión exitoso",
                    "token": token.key,
                    "datos": serializer.data
                }, status=status.HTTP_200_OK)
            else: 
                # FALLO DE CONTRASEÑA
                intentos += 1
                cache.set(key, intentos, timeout=3600)
                
                restantes = 3 - intentos
                return Response({
                    "exito": False,
                    "mensaje": f"Contraseña incorrecta. Te quedan {restantes} intentos."
                }, status=status.HTTP_401_UNAUTHORIZED)

        except Usuario.DoesNotExist:
            return Response({
                "exito": False,
                "mensaje": "Usuario no encontrado"
            }, status=status.HTTP_404_NOT_FOUND)
class SeguimientoUsuarios(APIView):
    def post(self,request):
        serializer=SeguimientoSerializer(data=request.data)
        if(serializer.is_valid()):
            serializer.save()
            return Response({
                "exito":True,
                "mensaje":"Seguimiento creado",
                "datos":serializer.data
            },status=status.HTTP_201_CREATED)
        else:
             return Response({
                "exito": False,
                "errores": serializer.errors
            }, status=status.HTTP_400_BAD_REQUEST)
    def put(self,request):
        seguimiento_id=request.data.get('id')
        estado=request.data.get('estado', '')
        try:
            seguimiento=Seguimiento.objects.get(id=seguimiento_id)
            if estado.upper() not in ['ACEPTADO','DENEGADO']:
                raise ValueError(f"¡Error! La cadena '{estado}' no es una opcion valida'")
            else:
                serializer=SeguimientoSerializer(seguimiento,data=request.data,partial=True)
                if serializer.is_valid():
                    serializer.save()
                    return Response({
                        "exito":True,
                        "mensaje":"Seguimiento actualizado en estado",
                        "datos":serializer.data
                    })
                return Response({"exito": False, "errores": serializer.errors}, status=400)
        except Seguimiento.DoesNotExist:
            return Response({
                "exito": False,
                "errores": "No existe un seguimiento con el ID proporcionado."
            }, status=status.HTTP_404_NOT_FOUND)
        except Exception as e:
             return Response({
                "exito": False,
                "errores": str(e)
            }, status=status.HTTP_400_BAD_REQUEST)
        
class DatosUsuarios(APIView):
    permission_classes = [AllowAny]
    
    def get(self,request,usuario_id=None):
        if usuario_id:
            usuario=Usuario.objects.get(id=usuario_id)
            if usuario:
                serializer=UsuarioSerializer(usuario)
                return Response({
                    "exito":True,
                    "mensaje": f"Los datos del usuario {usuario_id}",
                    "datos":serializer.data
                })
            else:
                return Response({
                    "exito":False,
                    "mensaje": f"No existe el usuario con id {usuario_id}",
                },status=status.HTTP_404_NOT_FOUND)
        else:
            usuarios=Usuario.objects.all()
            # EXCLUIR AL USUARIO LOGUEADO
            if request.user and request.user.is_authenticated:
                usuarios = usuarios.exclude(id=request.user.id)
                
            if usuarios:
                serializer=UsuarioSerializer(usuarios,many=True)
                return Response({
                    "exito":True,
                    "mensaje":"Todos los usuarios del sistema",
                    "datos":serializer.data
                })
            else:
                return Response({
                    "exito":False,
                    "mensaje":"No hay usuarios en el sistema",
                },status=status.HTTP_204_NO_CONTENT)
    def put(self,request):
        usuario_id=request.data.get('id')
        try:
            usuario=Usuario.objects.get(id=usuario_id)
            serializer = UsuarioSerializer(usuario, data=request.data, partial=True)
            if serializer.is_valid():
                serializer.save()
                return Response({
                    "exito": True, 
                    "mensaje": "usuario actualizado", 
                    "datos": serializer.data
                })
            return Response({"exito": False, "errores": serializer.errors}, status=400)
        except Usuario.DoesNotExist:
            return Response({
                "exito": False,
                "errores": "No existe un usuario con el ID proporcionado."
            }, status=status.HTTP_404_NOT_FOUND)  
        except Exception as e:
             return Response({
                "exito": False,
                "errores": str(e)
            }, status=status.HTTP_400_BAD_REQUEST)  

class GestionPerfiles(generics.ListCreateAPIView):
    """
    Esta clase sirve para listar todos los perfiles o crear uno nuevo.
    Excluye al propio usuario para no poder seguirse a sí mismo.
    Soporta búsqueda por nombre.
    """
    serializer_class = PerfilSerializer
    filter_backends = [filters.SearchFilter]
    search_fields = ['usuario__nombre_usuario']
    permission_classes = [IsAuthenticatedOrReadOnly]
    
    def get_queryset(self):
        # Obtenemos todos los perfiles
        perfiles = Perfil.objects.all().order_by('-fecha_actualizacion')
        
        # Si el usuario está autenticado, excluimos su propio perfil
        if self.request.user and self.request.user.is_authenticated:
            perfiles = perfiles.exclude(usuario=self.request.user)
            
        return perfiles
class SeguirPerfil(APIView):
    permission_classes = [AllowAny]
    authentication_classes = []
    def post(self,request,nombre_usuario):
        if request.user and request.user.is_authenticated:
            usuario = request.user
        else:
            # Fallback para pruebas anónimas
            usuario = Usuario.objects.filter(pk=1).first() or Usuario.objects.first()
        
        try:
            perfil=Perfil.objects.get(usuario__nombre_usuario=nombre_usuario)
        except Perfil.DoesNotExist:
             return Response({"error": "El perfil no existe"}, status=status.HTTP_404_NOT_FOUND)

        if perfil.usuario == usuario:
            return Response({"error": "No puedes seguirte a ti mismo"}, status=status.HTTP_400_BAD_REQUEST)
        
        seguimiento=Seguimiento.objects.filter(seguidor=usuario,seguido_usuario=perfil.usuario).first()
        if seguimiento:#Si existe
            if seguimiento.estado == "SOLICITUD":#si esta en solcitud
                return Response({"mensaje":"Ya has mandado una solcitud a este usuario"},status=status.HTTP_200_OK)
            elif seguimiento.estado == "DENEGADO":#Si esta denegado se vuelve a enviar
                seguimiento.estado="SOLICITUD"
                seguimiento.save()
                return Response({"mensaje": "Solicitud reintentada", "estado": seguimiento.estado}, status=status.HTTP_200_OK)
            else:#Si esta aceptado deja de seguir
                seguimiento.delete()
                return Response({"mensaje":"Has dejado de seguir a este usuario", "estado": None}, status=status.HTTP_200_OK)
        else:#Si no existe
            estado = "ACEPTADO" if perfil.es_publico else "SOLICITUD"
            seguimiento=Seguimiento.objects.create(seguidor=usuario,seguido_usuario=perfil.usuario,estado=estado)
            if not perfil.es_publico and seguimiento.estado == "SOLICITUD":
                notificacion=Notificacion.objects.create(
                usuario=perfil.usuario,
                tipo="PETICION_UNION",
                mensaje=f"¡Miau! {usuario.nombre_usuario} quiere seguirte.",
                referencia_usuario=usuario,
                referencia_id=seguimiento.id
            )
            mensaje = "Has seguido a este perfil" if perfil.es_publico else "Solicitud enviada a al perfil"
            return Response({"mensaje": mensaje, "estado": seguimiento.estado}, status=status.HTTP_201_CREATED)
            
class ResponderPeticionUnion(APIView):
    """
    Permite al administrador de una comunidad aceptar o rechazar una petición de unión.
    """
    permission_classes = [IsAuthenticated]

    def post(self, request, pk):
        try:
            # LAS PETICIONES PENDIENTES ESTÁN EN SEGUIMIENTO
            peticion = Seguimiento.objects.get(pk=pk)
        except Seguimiento.DoesNotExist:
            return Response({"error": "La petición no existe"}, status=status.HTTP_404_NOT_FOUND)

        if peticion.seguido_usuario!= request.user:
            return Response({"error": "No tienes permiso"}, status=status.HTTP_403_FORBIDDEN)

        aceptar = request.data.get('aceptar', False)
        
        if aceptar:
            # 1. Crear el registro oficial de miembro
            peticion.estado="ACEPTADO"
            peticion.save()
            # 2. Notificar y borrar la petición (para no duplicar)
            Notificacion.objects.create(
                usuario=peticion.seguidor,
                tipo="PETICION_ACEPTADA",
                mensaje=f"¡Miau! El usuario '{peticion.seguido_usuario.nombre_usuario}' ha aceptado la solicitud de amistad.",
                referencia_usuario=peticion.seguido_usuario
            )
        else:
            # Si se rechaza, la marcamos como DENEGADO en Seguimiento
            peticion.estado = "DENEGADO"
            peticion.save()
            
        # 3. Marcar la notificación original de esta petición como leída
        from notificaciones.models import Notificacion as NotifModelo
        NotifModelo.objects.filter(
            usuario=request.user, 
            tipo="PETICION_UNION", 
            referencia_id=peticion.id
        ).update(leida=True)
            
        return Response({"mensaje": "Respuesta enviada"}, status=status.HTTP_200_OK)

class RecuperarPassword(APIView):
    """
    Vista para gestionar la recuperación de contraseña mediante envío de email.
    """
    def post(self, request):
        """
        Recibe un email, genera un código temporal y envía un correo personalizado.
        """
        email = request.data.get('email')

        if not email:
            return Response({
                "exito": False,
                "mensaje": "El email es obligatorio"
            }, status=status.HTTP_400_BAD_REQUEST)

        try:
            usuario = Usuario.objects.get(email=email)
            
            codigo = ''.join(random.choices(string.ascii_uppercase + string.digits, k=6))
            
           
            usuario.set_password(codigo)
            usuario.save()

            # Personalización del correo
            sujeto = 'Recupera tu acceso a Myngo 🐾'
            mensaje_html = f"""
            <div style="font-family: Arial, sans-serif; max-width: 600px; margin: auto; border: 1px solid #ddd; border-radius: 10px; padding: 20px;">
                <h2 style="color: #6C63FF; text-align: center;">¡Hola, {usuario.nombre_usuario}!</h2>
                <p style="font-size: 16px; color: #333;">
                    Hemos recibido una solicitud para restablecer tu contraseña en <strong>Myngo</strong>. 
                    No te preocupes, ¡nos pasa a todos!
                </p>
                <div style="background-color: #f9f9f9; padding: 15px; border-radius: 8px; text-align: center; margin: 20px 0;">
                    <p style="font-size: 14px; color: #666; margin-bottom: 10px;">Tu nueva contraseña temporal es:</p>
                    <span style="font-size: 24px; font-weight: bold; color: #6C63FF; letter-spacing: 2px;">{codigo}</span>
                </div>
                <p style="font-size: 14px; color: #555;">
                    Te recomendamos iniciar sesión con esta contraseña y cambiarla por una nueva en tu perfil lo antes posible.
                </p>
                <hr style="border: 0; border-top: 1px solid #eee; margin: 20px 0;">
                <p style="font-size: 12px; color: #999; text-align: center;">
                    Si no solicitaste este cambio, puedes ignorar este correo o contactar con soporte en myngoadmin@gmail.com.
                </p>
                <div style="text-align: center; margin-top: 20px;">
                    <span style="font-size: 18px;">🐾 Myngo Team</span>
                </div>
            </div>
            """
            mensaje_plano = strip_tags(mensaje_html)
            
            try:
                send_mail(
                    sujeto,
                    mensaje_plano,
                    settings.EMAIL_HOST_USER,
                    [email],
                    html_message=mensaje_html,
                    fail_silently=False,
                )
                
                return Response({
                    "exito": True,
                    "mensaje": "Correo de recuperación enviado con éxito"
                }, status=status.HTTP_200_OK)
                
            except Exception as e:
                return Response({
                    "exito": False,
                    "mensaje": f"Error al enviar el correo: {str(e)}"
                }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

        except Usuario.DoesNotExist:
            return Response({
                "exito": False,
                "mensaje": "No existe ningún usuario registrado con ese email"
            }, status=status.HTTP_404_NOT_FOUND)
        
class EditarPerfil(APIView):
    permission_classes = [IsAuthenticated]
    def patch(self,request):
        perfil_id = request.data.get('perfil_id')
        imagen = request.FILES.get('url_avatar')
        if perfil_id:
            try:
                perfil = Perfil.objects.get(id=perfil_id)
            except Perfil.DoesNotExist:
                return Response({
                    "exito": False,
                    "mensaje": "No existe ningún perfil registrado con ese id"
                }, status=status.HTTP_404_NOT_FOUND)
            if imagen:
                    imagen_nueva=Imagenes_galeria.objects.create(propietario=request.user,
                    comunidad_id=request.data.get('comunidad') or None,
                    relacion_aspecto=float(request.data.get('relacion_aspecto', 1.0)),
                    etiquetas=request.data.get('etiquetas', ''),)
                    
                    if request.data.get('es_perfil'):
                        imagen_nueva._es_avatar = True
                    imagen_nueva.url_s3=imagen
                    imagen_nueva.save()
                    perfil.imagen=imagen_nueva
            serializer = PerfilSerializer(perfil, data=request.data, partial=True)
            if serializer.is_valid():
                serializer.save()
                
                # Construimos la URL completa para devolverla a Flutter
                url_avatar = None
                if perfil.imagen and perfil.imagen.url_s3:
                    url_avatar = request.build_absolute_uri(perfil.imagen.url_s3.url)
                    
                return Response({
                    "exito": True,
                    "mensaje": "Perfil actualizado correctamente",
                    "url_avatar": url_avatar,
                    "datos": serializer.data
                }, status=status.HTTP_200_OK)
            
            return Response({
                "exito": False,
                "errores": serializer.errors
            }, status=status.HTTP_400_BAD_REQUEST)


        else:
            return Response({
                "exito":False,
                "mensaje":"No se ha enviado ningun perfil para editar"
            },status=status.HTTP_400_BAD_REQUEST)

    
