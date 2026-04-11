class Notificacion {
  final int id;
  final String tipo;
  final String mensaje;
  final bool leida;
  final String? nombreGenerador;
  final int? idGenerador;
  final String? nombreComunidad;
  final int? idComunidad;
  final int? referenciaId;
  final String? estadoPeticion;
  final DateTime fechaNotificacion;

  Notificacion({
    required this.id,
    required this.tipo,
    required this.mensaje,
    required this.leida,
    this.nombreGenerador,
    this.idGenerador,
    this.nombreComunidad,
    this.idComunidad,
    this.referenciaId,
    this.estadoPeticion,
    required this.fechaNotificacion,
  });

  factory Notificacion.fromJson(Map<String, dynamic> json) {
    try {
      return Notificacion(
        id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
        tipo: json['tipo']?.toString() ?? 'default',
        mensaje: json['mensaje']?.toString() ?? 'Nueva notificación',
        leida: json['leida'] == true,
        nombreGenerador: json['nombre_generador']?.toString(),
        idGenerador: int.tryParse(json['id_generator']?.toString() ?? json['id_generador']?.toString() ?? ''),
        nombreComunidad: json['nombre_comunidad']?.toString(),
        idComunidad: int.tryParse(json['id_comunidad']?.toString() ?? ''),
        referenciaId: int.tryParse(json['referencia_id']?.toString() ?? ''),
        estadoPeticion: json['estado_peticion']?.toString(),
        fechaNotificacion: json['fecha_notificacion'] != null 
            ? DateTime.tryParse(json['fecha_notificacion'].toString()) ?? DateTime.now()
            : DateTime.now(),
      );
    } catch (e) {
      print('Error parsing Notificacion: $e');
      return Notificacion(
        id: 0,
        tipo: 'error',
        mensaje: 'Error de carga',
        leida: true,
        fechaNotificacion: DateTime.now(),
      );
    }
  }

  Notificacion copyWith({
    int? id,
    String? tipo,
    String? mensaje,
    bool? leida,
    String? nombreGenerador,
    String? nombreComunidad,
    int? idComunidad,
    int? referenciaId,
    String? estadoPeticion,
    DateTime? fechaNotificacion,
  }) {
    return Notificacion(
      id: id ?? this.id,
      tipo: tipo ?? this.tipo,
      mensaje: mensaje ?? this.mensaje,
      leida: leida ?? this.leida,
      idGenerador: idGenerador ?? this.idGenerador,
      nombreComunidad: nombreComunidad ?? this.nombreComunidad,
      idComunidad: idComunidad ?? this.idComunidad,
      referenciaId: referenciaId ?? this.referenciaId,
      estadoPeticion: estadoPeticion ?? this.estadoPeticion,
      fechaNotificacion: fechaNotificacion ?? this.fechaNotificacion,
    );
  }
}