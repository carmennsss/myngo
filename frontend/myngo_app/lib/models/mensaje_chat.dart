/// Modelo que representa un mensaje individual dentro de una sala de chat.
///
/// Soporta contenido de texto, archivos multimedia y mensajes de sistema.
class MensajeChat {
  final int id;
  final int salaId;
  final int emisorId;
  final String? contenido;
  final String? urlArchivoS3;
  final DateTime fechaEnvio;
  final List<int> leidoPorIds;
  final int? referenciaA;
  final Map<String, dynamic>? referenciaADetalle;
  final bool esEditado;
  final DateTime? fechaEdicion;
  final bool borradoParaTodos;
  final bool borradoParaMi;
  final String tipo; // TEXTO, IMAGEN, VIDEO, SISTEMA

  MensajeChat({
    required this.id,
    required this.salaId,
    required this.emisorId,
    this.contenido,
    this.urlArchivoS3,
    required this.fechaEnvio,
    this.leidoPorIds = const [],
    this.referenciaA,
    this.referenciaADetalle,
    this.esEditado = false,
    this.fechaEdicion,
    this.borradoParaTodos = false,
    this.borradoParaMi = false,
    this.tipo = 'TEXTO',
  });

  bool get esSistema => tipo == 'SISTEMA';

  /// Crea una instancia de [MensajeChat] a partir de un mapa JSON.
  factory MensajeChat.fromJson(Map<String, dynamic> json) {
    return MensajeChat(
      id: json['id'] ?? json['message_id'] ?? 0,
      salaId: json['sala'] ?? json['sala_id'] ?? 0,
      emisorId: json['emisor'] ?? json['user_id'] ?? json['sender_id'] ?? 0,
      contenido: json['content']?.toString() ?? json['contenido']?.toString(),
      urlArchivoS3: json['url_archivo_s3']?.toString(),
      fechaEnvio: json['fecha_envio'] != null
          ? DateTime.parse(json['fecha_envio']).toLocal()
          : (json['timestamp'] != null 
              ? DateTime.parse(json['timestamp']).toLocal() 
              : DateTime.now()),
      leidoPorIds: (json['leido_por_ids'] as List<dynamic>?)?.map((e) => e as int).toList() ?? [],
      referenciaA: json['referencia_a'],
      referenciaADetalle: json['referencia_a_detalle'],
      esEditado: json['es_editado'] ?? false,
      fechaEdicion: json['fecha_edicion'] != null ? DateTime.parse(json['fecha_edicion']).toLocal() : null,
      borradoParaTodos: json['borrado_para_todos'] ?? false,
      borradoParaMi: json['borrado_para_mi'] ?? false,
      tipo: json['tipo'] ?? 'TEXTO',
    );
  }

  MensajeChat copyWith({
    int? id,
    int? salaId,
    int? emisorId,
    String? contenido,
    String? urlArchivoS3,
    DateTime? fechaEnvio,
    List<int>? leidoPorIds,
    int? referenciaA,
    Map<String, dynamic>? referenciaADetalle,
    bool? esEditado,
    DateTime? fechaEdicion,
    bool? borradoParaTodos,
    bool? borradoParaMi,
    String? tipo,
  }) {
    return MensajeChat(
      id: id ?? this.id,
      salaId: salaId ?? this.salaId,
      emisorId: emisorId ?? this.emisorId,
      contenido: contenido ?? this.contenido,
      urlArchivoS3: urlArchivoS3 ?? this.urlArchivoS3,
      fechaEnvio: fechaEnvio ?? this.fechaEnvio,
      leidoPorIds: leidoPorIds ?? this.leidoPorIds,
      referenciaA: referenciaA ?? this.referenciaA,
      referenciaADetalle: referenciaADetalle ?? this.referenciaADetalle,
      esEditado: esEditado ?? this.esEditado,
      fechaEdicion: fechaEdicion ?? this.fechaEdicion,
      borradoParaTodos: borradoParaTodos ?? this.borradoParaTodos,
      borradoParaMi: borradoParaMi ?? this.borradoParaMi,
      tipo: tipo ?? this.tipo,
    );
  }
}