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
      id: json['id'],
      seguidorId: json['seguidor'],
      seguidoUsuarioId: json['seguido_usuario'],
      seguidaComunidadId: json['seguida_comunidad'],
      // Para ver perfiles o comunidades privadas, deben aceptar el seguimiento 
      estado: json['estado'] ?? 'Aceptado', 
      fechaSeguimiento: DateTime.parse(json['fecha_seguimiento']),
    );
  }
}