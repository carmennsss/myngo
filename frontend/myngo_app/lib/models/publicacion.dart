class Publicacion {
  final int id;
  final int autorId;
  final String autorNombre;
  final int comunidadId;
  final String titulo;
  final String contenidoTexto;
  final String urlArchivoS3;
  final double relacionAspecto;
  final bool esValidoIa;
  final DateTime fechaCreacion;

  Publicacion({
    required this.id,
    required this.autorId,
    required this.autorNombre,
    required this.comunidadId,
    required this.titulo,
    required this.contenidoTexto,
    required this.urlArchivoS3,
    required this.relacionAspecto,
    this.esValidoIa = true,
    required this.fechaCreacion,
  });

  factory Publicacion.fromJson(Map<String, dynamic> json) {
    return Publicacion(
      id: json['id'],
      autorId: json['autor'],
      autorNombre: json['autor_nombre'] ?? 'Anónimo',
      comunidadId: json['comunidad'] ?? 0,
      titulo: json['titulo'] ?? '',
      contenidoTexto: json['contenido_texto'] ?? '',
      urlArchivoS3: json['url_archivo_s3'] ?? '',
      relacionAspecto: (json['relacion_aspecto'] ?? 1.0).toDouble(),
      fechaCreacion: DateTime.parse(json['fecha_creacion']),
    );
  }
}