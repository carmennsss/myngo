class MeGustas {
  final int id;
  final int usuarioId;
  final int publicacionId;
  final DateTime fechaLike;

  MeGustas({
    required this.id,
    required this.usuarioId,
    required this.publicacionId,
    required this.fechaLike,
  });

  factory MeGustas.fromJson(Map<String, dynamic> json) {
    return MeGustas(
      id: json['id'],
      usuarioId: json['usuario'],
      publicacionId: json['publicacion'],
      fechaLike: DateTime.parse(json['fecha_like']),
    );
  }
}