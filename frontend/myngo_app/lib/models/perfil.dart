// lib/models/perfil.dart

class Perfil {
  final int id;
  final int usuarioId; // Relación OneToOne con Usuario
  final String? biografia;
  final String? urlAvatar;
  final int puntos; // Límite de 5000 puntos según anteproyecto
  final DateTime fechaActualizacion;

  Perfil({
    required this.id,
    required this.usuarioId,
    this.biografia,
    this.urlAvatar,
    required this.puntos,
    required this.fechaActualizacion,
  });

  factory Perfil.fromJson(Map<String, dynamic> json) {
    return Perfil(
      id: json['id'],
      usuarioId: json['usuario'],
      biografia: json['biografia'],
      urlAvatar: json['url_avatar'],
      // Los puntos se generan por estrellas recibidas
      // Máximo de 5.000 puntos por usuario
      puntos: json['puntos'] ?? 0, 
      fechaActualizacion: DateTime.parse(json['fecha_actualizacion']),
    );
  }
}