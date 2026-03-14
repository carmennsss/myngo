from django.shortcuts import render
from .serializers import UsuarioSerializer
from .models import Usuario
from rest_framework.response import Response
from rest_framework import status
from rest_framework.views import APIView

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
