class Publicacion {
  final int id;
  final int autorId;
  final int? comunidadId;
  final String? titulo;
  final String? contenidoTexto;
  final String urlArchivoS3;
  final double relacionAspecto; // Crucial para el diseño visual de Pinterest [cite: 58]
  final bool esValidoIa; // Moderación con agentes de Hugging Face [cite: 47]
  final DateTime fechaCreacion;

  Publicacion({
    required this.id,
    required this.autorId,
    this.comunidadId,
    this.titulo,
    this.contenidoTexto,
    required this.urlArchivoS3,
    required this.relacionAspecto,
    required this.esValidoIa,
    required this.fechaCreacion,
  });

  factory Publicacion.fromJson(Map<String, dynamic> json) {
    return Publicacion(
      id: json['id'],
      autorId: json['autor'],
      comunidadId: json['comunidad'],
      titulo: json['titulo'],
      contenidoTexto: json['contenido_texto'],
      urlArchivoS3: json['url_archivo_s3'],
      relacionAspecto: json['relacion_aspecto']?.toDouble() ?? 1.0,
      esValidoIa: json['es_valido_ia'] ?? true,
      fechaCreacion: DateTime.parse(json['fecha_creacion']),
    );
  }
}