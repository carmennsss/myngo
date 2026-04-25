import 'package:flutter/material.dart';

class Publicacion {
  final int id;
  final int autorId;
  final String autorNombre;
  final int comunidadId;
  final String comunidadNombre;
  final int? creadorComunidadId;
  final String titulo;
  final String contenidoTexto;
  final String? urlImagen;
  final int? imagenId;
  final List<String> urlsImagenes;
  final List<int> imagenesIds;
  final double relacionAspecto;
  final bool esValidoIa;
  final DateTime fechaCreacion;
  int likesCount;
  int comentariosCount;
  final String? autorFoto;
  final String? autorMarco;
  final String? autorFondo;
  final Map<String, dynamic>? autorEstiloPost;
  bool usuarioDioLike;
  bool usuarioGuardoPost;

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
    this.autorMarco,
    this.autorFondo,
    required this.fechaCreacion,
    this.likesCount = 0,
    this.comentariosCount = 0,
    this.autorEstiloPost,
    this.usuarioDioLike = false,
    this.usuarioGuardoPost = false,
  });

  factory Publicacion.fromJson(Map<String, dynamic> json) {
    try {
      // Función auxiliar para parsear enteros de forma segura
      int toInt(dynamic val, [int def = 0]) {
        if (val == null) return def;
        if (val is int) return val;
        return int.tryParse(val.toString()) ?? def;
      }

      return Publicacion(
        id: toInt(json['id']),
        autorId: toInt(json['autor']),
        autorNombre: json['autor_nombre']?.toString() ?? 'Anónimo',
        autorFoto: json['autor_foto']?.toString(),
        autorMarco: json['autor_marco']?.toString(),
        autorFondo: json['autor_fondo']?.toString(),
        comunidadId: toInt(json['comunidad']),
        comunidadNombre: json['comunidad_nombre']?.toString() ?? 'General',
        creadorComunidadId: json['creador_comunidad_id'] != null ? toInt(json['creador_comunidad_id']) : null,
        titulo: json['titulo']?.toString() ?? '',
        contenidoTexto: json['contenido_texto']?.toString() ?? '',
        urlImagen: (json['url_archivo_s3'] ?? json['url_imagen'])?.toString(),
        imagenId: json['imagen_id'] != null ? toInt(json['imagen_id']) : (json['imagen'] != null ? toInt(json['imagen']) : null),
        urlsImagenes: (json['urls_imagenes'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
        imagenesIds: (json['imagenes_ids'] as List<dynamic>?)?.map((e) => toInt(e)).toList() ?? [],
        relacionAspecto: double.tryParse(json['relacion_aspecto']?.toString() ?? '1.0') ?? 1.0,
        esValidoIa: json['es_valido_ia'] == true,
        fechaCreacion: json['fecha_creacion'] != null 
            ? DateTime.tryParse(json['fecha_creacion'].toString()) ?? DateTime.now() 
            : DateTime.now(),
        likesCount: toInt(json['likes_count']),
        comentariosCount: toInt(json['comentarios_count']),
        autorEstiloPost: json['autor_estilo_post'] is Map ? Map<String, dynamic>.from(json['autor_estilo_post']) : null,
        usuarioDioLike: json['usuario_dio_like'] == true,
        usuarioGuardoPost: json['usuario_guardo_post'] == true,
      );
    } catch (e) {
      debugPrint('Error parsing Publicacion: $e');
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
    String? autorMarco,
    String? autorFondo,
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
      autorMarco: autorMarco ?? this.autorMarco,
      autorFondo: autorFondo ?? this.autorFondo,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      likesCount: likesCount ?? this.likesCount,
      comentariosCount: comentariosCount ?? this.comentariosCount,
      usuarioDioLike: usuarioDioLike ?? this.usuarioDioLike,
      usuarioGuardoPost: usuarioGuardoPost ?? this.usuarioGuardoPost,
    );
  }
}