// lib/models/perfil.dart

class Perfil {
  final int id;
  final int usuarioId; // Relación OneToOne
  final String? biografia;
  final String? urlAvatar;
  final int puntos; // Límite de 5000 puntos
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
      puntos: json['puntos'] ?? 0, [cite: 37]
      fechaActualizacion: DateTime.parse(json['fecha_actualizacion']),
    );
  }
}