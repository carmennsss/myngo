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

  MensajeChat({
    required this.id,
    required this.salaId,
    required this.emisorId,
    this.contenido,
    this.urlArchivoS3,
    required this.fechaEnvio,
  });

  /// Crea una instancia de [MensajeChat] a partir de un mapa JSON.
  factory MensajeChat.fromJson(Map<String, dynamic> json) {
    return MensajeChat(
      id: json['id'] ?? 0,
      salaId: json['sala'] ?? 0,
      emisorId: json['emisor'] ?? 0,
      contenido: json['contenido']?.toString(),
      urlArchivoS3: json['url_archivo_s3']?.toString(),
      fechaEnvio: json['fecha_envio'] != null
          ? DateTime.parse(json['fecha_envio'])
          : DateTime.now(),
    );
  }
}