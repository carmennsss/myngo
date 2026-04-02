class Publicacion {
  final int id;
  final int autorId;
  final String autorNombre;
  final int comunidadId;
  final String comunidadNombre;
  final String titulo;
  final String contenidoTexto;
  final String? urlImagen;     // URL de la imagen en galería (puede ser null si es solo texto)
  final double relacionAspecto;
  final bool esValidoIa;
  final DateTime fechaCreacion;

  Publicacion({
    required this.id,
    required this.autorId,
    required this.autorNombre,
    required this.comunidadId,
    required this.comunidadNombre,
    required this.titulo,
    required this.contenidoTexto,
    this.urlImagen,
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
      comunidadNombre: json['comunidad_nombre'] ?? 'General',
      titulo: json['titulo'] ?? '',
      contenidoTexto: json['contenido_texto'] ?? '',
      urlImagen: json['url_imagen'] as String?,
      relacionAspecto: (json['relacion_aspecto'] ?? 1.0).toDouble(),
      fechaCreacion: DateTime.parse(json['fecha_creacion']),
    );
  }
}