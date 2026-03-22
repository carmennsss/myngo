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
  final int numeroSeguidores;
  final int numeroSeguidos;
  final String? estadoSeguimiento;

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
    this.numeroSeguidores = 0,
    this.numeroSeguidos = 0,
    this.estadoSeguimiento,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'] ?? 0,
      nombreUsuario: json['nombre_usuario'] ?? 'Desconocido',
      email: json['email'] ?? '',
      contrasena: json['contrasena'],
      esVerificado: json['es_verificado'] ?? false, 
      esPublico: json['es_publico'] ?? true, 
      ratingActual: json['rating_actual'] != null ? double.parse(json['rating_actual'].toString()) : 0.0, 
      fechaRegistro: json['fecha_registro'] != null ? DateTime.parse(json['fecha_registro']) : DateTime.now(),
      biografia: json['biografia'],
      urlAvatar: json['url_avatar'],
      puntos: json['puntos'],
      numeroSeguidores: json['numero_seguidores'] ?? 0,
      numeroSeguidos: json['numero_seguidos'] ?? 0,
      estadoSeguimiento: json['estado_seguimiento'],
    );
  }
}