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
            url_activacion = f"{settings.FRONTEND_URL}/usuarios/confirmar/{token}/"
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
            return Response(
                {'exito': True, 'mensaje': 'Cuenta activada con éxito. Ya puedes iniciar sesión.'},
                status=status.HTTP_201_CREATED,
            )
        except SignatureExpired:
            return Response({'exito': False, 'mensaje': 'Enlace caducado.'}, status=status.HTTP_400_BAD_REQUEST)
        except (BadSignature, Exception) as e:
            return Response({'exito': False, 'mensaje': 'Enlace inválido o error en la activación.'}, status=status.HTTP_400_BAD_REQUEST)


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
            token = _firmador.sign_object({'email': email})
            url_recuperacion = f"{settings.FRONTEND_URL}/usuarios/recuperar-confirmar/{token}/"
            
            sujeto = 'Recupera tu acceso a Myngo 🐾'
            mensaje_html = f"""
            <div style="font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; max-width: 600px; margin: auto; border: 1px solid #e0e0e0; border-radius: 15px; padding: 25px; text-align: center; background-color: #ffffff;">
                <h2 style="color: #6C63FF; margin-bottom: 10px;">¡Hola, {usuario.nombre_usuario}!</h2>
                <p style="color: #666; font-size: 16px;">Hemos recibido una solicitud para restablecer tu contraseña en <strong>Myngo</strong>.</p>
                <div style="margin: 30px 0;">
                    <a href="{url_recuperacion}" 
                    style="background-color: #6C63FF; color: white; padding: 15px 30px; text-decoration: none; border-radius: 10px; font-weight: bold; font-size: 18px; display: inline-block; box-shadow: 0 4px 6px rgba(108, 99, 255, 0.2);">
                    RESTABLECER CONTRASEÑA 🐾
                    </a>
                </div>
                <p style="color: #999; font-size: 12px;">Si no solicitaste este cambio, puedes ignorar este correo. Tu contraseña actual no cambiará hasta que pulses el botón.</p>
                <hr style="border: 0; border-top: 1px solid #eee; margin: 20px 0;">
                <p style="color: #6C63FF; font-weight: bold;">El equipo de Myngo</p>
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


class ConfirmarRecuperacionPassword(APIView):
    """Vista para confirmar la recuperación de contraseña.
    
    Valida el token enviado por email, genera una nueva contraseña y la devuelve.
    """

    def get(self, request, token):
        """Valida el token y genera la nueva contraseña.
        
        Args:
            request: Petición GET.
            token: Token firmado con el email del usuario.
            
        Returns:
            Response con la nueva contraseña o error.
        """
        try:
            datos = _firmador.unsign_object(token, max_age=3600)
            email = datos.get('email')
            usuario = Usuario.objects.get(email=email)
            
            # Generar nueva contraseña aleatoria
            nueva_pass = ''.join(random.choices(string.ascii_letters + string.digits, k=10))
            usuario.set_password(nueva_pass)
            usuario.save()
            
            return Response({
                'exito': True,
                'mensaje': 'Contraseña restablecida con éxito',
                'nueva_password': nueva_pass
            }, status=status.HTTP_200_OK)
            
        except SignatureExpired:
            return Response({'exito': False, 'mensaje': 'El enlace ha caducado.'}, status=status.HTTP_400_BAD_REQUEST)
        except (BadSignature, Usuario.DoesNotExist):
            return Response({'exito': False, 'mensaje': 'Enlace inválido.'}, status=status.HTTP_400_BAD_REQUEST)
        except Exception as e:
            return Response({'exito': False, 'mensaje': f'Error interno: {str(e)}'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
