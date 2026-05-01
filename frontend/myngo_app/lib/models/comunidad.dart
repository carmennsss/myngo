import 'package:flutter/material.dart';

/// Modelo que representa una comunidad en la aplicación Myngo.
class Comunidad {
  final int id;
  final String nombre;
  final String descripcion;
  final int? creadorId;
  final String creadorNombre;
  final String urlPortada;
  final String? urlAvatar;
  final String? urlFondo;
  final Map<String, dynamic>? fondoPostsConfig;
  final String? fuenteComunidad;
  final bool esPublica;
  final bool esVerificada;
  bool esMiembro;
  bool esPendiente;
  int conteoPendienteAdmin;
  final int miembrosCount;
  final double ratingMedio;
  final double minRatingAcceso;
  final Color colorTema;
  final bool tiendaHabilitada;
  final String? miRol;
  final DateTime fechaCreacion;

  Comunidad({
    required this.id,
    required this.nombre,
    required this.descripcion,
    this.creadorId,
    required this.creadorNombre,
    required this.urlPortada,
    this.urlAvatar,
    this.urlFondo,
    this.fondoPostsConfig,
    this.fuenteComunidad,
    required this.esPublica,
    required this.esVerificada,
    required this.esMiembro,
    this.esPendiente = false,
    this.conteoPendienteAdmin = 0,
    this.miembrosCount = 0,
    required this.ratingMedio,
    this.minRatingAcceso = 0.0,
    this.colorTema = const Color(0xFFC35E34),
    this.tiendaHabilitada = false,
    this.miRol,
    required this.fechaCreacion,
  });

  /// Crea una instancia de [Comunidad] a partir de un mapa JSON.
  factory Comunidad.fromJson(Map<String, dynamic> json) {
    try {
      String colorHex = json['color_tema']?.toString() ?? '#C35E34';
      if (!colorHex.startsWith('#')) colorHex = '#$colorHex';
      final color = Color(int.parse(colorHex.replaceFirst('#', '0xFF')));

      return Comunidad(
        id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
        nombre: json['nombre']?.toString() ?? 'Sin nombre',
        descripcion: json['descripcion']?.toString() ?? '',
        creadorId: int.tryParse(json['creador']?.toString() ?? ''),
        creadorNombre: json['creador_nombre']?.toString() ?? 'Sistema',
        urlPortada: json['url_portada']?.toString() ?? '',
        urlAvatar: json['url_avatar']?.toString(),
        urlFondo: json['url_fondo']?.toString(),
        fondoPostsConfig: json['fondo_posts_config'] as Map<String, dynamic>?,
        fuenteComunidad: json['fuente_comunidad']?.toString(),
        esPublica: json['es_publica'] != false,
        esVerificada: json['es_verificada'] == true,
        esMiembro: json['es_miembro'] == true,
        esPendiente: json['es_pendiente'] == true,
        conteoPendienteAdmin: int.tryParse(json['conteo_pendiente_admin']?.toString() ?? '0') ?? 0,
        miembrosCount: int.tryParse(json['miembros_count']?.toString() ?? '0') ?? 0,
        ratingMedio: double.tryParse(json['rating_medio']?.toString() ?? '0.0') ?? 0.0,
        minRatingAcceso: double.tryParse(json['min_rating_acceso']?.toString() ?? '0.0') ?? 0.0,
        colorTema: color,
        tiendaHabilitada: json['tienda_habilitada'] == true,
        miRol: json['mi_rol']?.toString(),
        fechaCreacion: json['fecha_creacion'] != null 
            ? DateTime.tryParse(json['fecha_creacion'].toString()) ?? DateTime.now() 
            : DateTime.now(),
      );
    } catch (e) {
      debugPrint('Error parsing Comunidad: $e');
      return Comunidad(
        id: 0,
        nombre: 'Error',
        descripcion: '',
        creadorNombre: 'Sistema',
        urlPortada: '',
        urlAvatar: null,
        urlFondo: null,
        fondoPostsConfig: null,
        fuenteComunidad: null,
        esPublica: true,
        esVerificada: false,
        esMiembro: false,
        esPendiente: false,
        conteoPendienteAdmin: 0,
        miembrosCount: 0,
        ratingMedio: 0.0,
        minRatingAcceso: 0.0,
        colorTema: const Color(0xFFC35E34),
        tiendaHabilitada: false,
        fechaCreacion: DateTime.now(),
      );
    }
  }

  /// Convierte la instancia de [Comunidad] a un mapa JSON para enviar al backend.
  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'descripcion': descripcion,
      'url_portada': urlPortada,
      // Los campos de imágenes (urlAvatar, urlFondo) y config (fondoPostsConfig, fuente)
      // se envían vía multipart/form-data o PATCH separado en el servicio,
      // pero podemos incluir la fuente y JSON aquí si es necesario:
      if (fondoPostsConfig != null) 'fondo_posts_config': fondoPostsConfig,
      if (fuenteComunidad != null) 'fuente_comunidad': fuenteComunidad,
      'es_publica': esPublica,
      'min_rating_acceso': minRatingAcceso,
      'color_tema': '#${colorTema.value.toRadixString(16).substring(2).toUpperCase()}',
      'tienda_habilitada': tiendaHabilitada,
    };
  }
}