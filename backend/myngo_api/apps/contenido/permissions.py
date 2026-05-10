from rest_framework import permissions

class IsAuthorOrAdmin(permissions.BasePermission):
    """
    Permiso que solo permite al autor de un post o al admin de la comunidad 
    editarlo o borrarlo.
    """
    def has_object_permission(self, request, view, obj):
        if request.method in permissions.SAFE_METHODS:
            return True
        
        # Identificar autor/propietario
        autor = getattr(obj, 'autor', getattr(obj, 'propietario', None))
        if autor == request.user:
            return True
            
        # O si es admin/moderador de la comunidad
        comunidad = getattr(obj, 'comunidad', None)
        
        # Caso especial para Comentarios: el dueño del post también puede borrarlo
        from .models import Comentario
        if isinstance(obj, Comentario):
            if obj.publicacion.autor == request.user:
                return True
            # Si el comentario es en una comunidad, heredamos la comunidad del post
            if not comunidad:
                comunidad = obj.publicacion.comunidad

        if comunidad:
            if comunidad.creador == request.user:
                return True
            
            from comunidades.models import MiembrosComunidad
            return MiembrosComunidad.objects.filter(
                usuario=request.user, 
                comunidad=comunidad, 
                rol__in=['Administrador', 'Moderador']
            ).exists()
            
        return False
