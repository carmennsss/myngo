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