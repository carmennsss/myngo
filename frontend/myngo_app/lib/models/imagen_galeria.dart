class ImagenGaleria {
  final int id;
  final int propietarioId;
  final String? propietarioNombre;
  final int? comunidadId;
  final String? comunidadNombre;
  final int? creadorComunidadId;
  final bool usuarioEsMiembro;
  final String urlArchivo;
  final String tipoArchivo; // 'I' o 'V'
  final double relacionAspecto;
  final bool esPublica;
  final DateTime fechaSubida;
  final String? etiquetas;

  ImagenGaleria({
    required this.id,
    required this.propietarioId,
    this.propietarioNombre,
    this.comunidadId,
    this.comunidadNombre,
    this.creadorComunidadId,
    this.usuarioEsMiembro = false,
    required this.urlArchivo,
    required this.tipoArchivo,
    required this.relacionAspecto,
    required this.esPublica,
    required this.fechaSubida,
    this.etiquetas,
  });

  factory ImagenGaleria.fromJson(Map<String, dynamic> json) {
    return ImagenGaleria(
      id: json['id'] ?? 0,
      propietarioId: json['propietario'] ?? 0,
      propietarioNombre: json['propietario_nombre']?.toString() ?? 'Anónimo',
      comunidadId: json['comunidad'] as int?,
      comunidadNombre: json['comunidad_nombre']?.toString(),
      creadorComunidadId: json['creador_comunidad_id'] as int?,
      usuarioEsMiembro: json['usuario_es_miembro'] ?? false,
      urlArchivo: json['url_archivo']?.toString() ?? json['url_s3']?.toString() ?? '',
      tipoArchivo: json['tipo_archivo']?.toString() ?? 'I',
      relacionAspecto: (json['relacion_aspecto'] ?? 1.0).toDouble(),
      esPublica: json['es_publica'] ?? true,
      fechaSubida: json['fecha_subida'] != null 
          ? DateTime.parse(json['fecha_subida']) 
          : DateTime.now(),
      etiquetas: json['etiquetas']?.toString(),
    );
  }
}
