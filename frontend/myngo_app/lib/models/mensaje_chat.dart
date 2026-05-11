import '../utils/configuracion.dart';

/// Modelo que representa un archivo adjunto en un mensaje.
class ChatAttachment {
  final int id;
  final String url;
  final String type; // 'I' (Imagen) o 'V' (Video)
  final String? name;

  ChatAttachment({
    required this.id,
    required this.url,
    required this.type,
    this.name,
  });

  factory ChatAttachment.fromJson(Map<String, dynamic> json) {
    String rawUrl = json['url'] ?? json['file_url'] ?? '';
    if (rawUrl.startsWith('/')) {
      rawUrl = '${Configuracion.baseUrl}$rawUrl';
    }
    
    return ChatAttachment(
      id: json['id'] ?? 0,
      url: rawUrl,
      type: json['tipo'] ?? json['type'] ?? json['file_type'] ?? 'I',
      name: json['name'],
    );
  }

  bool get isVideo => type == 'V' || type == 'video';
  bool get isImage => type == 'I' || type == 'image';
}

/// Modelo que representa un mensaje individual dentro de una sala de chat.
///
/// Soporta contenido de texto, archivos multimedia y mensajes de sistema.
class MensajeChat {
  final int id;
  final int salaId;
  final int emisorId;
  final String? contenido;
  final String? urlArchivoS3; // Mantenido por compatibilidad
  final List<ChatAttachment> attachments;
  final DateTime fechaEnvio;
  final List<int> leidoPorIds;
  final int? referenciaA;
  final Map<String, dynamic>? referenciaADetalle;
  final bool esEditado;
  final DateTime? fechaEdicion;
  final bool borradoParaTodos;
  final bool borradoParaMi;
  final String tipo; // TEXTO, IMAGEN, VIDEO, SISTEMA
  final Map<int, DateTime> infoLectura; // userId -> fechaLectura

  MensajeChat({
    required this.id,
    required this.salaId,
    required this.emisorId,
    this.contenido,
    this.urlArchivoS3,
    this.attachments = const [],
    required this.fechaEnvio,
    this.leidoPorIds = const [],
    this.referenciaA,
    this.referenciaADetalle,
    this.esEditado = false,
    this.fechaEdicion,
    this.borradoParaTodos = false,
    this.borradoParaMi = false,
    this.tipo = 'TEXTO',
    this.infoLectura = const {},
  });

  bool get esSistema => tipo == 'SISTEMA';

  /// Crea una instancia de [MensajeChat] a partir de un mapa JSON.
  factory MensajeChat.fromJson(Map<String, dynamic> json) {
    var mediaList = <ChatAttachment>[];
    if (json['media'] != null) {
      mediaList = (json['media'] as List).map((i) => ChatAttachment.fromJson(i)).toList();
    } else if (json['attachments'] != null) {
      mediaList = (json['attachments'] as List).map((i) => ChatAttachment.fromJson(i)).toList();
    }

    String? urlS3 = json['url_archivo_s3']?.toString();
    if (urlS3 != null && urlS3.startsWith('/')) {
      urlS3 = '${Configuracion.baseUrl}$urlS3';
    }

    return MensajeChat(
      id: json['id'] ?? json['message_id'] ?? 0,
      salaId: json['sala'] ?? json['sala_id'] ?? 0,
      emisorId: json['emisor'] ?? json['user_id'] ?? json['sender_id'] ?? 0,
      contenido: json['content']?.toString() ?? json['contenido']?.toString(),
      urlArchivoS3: urlS3,
      attachments: mediaList,
      fechaEnvio: json['fecha_envio'] != null
          ? DateTime.parse(json['fecha_envio']).toLocal()
          : (json['timestamp'] != null 
              ? DateTime.parse(json['timestamp']).toLocal() 
              : DateTime.now()),
      leidoPorIds: (json['leido_por_ids'] as List<dynamic>?)?.map((e) => (e as num).toInt()).toList() ?? [],
      referenciaA: json['referencia_a'],
      referenciaADetalle: json['referencia_a_detalle'],
      esEditado: json['es_editado'] ?? false,
      fechaEdicion: json['fecha_edicion'] != null ? DateTime.parse(json['fecha_edicion']).toLocal() : null,
      borradoParaTodos: json['borrado_para_todos'] ?? false,
      borradoParaMi: json['borrado_para_mi'] ?? false,
      tipo: json['tipo'] ?? 'TEXTO',
      infoLectura: (json['info_lectura'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(int.parse(key), DateTime.parse(value).toLocal())
      ) ?? {},
    );
  }

  MensajeChat copyWith({
    int? id,
    int? salaId,
    int? emisorId,
    String? contenido,
    String? urlArchivoS3,
    List<ChatAttachment>? attachments,
    DateTime? fechaEnvio,
    List<int>? leidoPorIds,
    int? referenciaA,
    Map<String, dynamic>? referenciaADetalle,
    bool? esEditado,
    DateTime? fechaEdicion,
    bool? borradoParaTodos,
    bool? borradoParaMi,
    String? tipo,
    Map<int, DateTime>? infoLectura,
  }) {
    return MensajeChat(
      id: id ?? this.id,
      salaId: salaId ?? this.salaId,
      emisorId: emisorId ?? this.emisorId,
      contenido: contenido ?? this.contenido,
      urlArchivoS3: urlArchivoS3 ?? this.urlArchivoS3,
      attachments: attachments ?? this.attachments,
      fechaEnvio: fechaEnvio ?? this.fechaEnvio,
      leidoPorIds: leidoPorIds ?? this.leidoPorIds,
      referenciaA: referenciaA ?? this.referenciaA,
      referenciaADetalle: referenciaADetalle ?? this.referenciaADetalle,
      esEditado: esEditado ?? this.esEditado,
      fechaEdicion: fechaEdicion ?? this.fechaEdicion,
      borradoParaTodos: borradoParaTodos ?? this.borradoParaTodos,
      borradoParaMi: borradoParaMi ?? this.borradoParaMi,
      tipo: tipo ?? this.tipo,
      infoLectura: infoLectura ?? this.infoLectura,
    );
  }
}
