class ImagenesGaleria {
  final int id;
  final int propietarioId;
  final int comunidadId;
  final String urlS3;
  final double relacionAspecto;
  final bool esPublica; // Las fotos pueden ser privadas o públicas [cite: 20]
  final DateTime fechaSubida;

  ImagenesGaleria({
    required this.id,
    required this.propietarioId,
    required this.comunidadId,
    required this.urlS3,
    required this.relacionAspecto,
    required this.esPublica,
    required this.fechaSubida,
  });

  factory ImagenesGaleria.fromJson(Map<String, dynamic> json) {
    return ImagenesGaleria(
      id: json['id'],
      propietarioId: json['propietario'],
      comunidadId: json['comunidad'],
      urlS3: json['url_s3'],
      relacionAspecto: json['relacion_aspecto']?.toDouble() ?? 1.0,
      esPublica: json['es_publica'] ?? true,
      fechaSubida: DateTime.parse(json['fecha_subida']),
    );
  }
}