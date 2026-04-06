import 'package:flutter/material.dart';

/// Modelo que representa una comunidad en la aplicación Myngo.
class Comunidad {
  final int id;
  final String nombre;
  final String descripcion;
  final int? creadorId;
  final String creadorNombre;
  final String urlPortada;
  final bool esPublica;
  final bool esVerificada;
  bool esMiembro;
  bool esPendiente;
  int conteoPendienteAdmin;
  final int miembrosCount;
  final double ratingMedio;
  final double minRatingAcceso;
  final Color colorTema;
  final String? miRol;
  final DateTime fechaCreacion;

  Comunidad({
    required this.id,
    required this.nombre,
    required this.descripcion,
    this.creadorId,
    required this.creadorNombre,
    required this.urlPortada,
    required this.esPublica,
    required this.esVerificada,
    required this.esMiembro,
    this.esPendiente = false,
    this.conteoPendienteAdmin = 0,
    this.miembrosCount = 0,
    required this.ratingMedio,
    this.minRatingAcceso = 0.0,
    this.colorTema = const Color(0xFFC35E34),
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
        esPublica: json['es_publica'] != false,
        esVerificada: json['es_verificada'] == true,
        esMiembro: json['es_miembro'] == true,
        esPendiente: json['es_pendiente'] == true,
        conteoPendienteAdmin: int.tryParse(json['conteo_pendiente_admin']?.toString() ?? '0') ?? 0,
        miembrosCount: int.tryParse(json['miembros_count']?.toString() ?? '0') ?? 0,
        ratingMedio: double.tryParse(json['rating_medio']?.toString() ?? '0.0') ?? 0.0,
        minRatingAcceso: double.tryParse(json['min_rating_acceso']?.toString() ?? '0.0') ?? 0.0,
        colorTema: color,
        miRol: json['mi_rol']?.toString(),
        fechaCreacion: json['fecha_creacion'] != null 
            ? DateTime.tryParse(json['fecha_creacion'].toString()) ?? DateTime.now() 
            : DateTime.now(),
      );
    } catch (e) {
      print('Error parsing Comunidad: $e');
      return Comunidad(
        id: 0,
        nombre: 'Error',
        descripcion: '',
        creadorNombre: '',
        urlPortada: '',
        esPublica: true,
        esVerificada: false,
        esMiembro: false,
        ratingMedio: 0.0,
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
      'es_publica': esPublica,
      'min_rating_acceso': minRatingAcceso,
      'color_tema': '#${colorTema.value.toRadixString(16).substring(2).toUpperCase()}',
    };
  }
}