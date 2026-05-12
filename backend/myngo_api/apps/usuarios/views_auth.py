"""Vistas de autenticación: registro, confirmación por email, login y recuperación de contraseña."""

import random
import string

from django.conf import settings
from django.core.cache import cache
from django.core.signing import BadSignature, SignatureExpired, TimestampSigner
from django.http import HttpResponse
from django.utils import timezone
from django.utils.html import strip_tags
from django.core.mail import send_mail
from rest_framework import status
from rest_framework.authtoken.models import Token
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import Perfil, Usuario
from .serializers import UsuarioSerializer

_firmador = TimestampSigner()


class RegistroUsuarios(APIView):
    """Vista para el registro de nuevos usuarios en la plataforma.

    El proceso es de dos pasos: primero se validan los datos y se envía
    un email de confirmación con un token firmado. Cuando el usuario
    hace clic en el enlace, se crea la cuenta definitivamente.
    """

    def post(self, request):
        """Valida los datos y envía el email de activación.

        Args:
            request: Petición POST con los datos del nuevo usuario.

        Returns:
            Response con ``exito: True`` si el email se envió, o errores
            de validación si los datos son incorrectos.
        """
        serializer = UsuarioSerializer(data=request.data)
        if serializer.is_valid():
            datos_usuario = request.data
            token = _firmador.sign_object(datos_usuario)
            url_activacion = f"{settings.API_URL}/usuarios/confirmar/{token}/"
            sujeto = 'Bienvenido a Myngo 🐾 - Activa tu cuenta'
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
            send_mail(
                sujeto,
                strip_tags(mensaje_html),
                settings.EMAIL_HOST_USER,
                [datos_usuario['email']],
                html_message=mensaje_html,
                fail_silently=False,
            )
            return Response(
                {'exito': True, 'mensaje': 'Revisa tu correo para completar el registro.'},
                status=status.HTTP_200_OK,
            )
        return Response(
            {'exito': False, 'mensaje': 'Error en la validación', 'errores': serializer.errors},
            status=status.HTTP_400_BAD_REQUEST,
        )

    def get(self, request, token):
        """Confirma la cuenta del usuario a partir del token del email.

        Args:
            request: Petición GET con el token en la URL.
            token: Token firmado que contiene los datos del nuevo usuario.

        Returns:
            HttpResponse HTML con el resultado de la activación.
        """
        try:
            datos_usuario = _firmador.unsign_object(token, max_age=3600)
            datos_limpios = datos_usuario.copy()
            password = datos_limpios.pop('password', datos_limpios.pop('contrasena', None))
            usuario = Usuario.objects.create_user(
                email=datos_limpios['email'],
                password=password,
                nombre_usuario=datos_limpios['nombre_usuario'],
            )
            Perfil.objects.create(usuario=usuario, biografia='', puntos=0)
            return HttpResponse("""
    <html>
        <head>
            <style>
                body { font-family: 'Segoe UI', sans-serif; background-color: #F7F4FF; display: flex; align-items: center; justify-content: center; height: 100vh; margin: 0; }
                .card { background: white; padding: 40px; border-radius: 20px; box-shadow: 0 10px 25px rgba(0,0,0,0.1); text-align: center; max-width: 400px; }
                h1 { color: #6C63FF; margin-bottom: 20px; }
                p { color: #666; line-height: 1.6; }
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
        except SignatureExpired:
            return HttpResponse('<h1>Enlace caducado o inválido.</h1>', status=400)
        except BadSignature:
            return HttpResponse('<h1>Enlace caducado o inválido.</h1>', status=400)


class LoginUsuario(APIView):
    """Vista de inicio de sesión con protección ante intentos repetidos.

    Bloquea la cuenta durante 1 hora tras 3 intentos fallidos consecutivos.
    Al iniciar sesión correctamente, recalcula los puntos acumulados por inactividad.
    """

    def post(self, request):
        """Autentica al usuario y devuelve el token de sesión.

        Args:
            request: Petición POST con ``email`` y ``password``.

        Returns:
            Response con el token y los datos del usuario, o error descriptivo.
        """
        email = request.data.get('email')
        password = request.data.get('password') or request.data.get('contrasena')
        clave_intentos = f"login_attempts:{email}"
        intentos = cache.get(clave_intentos, 0)

        if intentos >= 3:
            return Response(
                {
                    'exito': False,
                    'mensaje': 'Cuenta bloqueada temporalmente por seguridad. Inténtalo más tarde (máx. 1 hora).',
                },
                status=status.HTTP_403_FORBIDDEN,
            )

        if not email or not password:
            return Response(
                {'exito': False, 'mensaje': 'Email y contraseña son obligatorios'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        try:
            usuario = Usuario.objects.get(email=email)
            if usuario.check_password(password):
                cache.delete(clave_intentos)
                
                # Intentamos recalcular puntos, pero si falla no bloqueamos el login
                if hasattr(usuario, 'perfil'):
                    try:
                        usuario.perfil.recalcular_puntos()
                    except Exception:
                        pass
                
                usuario.last_login = timezone.now()
                usuario.save(update_fields=['last_login'])
                token, _ = Token.objects.get_or_create(user=usuario)
                serializer = UsuarioSerializer(usuario, context={'request': request})
                return Response(
                    {
                        'exito': True,
                        'mensaje': 'Inicio de sesión exitoso',
                        'token': token.key,
                        'datos': serializer.data,
                    },
                    status=status.HTTP_200_OK,
                )
            intentos += 1
            cache.set(clave_intentos, intentos, timeout=3600)
            restantes = 3 - intentos
            return Response(
                {'exito': False, 'mensaje': f'Contraseña incorrecta. Te quedan {restantes} intentos.'},
                status=status.HTTP_401_UNAUTHORIZED,
            )
        except Usuario.DoesNotExist:
            return Response(
                {'exito': False, 'mensaje': 'Usuario no encontrado'},
                status=status.HTTP_404_NOT_FOUND,
            )


class RecuperarPassword(APIView):
    """Vista para gestionar la recuperación de contraseña mediante envío de email.

    Genera una contraseña temporal aleatoria, la asigna al usuario y la envía
    por correo. Se recomienda cambiarla al iniciar sesión.
    """

    def post(self, request):
        """Recibe un email, genera un código temporal y envía un correo personalizado.

        Args:
            request: Petición POST con el campo ``email``.

        Returns:
            Response con ``exito: True`` si el correo se envió correctamente.
        """
        email = request.data.get('email')
        if not email:
            return Response(
                {'exito': False, 'mensaje': 'El email es obligatorio'},
                status=status.HTTP_400_BAD_REQUEST,
            )
        try:
            usuario = Usuario.objects.get(email=email)
            codigo = ''.join(random.choices(string.ascii_uppercase + string.digits, k=6))
            usuario.set_password(codigo)
            usuario.save()
            sujeto = 'Recupera tu acceso a Myngo 🐾'
            mensaje_html = f"""
            <div style="font-family: Arial, sans-serif; max-width: 600px; margin: auto; border: 1px solid #ddd; border-radius: 10px; padding: 20px;">
                <h2 style="color: #6C63FF; text-align: center;">¡Hola, {usuario.nombre_usuario}!</h2>
                <p style="font-size: 16px; color: #333;">
                    Hemos recibido una solicitud para restablecer tu contraseña en <strong>Myngo</strong>.
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
            try:
                send_mail(
                    sujeto,
                    strip_tags(mensaje_html),
                    settings.EMAIL_HOST_USER,
                    [email],
                    html_message=mensaje_html,
                    fail_silently=False,
                )
                return Response(
                    {'exito': True, 'mensaje': 'Correo de recuperación enviado con éxito'},
                    status=status.HTTP_200_OK,
                )
            except Exception as e:
                return Response(
                    {'exito': False, 'mensaje': f'Error al enviar el correo: {str(e)}'},
                    status=status.HTTP_500_INTERNAL_SERVER_ERROR,
                )
        except Usuario.DoesNotExist:
            return Response(
                {'exito': False, 'mensaje': 'No existe ningún usuario registrado con ese email'},
                status=status.HTTP_404_NOT_FOUND,
            )
