class Publicacion {
  final int id;
  final int autorId;
  final String autorNombre;
  final int comunidadId;
  final String comunidadNombre;
  final int? creadorComunidadId;
  final String titulo;
  final String contenidoTexto;
  final String? urlImagen;     // URL de la imagen (mantenido por backcompat)
  final int? imagenId;         // ID de la imagen (mantenido por backcompat)
  final List<String> urlsImagenes;
  final List<int> imagenesIds;
  final double relacionAspecto;
  final bool esValidoIa;
  final DateTime fechaCreacion;
  final int likesCount;
  final int comentariosCount;
  final String? autorFoto;
  final Map<String, dynamic>? autorEstiloPost;
  final bool usuarioDioLike;
  final bool usuarioGuardoPost;

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
    this.imagenId,
    this.urlsImagenes = const [],
    this.imagenesIds = const [],
    required this.relacionAspecto,
    this.esValidoIa = true,
    this.autorFoto,
    required this.fechaCreacion,
    this.likesCount = 0,
    this.comentariosCount = 0,
    this.autorEstiloPost,
    this.usuarioDioLike = false,
    this.usuarioGuardoPost = false,
  });

  factory Publicacion.fromJson(Map<String, dynamic> json) {
    try {
      return Publicacion(
        id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
        autorId: int.tryParse(json['autor']?.toString() ?? '0') ?? 0,
        autorNombre: json['autor_nombre']?.toString() ?? 'Anónimo',
        autorFoto: json['autor_foto']?.toString(),
        comunidadId: int.tryParse(json['comunidad']?.toString() ?? '0') ?? 0,
        comunidadNombre: json['comunidad_nombre']?.toString() ?? 'General',
        creadorComunidadId: int.tryParse(json['creador_comunidad_id']?.toString() ?? ''),
        titulo: json['titulo']?.toString() ?? '',
        contenidoTexto: json['contenido_texto']?.toString() ?? '',
        urlImagen: (() {
          final url = json['url_archivo_s3'] ?? json['url_imagen'];
          return url != null ? url.toString().trim() : null;
        })(),
        // Prioriza imagen_id (campo explícito del backend), luego imagen (FK id)
        imagenId: (json['imagen_id'] is int)
            ? json['imagen_id'] as int
            : (json['imagen'] is int)
                ? json['imagen'] as int
                : int.tryParse(json['imagen_id']?.toString() ?? json['imagen']?.toString() ?? ''),
        urlsImagenes: (json['urls_imagenes'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? 
             ((json['url_archivo_s3'] ?? json['url_imagen']) != null ? [(json['url_archivo_s3'] ?? json['url_imagen']).toString()] : []),
        imagenesIds: (json['imagenes_ids'] as List<dynamic>?)?.map((e) => int.tryParse(e.toString()) ?? 0).toList() ?? [],
        relacionAspecto: double.tryParse(json['relacion_aspecto']?.toString() ?? '1.0') ?? 1.0,
        esValidoIa: json['es_valido_ia'] == true,
        fechaCreacion: json['fecha_creacion'] != null 
            ? DateTime.tryParse(json['fecha_creacion'].toString()) ?? DateTime.now() 
            : DateTime.now(),
        likesCount: int.tryParse(json['likes_count']?.toString() ?? '0') ?? 0,
        comentariosCount: int.tryParse(json['comentarios_count']?.toString() ?? '0') ?? 0,
        autorEstiloPost: json['autor_estilo_post'] is Map ? Map<String, dynamic>.from(json['autor_estilo_post']) : null,
        usuarioDioLike: json['usuario_dio_like'] == true,
        usuarioGuardoPost: json['usuario_guardo_post'] == true,
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
    int? imagenId,
    List<String>? urlsImagenes,
    List<int>? imagenesIds,
    double? relacionAspecto,
    bool? esValidoIa,
    String? autorFoto,
    DateTime? fechaCreacion,
    int? likesCount,
    int? comentariosCount,
    bool? usuarioDioLike,
    bool? usuarioGuardoPost,
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
      imagenId: imagenId ?? this.imagenId,
      urlsImagenes: urlsImagenes ?? this.urlsImagenes,
      imagenesIds: imagenesIds ?? this.imagenesIds,
      relacionAspecto: relacionAspecto ?? this.relacionAspecto,
      esValidoIa: esValidoIa ?? this.esValidoIa,
      autorFoto: autorFoto ?? this.autorFoto,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      likesCount: likesCount ?? this.likesCount,
      comentariosCount: comentariosCount ?? this.comentariosCount,
      usuarioDioLike: usuarioDioLike ?? this.usuarioDioLike,
      usuarioGuardoPost: usuarioGuardoPost ?? this.usuarioGuardoPost,
    );
  }
}