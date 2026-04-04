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
      id: json['id'] ?? 0,
      usuarioId: json['usuario'] ?? 0,
      biografia: json['biografia']?.toString(),
      urlAvatar: json['url_avatar']?.toString(),
      puntos: (json['puntos'] ?? 0).toInt(), 
      fechaActualizacion: json['fecha_actualizacion'] != null 
          ? DateTime.parse(json['fecha_actualizacion']) 
          : DateTime.now(),
    );
  }
}