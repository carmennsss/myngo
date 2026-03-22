// lib/models/usuario.dart

class Usuario {
  final int id;
  final String nombreUsuario;
  final String email;
  final String? contrasena; 
  final bool esVerificado; // Necesario para poder votar 
  final bool esPublico; // Determina si la biografía es visible y cómo se le sigue
  final double ratingActual; // Sistema de 0 a 5 estrellas 
  final DateTime fechaRegistro;
  final String? biografia;
  final String? urlAvatar;
  final int? puntos;

  Usuario({
    required this.id,
    required this.nombreUsuario,
    required this.email,
    this.contrasena,
    required this.esVerificado,
    required this.esPublico,
    required this.ratingActual,
    required this.fechaRegistro,
    this.biografia,
    this.urlAvatar,
    this.puntos,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'],
      nombreUsuario: json['nombre_usuario'],
      email: json['email'],
      contrasena: json['contrasena'],
      // Solo se puede votar a usuarios y comunidades verificadas 
      esVerificado: json['es_verificado'] ?? false, 
      esPublico: json['es_publico'] ?? true, // Por defecto público si no existe
      // Rating basado en puntuación diaria de 0 a 5 
      ratingActual: double.parse(json['rating_actual'].toString()), 
      fechaRegistro: DateTime.parse(json['fecha_registro']),
      biografia: json['biografia'],
      urlAvatar: json['url_avatar'],
      puntos: json['puntos'],
    );
  }
}