// lib/models/mejoras_usuario.dart

class MejorasUsuario {
  final int id;
  final int usuarioId;
  final int mejoraId;
  final bool estaEquipada; // Para renderizar el marco/fondo en el perfil
  final DateTime fechaAdquisicion;

  MejorasUsuario({
    required this.id,
    required this.usuarioId,
    required this.mejoraId,
    required this.estaEquipada,
    required this.fechaAdquisicion,
  });

  factory MejorasUsuario.fromJson(Map<String, dynamic> json) {
    return MejorasUsuario(
      id: json['id'],
      usuarioId: json['usuario'],
      mejoraId: json['mejora'],
      estaEquipada: json['esta_equipada'] ?? false,
      fechaAdquisicion: DateTime.parse(json['fecha_adquisicion']),
    );
  }
}