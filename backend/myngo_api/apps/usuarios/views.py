from django.shortcuts import render
from .serializers import UsuarioSerializer
from .models import Usuario
from rest_framework.response import Response
from rest_framework import status
from rest_framework.views import APIView
from django.core.mail import send_mail
from django.conf import settings
from django.template.loader import render_to_string
from django.utils.html import strip_tags
import random
import string

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
            serializer.save()
            return Response(
                {
                    "exito": True,
                    "mensaje": "Usuario registrado correctamente",
                    "datos": serializer.data
                },
                status=status.HTTP_201_CREATED)
        else:
            return Response({
                "exito": False,
                "errores": serializer.errors
            }, status=status.HTTP_400_BAD_REQUEST)

class LoginUsuario(APIView):
    """
    Vista para gestionar la autenticación de usuarios.
    """
    def post(self, request):
        """
        Valida las credenciales del usuario (email y contraseña).
        
        En caso de éxito, devuelve la información básica del usuario.
        En caso de error, devuelve un mensaje descriptivo y el código HTTP correspondiente.
        """
        email = request.data.get('email')
        contrasena = request.data.get('contrasena')

        if not email or not contrasena:
            return Response({
                "exito": False,
                "mensaje": "Email y contraseña son obligatorios"
            }, status=status.HTTP_400_BAD_REQUEST)

        try:
            usuario = Usuario.objects.get(email=email)
            if usuario.contrasena == contrasena: 
                serializer = UsuarioSerializer(usuario)
                return Response({
                    "exito": True,
                    "mensaje": "Inicio de sesión exitoso",
                    "datos": serializer.data
                }, status=status.HTTP_200_OK)
            else:
                return Response({
                    "exito": False,
                    "mensaje": "Contraseña incorrecta"
                }, status=status.HTTP_401_UNAUTHORIZED)
        except Usuario.DoesNotExist:
            return Response({
                "exito": False,
                "mensaje": "Usuario no encontrado"
            }, status=status.HTTP_404_NOT_FOUND)

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
            
            # Generamos un código simple de 6 caracteres para el TFG
            codigo = ''.join(random.choices(string.ascii_uppercase + string.digits, k=6))
            
            # En un sistema real, guardaríamos este código en DB asociado al usuario
            # Por ahora, para demostrar la funcionalidad, simularemos el cambio
            # o simplemente informaremos al usuario. 
            # Para que sea "real", vamos a actualizar su contraseña al código temporal.
            usuario.contrasena = codigo
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
