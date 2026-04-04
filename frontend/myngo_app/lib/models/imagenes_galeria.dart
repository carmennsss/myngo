class ImagenesGaleria {
  final int id;
  final int propietarioId;
  final int comunidadId;
  final String urlS3;
  final double relacionAspecto;
  final DateTime fechaSubida;
  final String etiquetas;

  ImagenesGaleria({
    required this.id,
    required this.propietarioId,
    required this.comunidadId,
    required this.urlS3,
    required this.relacionAspecto,
    required this.fechaSubida,
    required this.etiquetas,
  });

  factory ImagenesGaleria.fromJson(Map<String, dynamic> json) {
    return ImagenesGaleria(
      id: json['id'] ?? 0,
      propietarioId: json['propietario'] ?? 0,
      comunidadId: json['comunidad'] ?? 0,
      urlS3: json['url_s3']?.toString() ?? '',
      relacionAspecto: (json['relacion_aspecto'] ?? 1.0).toDouble(),
      fechaSubida: json['fecha_subida'] != null 
          ? DateTime.parse(json['fecha_subida']) 
          : DateTime.now(),
      etiquetas: json['etiquetas']?.toString() ?? '',
    );
  }
}