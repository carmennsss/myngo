/// Modelo que representa una propuesta de nueva mejora para una comunidad.
///
/// Incluye el tipo de mejora, el recurso visual propuesto y el estado
/// de moderación ('PENDIENTE', 'APROBADA', 'RECHAZADA').
class PeticionMejora {
  final int id;
  final int usuarioId;
  final String nombreUsuario;
  final int comunidadId;
  final String nombreComunidad;
  final String tipo;
  final String urlRecurso;
  final String estado;
  final int precioSugerido;
  final DateTime fechaCreacion;

  PeticionMejora({
    required this.id,
    required this.usuarioId,
    required this.nombreUsuario,
    required this.comunidadId,
    required this.nombreComunidad,
    required this.tipo,
    required this.urlRecurso,
    required this.estado,
    required this.precioSugerido,
    required this.fechaCreacion,
  });

  /// Crea una instancia de [PeticionMejora] a partir de un mapa JSON.
  factory PeticionMejora.fromJson(Map<String, dynamic> json) {
    return PeticionMejora(
      id: json['id'] ?? 0,
      usuarioId: json['usuario'] ?? 0,
      nombreUsuario: json['nombre_usuario'] ?? '',
      comunidadId: json['comunidad'] ?? 0,
      nombreComunidad: json['nombre_comunidad'] ?? '',
      tipo: json['tipo'] ?? '',
      urlRecurso: json['url_recurso'] ?? '',
      estado: json['estado'] ?? 'PENDIENTE',
      precioSugerido: json['precio_sugerido'] ?? 0,
      fechaCreacion: json['fecha_creacion'] != null
          ? DateTime.parse(json['fecha_creacion'])
          : DateTime.now(),
    );
  }
}
