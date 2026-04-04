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