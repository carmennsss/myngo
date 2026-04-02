class MiembrosComunidades {
  final int id;
  final int usuarioId;
  final int comunidadId;
  final String rol; // 'MIEMBRO' o 'ADMIN' 
  final DateTime fechaUnion;

  MiembrosComunidades({
    required this.id,
    required this.usuarioId,
    required this.comunidadId,
    required this.rol,
    required this.fechaUnion,
  });

  factory MiembrosComunidades.fromJson(Map<String, dynamic> json) {
    return MiembrosComunidades(
      id: json['id'],
      usuarioId: json['usuario'],
      comunidadId: json['comunidad'],
      rol: json['rol'] ?? 'Miembro',
      fechaUnion: DateTime.parse(json['fecha_union']),
    );
  }
}