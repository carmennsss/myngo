"""Serializadores para el sistema de notificaciones de Myngo.

Transforma las notificaciones en JSON, incluyendo información sobre el
estado de las peticiones relacionadas (unión/seguimiento).
"""

from rest_framework import serializers

from usuarios.models import Seguimiento
from .models import Notificacion


class NotificacionSerializer(serializers.ModelSerializer):
    """Serializador para notificaciones, con resolución de metadatos de referencia."""

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
        """Consulta el estado actual de la petición vinculada a la notificación."""
        if obj.tipo in ['PETICION_UNION', 'PETICION_SEGUIMIENTO']:
            try:
                return Seguimiento.objects.get(pk=obj.referencia_id).estado
            except Exception:
                return "INEXISTENTE"
        return None
