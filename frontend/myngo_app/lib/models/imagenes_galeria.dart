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
      id: json['id'],
      propietarioId: json['propietario'],
      comunidadId: json['comunidad'],
      urlS3: json['url_s3'],
      relacionAspecto: json['relacion_aspecto']?.toDouble() ?? 1.0,
      fechaSubida: DateTime.parse(json['fecha_subida']),
      etiquetas: json['etiquetas'] ?? '',
    );
  }
}