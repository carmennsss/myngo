from rest_framework import permissions

class IsAuthorOrAdmin(permissions.BasePermission):
    """
    Permiso que solo permite al autor de un post o al admin de la comunidad 
    editarlo o borrarlo.
    """
    def has_object_permission(self, request, view, obj):
        # Lectura permitida (el filtrado se hace en el queryset)
        if request.method in permissions.SAFE_METHODS:
            return True
        
        # Escritura solo autor
        if obj.autor == request.user:
            return True
            
        # O si es admin de la comunidad (suponiendo que existe lógica de admin)
        if obj.comunidad and obj.comunidad.creador == request.user:
            return True
            
        return False
