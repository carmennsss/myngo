from django.shortcuts import render
from rest_framework.views import APIView,status
from rest_framework.response import Response
from core import settings
from django.http import JsonResponse
from django.core.files.storage import default_storage
class DocumentosUtilidad(APIView):
    """
    Endpoint para obtener las rutas de documentos legales de Myngo.
    """
    def get(self, request):
        nombre_archivo = "legal/Reglas_comunidad.pdf"
        
        # Al tener querystring_auth=True en settings, esto genera 
        # automáticamente la URL con el token de seguridad de Amazon
        try:
            url_s3 = default_storage.url(nombre_archivo)
            return Response({"reglas_comunidad": url_s3}, status=status.HTTP_200_OK)
        except Exception as e:
            return Response({"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
