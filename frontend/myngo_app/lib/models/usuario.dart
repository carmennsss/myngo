// lib/models/usuario.dart

class Usuario {
  final int id;
  final String nombreUsuario;
  final String email;
  final String? contrasena; 
  final bool esVerificado; // Necesario para poder votar 
  final double ratingActual; // Sistema de 0 a 5 estrellas 
  final DateTime fechaRegistro;

  Usuario({
    required this.id,
    required this.nombreUsuario,
    required this.email,
    this.contrasena,
    required this.esVerificado,
    required this.ratingActual,
    required this.fechaRegistro,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'],
      nombreUsuario: json['nombre_usuario'],
      email: json['email'],
      contrasena: json['contrasena'],
      // Solo se puede votar a usuarios y comunidades verificadas 
      esVerificado: json['es_verificado'] ?? false, 
      // Rating basado en puntuación diaria de 0 a 5 
      ratingActual: double.parse(json['rating_actual'].toString()), 
      fechaRegistro: DateTime.parse(json['fecha_registro']),
    );
  }
}