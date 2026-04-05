class Publicacion {
  final int id;
  final int autorId;
  final String autorNombre;
  final int comunidadId;
  final String comunidadNombre;
  final int? creadorComunidadId;
  final String titulo;
  final String contenidoTexto;
  final String? urlImagen;     // URL de la imagen en galería (puede ser null si es solo texto)
  final double relacionAspecto;
  final bool esValidoIa;
  final DateTime fechaCreacion;
  final int likesCount;
  final int comentariosCount;
  final bool usuarioDioLike;

  Publicacion({
    required this.id,
    required this.autorId,
    required this.autorNombre,
    required this.comunidadId,
    required this.comunidadNombre,
    this.creadorComunidadId,
    required this.titulo,
    required this.contenidoTexto,
    this.urlImagen,
    required this.relacionAspecto,
    this.esValidoIa = true,
    required this.fechaCreacion,
    this.likesCount = 0,
    this.comentariosCount = 0,
    this.usuarioDioLike = false,
  });

  factory Publicacion.fromJson(Map<String, dynamic> json) {
    try {
      return Publicacion(
        id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
        autorId: int.tryParse(json['autor']?.toString() ?? '0') ?? 0,
        autorNombre: json['autor_nombre']?.toString() ?? 'Anónimo',
        comunidadId: int.tryParse(json['comunidad']?.toString() ?? '0') ?? 0,
        comunidadNombre: json['comunidad_nombre']?.toString() ?? 'General',
        creadorComunidadId: int.tryParse(json['creador_comunidad_id']?.toString() ?? ''),
        titulo: json['titulo']?.toString() ?? '',
        contenidoTexto: json['contenido_texto']?.toString() ?? '',
        urlImagen: json['url_archivo_s3'] ?? json['url_imagen'],
        relacionAspecto: double.tryParse(json['relacion_aspecto']?.toString() ?? '1.0') ?? 1.0,
        fechaCreacion: json['fecha_creacion'] != null 
            ? DateTime.tryParse(json['fecha_creacion'].toString()) ?? DateTime.now() 
            : DateTime.now(),
        likesCount: int.tryParse(json['likes_count']?.toString() ?? '0') ?? 0,
        comentariosCount: int.tryParse(json['comentarios_count']?.toString() ?? '0') ?? 0,
        usuarioDioLike: json['usuario_dio_like'] == true,
      );
    } catch (e) {
      print('Error parsing Publicacion: $e');
      return Publicacion(
        id: 0,
        autorId: 0,
        autorNombre: 'Error',
        comunidadId: 0,
        comunidadNombre: '',
        titulo: 'Error de carga',
        contenidoTexto: '',
        relacionAspecto: 1.0,
        fechaCreacion: DateTime.now(),
      );
    }
  }

  Publicacion copyWith({
    int? id,
    int? autorId,
    String? autorNombre,
    int? comunidadId,
    String? comunidadNombre,
    int? creadorComunidadId,
    String? titulo,
    String? contenidoTexto,
    String? urlImagen,
    double? relacionAspecto,
    bool? esValidoIa,
    DateTime? fechaCreacion,
    int? likesCount,
    int? comentariosCount,
    bool? usuarioDioLike,
  }) {
    return Publicacion(
      id: id ?? this.id,
      autorId: autorId ?? this.autorId,
      autorNombre: autorNombre ?? this.autorNombre,
      comunidadId: comunidadId ?? this.comunidadId,
      comunidadNombre: comunidadNombre ?? this.comunidadNombre,
      creadorComunidadId: creadorComunidadId ?? this.creadorComunidadId,
      titulo: titulo ?? this.titulo,
      contenidoTexto: contenidoTexto ?? this.contenidoTexto,
      urlImagen: urlImagen ?? this.urlImagen,
      relacionAspecto: relacionAspecto ?? this.relacionAspecto,
      esValidoIa: esValidoIa ?? this.esValidoIa,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      likesCount: likesCount ?? this.likesCount,
      comentariosCount: comentariosCount ?? this.comentariosCount,
      usuarioDioLike: usuarioDioLike ?? this.usuarioDioLike,
    );
  }
}