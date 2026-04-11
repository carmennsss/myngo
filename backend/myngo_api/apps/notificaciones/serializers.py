from rest_framework import serializers
from .models import Notificacion
from usuarios.models import Seguimiento

class NotificacionSerializer(serializers.ModelSerializer):
    nombre_generador = serializers.ReadOnlyField(source='referencia_usuario.nombre_usuario')
    id_generador = serializers.ReadOnlyField(source='referencia_usuario.id')
    nombre_comunidad = serializers.ReadOnlyField(source='referencia_comunidad.nombre')
    id_comunidad = serializers.ReadOnlyField(source='referencia_comunidad.id')
    estado_peticion = serializers.SerializerMethodField()

    class Meta:
        model = Notificacion
        fields = [
            'id', 'tipo', 'mensaje', 'leida', 
            'nombre_generador', 'id_generador', 'nombre_comunidad', 'id_comunidad',
            'referencia_id', 'fecha_notificacion', 'estado_peticion'
        ]

    def get_estado_peticion(self, obj):
        if obj.tipo == 'PETICION_UNION':
            
            try:
                # Tanto para comunidad como para usuario, la petición está en Seguimiento
                return Seguimiento.objects.get(pk=obj.referencia_id).estado
            except Exception:
                return "INEXISTENTE"
        return None
