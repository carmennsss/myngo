from rest_framework import serializers
from .models import Notificacion

class NotificacionSerializer(serializers.ModelSerializer):
    nombre_generador = serializers.ReadOnlyField(source='referencia_usuario.nombre_usuario')
    nombre_comunidad = serializers.ReadOnlyField(source='referencia_comunidad.nombre')
    estado_peticion = serializers.SerializerMethodField()

    class Meta:
        model = Notificacion
        fields = [
            'id', 'tipo', 'mensaje', 'leida', 
            'nombre_generador', 'nombre_comunidad', 
            'referencia_id', 'fecha_notificacion', 'estado_peticion'
        ]

    def get_estado_peticion(self, obj):
        if obj.tipo == 'PETICION_UNION':
            if obj.referencia_comunidad:
                from comunidades.models import Miembros_comunidades
                try:
                    return Miembros_comunidades.objects.get(pk=obj.referencia_id).estado_peticion
                except Exception:
                    return "INEXISTENTE"
            elif obj.referencia_usuario:
                from usuarios.models import Seguimiento
                try:
                    return Seguimiento.objects.get(pk=obj.referencia_id).estado
                except Exception:
                    return "INEXISTENTE"
        return None
