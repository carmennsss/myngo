class ImagenGaleria {
  final int id;
  final int propietarioId;
  final int comunidadId;
  final String urlS3;
  final double relacionAspecto;
  final bool esPublica;
  final DateTime fechaSubida;

  ImagenGaleria({
    required this.id,
    required this.propietarioId,
    required this.comunidadId,
    required this.urlS3,
    required this.relacionAspecto,
    required this.esPublica,
    required this.fechaSubida,
  });

  factory ImagenGaleria.fromJson(Map<String, dynamic> json) {
    return ImagenGaleria(
      id: json['id'],
      propietarioId: json['propietario'],
      comunidadId: json['comunidad'],
      urlS3: json['url_s3'],
      relacionAspecto: (json['relacion_aspecto'] ?? 1.0).toDouble(),
      esPublica: json['es_publica'] ?? true,
      fechaSubida: DateTime.parse(json['fecha_subida']),
    );
  }
}
