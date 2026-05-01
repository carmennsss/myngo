/// Modelo que representa una sala de chat.
///
/// Puede ser una sala de grupo dentro de una comunidad o una sala
/// de chat privado entre dos usuarios.
class SalaChat {
  final int id;
  final String nombre;
  final int comunidadId;
  final bool esGrupal;
  final DateTime fechaCreacion;

  SalaChat({
    required this.id,
    required this.nombre,
    required this.comunidadId,
    required this.esGrupal,
    required this.fechaCreacion,
  });

  /// Crea una instancia de [SalaChat] a partir de un mapa JSON.
  factory SalaChat.fromJson(Map<String, dynamic> json) {
    return SalaChat(
      id: json['id'] ?? 0,
      nombre: json['nombre']?.toString() ?? 'General',
      comunidadId: json['comunidad'] ?? 0,
      esGrupal: json['es_grupal'] ?? false,
      fechaCreacion: json['fecha_creacion'] != null
          ? DateTime.parse(json['fecha_creacion'])
          : DateTime.now(),
    );
  }
}
