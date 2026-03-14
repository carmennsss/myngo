from django.shortcuts import render
from .serializers import UsuarioSerializer
from rest_framework.response import Response
from rest_framework import status
from rest_framework.views import APIView
class RegistroUsuarios(APIView):
    def post(self,request):
        serializer=UsuarioSerializer(data=request.data)

        if(serializer.is_valid):
            serializer.save()
            return Response(
                {
                    "success": True,
                    "message": "Usuario registrado correctamente",
                    "data": serializer.data
                },
                status=status.HTTP_201_CREATED)
        else:
            return Response({
                "success": False,
                "errors": serializer.errors
            },status.HTTP_400_BAD_REQUEST)
        

