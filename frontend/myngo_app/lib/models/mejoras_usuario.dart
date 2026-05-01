/// Modelo que representa la propiedad de una mejora por parte de un usuario.
///
/// Vincula un artículo del catálogo con el usuario que lo adquirió y
/// mantiene el estado de equipación (activo en el perfil).
class MejorasUsuario {
  final int id;
  final int usuarioId;
  final int mejoraId;

  /// Indica si el usuario tiene actualmente equipada esta mejora en su perfil.
  final bool estaEquipada;

  final DateTime fechaAdquisicion;

  MejorasUsuario({
    required this.id,
    required this.usuarioId,
    required this.mejoraId,
    required this.estaEquipada,
    required this.fechaAdquisicion,
  });

  /// Crea una instancia de [MejorasUsuario] a partir de un mapa JSON.
  factory MejorasUsuario.fromJson(Map<String, dynamic> json) {
    return MejorasUsuario(
      id: json['id'] ?? 0,
      usuarioId: json['usuario'] ?? 0,
      mejoraId: json['mejora'] ?? 0,
      estaEquipada: json['esta_equipada'] ?? false,
      fechaAdquisicion: json['fecha_adquisicion'] != null
          ? DateTime.parse(json['fecha_adquisicion'])
          : DateTime.now(),
    );
  }
}