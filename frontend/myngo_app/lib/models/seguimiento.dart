// lib/models/seguimiento.dart

class Seguimiento {
  final int id;
  final int seguidorId;
  final int? seguidoUsuarioId;
  final int? seguidaComunidadId;
  final String estado; // "Aceptado" o "Pendiente"
  final DateTime fechaSeguimiento;

  Seguimiento({
    required this.id,
    required this.seguidorId,
    this.seguidoUsuarioId,
    this.seguidaComunidadId,
    required this.estado,
    required this.fechaSeguimiento,
  });

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