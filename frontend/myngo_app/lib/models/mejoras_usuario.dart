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