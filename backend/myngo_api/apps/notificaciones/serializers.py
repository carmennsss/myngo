from rest_framework import serializers
from .models import Notificacion

class NotificacionSerializer(serializers.ModelSerializer):
    nombre_generador = serializers.ReadOnlyField(source='referencia_usuario.nombre_usuario')
    nombre_comunidad = serializers.ReadOnlyField(source='referencia_comunidad.nombre')

    class Meta:
        model = Notificacion
        fields = [
            'id', 'tipo', 'mensaje', 'leida', 
            'nombre_generador', 'nombre_comunidad', 
            'referencia_id', 'fecha_notificacion'
        ]
