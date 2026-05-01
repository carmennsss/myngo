/// Modelo que representa la pertenencia de un usuario a una comunidad.
///
/// Define el rol del usuario (e.g., 'ADMIN', 'MODERADOR', 'MIEMBRO')
/// y la fecha en que se unió.
class MiembroComunidad {
  final int id;
  final int usuarioId;
  final int comunidadId;

  /// Rol asignado al usuario en esta comunidad.
  final String rol;

  final DateTime fechaUnion;

  MiembroComunidad({
    required this.id,
    required this.usuarioId,
    required this.comunidadId,
    required this.rol,
    required this.fechaUnion,
  });

  /// Crea una instancia de [MiembroComunidad] a partir de un mapa JSON.
  factory MiembroComunidad.fromJson(Map<String, dynamic> json) {
    return MiembroComunidad(
      id: json['id'] ?? 0,
      usuarioId: json['usuario'] ?? 0,
      comunidadId: json['comunidad'] ?? 0,
      rol: json['rol']?.toString() ?? 'MIEMBRO',
      fechaUnion: json['fecha_union'] != null
          ? DateTime.parse(json['fecha_union'])
          : DateTime.now(),
    );
  }
}