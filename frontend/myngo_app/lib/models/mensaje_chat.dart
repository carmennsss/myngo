class MensajeChat {
  final int id;
  final int salaId;
  final int emisorId;
  final String? contenido; // Soporte para mensajes de texto [cite: 41, 67]
  final String? urlArchivoS3; // Soporte para imágenes y audios [cite: 41, 67]
  final DateTime fechaEnvio;

  MensajeChat({
    required this.id,
    required this.salaId,
    required this.emisorId,
    this.contenido,
    this.urlArchivoS3,
    required this.fechaEnvio,
  });

  factory MensajeChat.fromJson(Map<String, dynamic> json) {
    return MensajeChat(
      id: json['id'],
      salaId: json['sala'],
      emisorId: json['emisor'],
      contenido: json['contenido'],
      urlArchivoS3: json['url_archivo_s3'],
      fechaEnvio: DateTime.parse(json['fecha_envio']),
    );
  }
}