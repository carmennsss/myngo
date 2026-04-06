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
        if comunidad:
            if comunidad.creador == request.user:
                return True
            
            from comunidades.models import Miembros_comunidades
            return Miembros_comunidades.objects.filter(
                usuario=request.user, 
                comunidad=comunidad, 
                rol__in=['Administrador', 'Moderador']
            ).exists()
            
        return False
