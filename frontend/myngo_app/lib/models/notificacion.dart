class Notificacion {
  final int id;
  final String tipo;
  final String mensaje;
  final bool leida;
  final String? nombreGenerador;
  final String? nombreComunidad;
  final int? referenciaId;
  final DateTime fechaNotificacion;

  Notificacion({
    required this.id,
    required this.tipo,
    required this.mensaje,
    required this.leida,
    this.nombreGenerador,
    this.nombreComunidad,
    this.referenciaId,
    required this.fechaNotificacion,
  });

  factory Notificacion.fromJson(Map<String, dynamic> json) {
    return Notificacion(
      id: json['id'],
      tipo: json['tipo'],
      mensaje: json['mensaje'],
      leida: json['leida'],
      nombreGenerador: json['nombre_generador'],
      nombreComunidad: json['nombre_comunidad'],
      referenciaId: json['referencia_id'],
      fechaNotificacion: DateTime.parse(json['fecha_notificacion']),
    );
  }

  Notificacion copyWith({
    int? id,
    String? tipo,
    String? mensaje,
    bool? leida,
    String? nombreGenerador,
    String? nombreComunidad,
    int? referenciaId,
    DateTime? fechaNotificacion,
  }) {
    return Notificacion(
      id: id ?? this.id,
      tipo: tipo ?? this.tipo,
      mensaje: mensaje ?? this.mensaje,
      leida: leida ?? this.leida,
      nombreGenerador: nombreGenerador ?? this.nombreGenerador,
      nombreComunidad: nombreComunidad ?? this.nombreComunidad,
      referenciaId: referenciaId ?? this.referenciaId,
      fechaNotificacion: fechaNotificacion ?? this.fechaNotificacion,
    );
  }
}