/// Modelo que representa un "me gusta" dado por un usuario a una publicación.
class MeGusta {
  final int id;
  final int usuarioId;
  final int publicacionId;
  final DateTime fechaLike;

  MeGusta({
    required this.id,
    required this.usuarioId,
    required this.publicacionId,
    required this.fechaLike,
  });

  /// Crea una instancia de [MeGusta] a partir de un mapa JSON.
  factory MeGusta.fromJson(Map<String, dynamic> json) {
    return MeGusta(
      id: json['id'] ?? 0,
      usuarioId: json['usuario'] ?? 0,
      publicacionId: json['publicacion'] ?? 0,
      fechaLike: json['fecha_like'] != null
          ? DateTime.parse(json['fecha_like'])
          : DateTime.now(),
    );
  }
}