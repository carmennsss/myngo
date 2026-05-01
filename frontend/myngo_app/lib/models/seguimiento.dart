/// Modelo que representa una relación de seguimiento o solicitud de unión.
///
/// Vincula a un seguidor con un usuario o una comunidad, manteniendo
/// el estado de aprobación ('ACEPTADO', 'PENDIENTE', etc.).
class Seguimiento {
  final int id;
  final int seguidorId;
  final int? seguidoUsuarioId;
  final int? seguidaComunidadId;

  /// Estado de la relación (e.g., 'ACEPTADO', 'PENDIENTE', 'DENEGADO').
  final String estado;

  final DateTime fechaSeguimiento;

  Seguimiento({
    required this.id,
    required this.seguidorId,
    this.seguidoUsuarioId,
    this.seguidaComunidadId,
    required this.estado,
    required this.fechaSeguimiento,
  });

  /// Crea una instancia de [Seguimiento] a partir de un mapa JSON.
  factory Seguimiento.fromJson(Map<String, dynamic> json) {
    return Seguimiento(
      id: json['id'] ?? 0,
      seguidorId: json['seguidor'] ?? 0,
      seguidoUsuarioId: json['seguido_usuario'] as int?,
      seguidaComunidadId: json['seguida_comunidad'] as int?,
      estado: json['estado']?.toString() ?? 'PENDIENTE',
      fechaSeguimiento: json['fecha_seguimiento'] != null
          ? DateTime.parse(json['fecha_seguimiento'])
          : DateTime.now(),
    );
  }
}