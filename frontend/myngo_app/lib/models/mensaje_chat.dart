/// Modelo que representa un mensaje individual dentro de una sala de chat.
///
/// Soporta contenido de texto y referencias a archivos multimedia.
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
  });

  /// Crea una instancia de [MensajeChat] a partir de un mapa JSON.
  factory MensajeChat.fromJson(Map<String, dynamic> json) {
    return MensajeChat(
      id: json['id'] ?? 0,
      salaId: json['sala'] ?? 0,
      emisorId: json['emisor'] ?? 0,
      contenido: json['content']?.toString() ?? json['contenido']?.toString(),
      urlArchivoS3: json['url_archivo_s3']?.toString(),
      fechaEnvio: json['fecha_envio'] != null
          ? DateTime.parse(json['fecha_envio']).toLocal()
          : DateTime.now(),
      leidoPorIds: (json['leido_por_ids'] as List<dynamic>?)?.map((e) => e as int).toList() ?? [],
      referenciaA: json['referencia_a'],
      referenciaADetalle: json['referencia_a_detalle'],
      esEditado: json['es_editado'] ?? false,
      fechaEdicion: json['fecha_edicion'] != null ? DateTime.parse(json['fecha_edicion']).toLocal() : null,
      borradoParaTodos: json['borrado_para_todos'] ?? false,
      borradoParaMi: json['borrado_para_mi'] ?? false,
    );
  }
}