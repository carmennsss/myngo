// lib/models/notificacion.dart

class Notificacion {
  final int id;
  final int usuarioId;
  final String tipo; // Ej: 'SOLICITUD_SEGUIMIENTO', 'NUEVO_VOTO'
  final String mensaje;
  final bool leida;
  final int? referenciaUsuarioId;
  final int? referenciaComunidadId;
  final DateTime fechaNotificacion;

  Notificacion({
    required this.id,
    required this.usuarioId,
    required this.tipo,
    required this.mensaje,
    required this.leida,
    this.referenciaUsuarioId,
    this.referenciaComunidadId,
    required this.fechaNotificacion,
  });

  factory Notificacion.fromJson(Map<String, dynamic> json) {
    return Notificacion(
      id: json['id'],
      usuarioId: json['usuario'],
      tipo: json['tipo'],
      mensaje: json['mensaje'],
      leida: json['leida'] ?? false,
      referenciaUsuarioId: json['referencia_usuario'],
      referenciaComunidadId: json['referencia_comunidad'],
      // Corregimos el nombre del campo según tu modelo (fecha_notoficacion)
      fechaNotificacion: DateTime.parse(json['fecha_notoficacion']),
    );
  }
}