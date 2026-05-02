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
  final int? otroUsuarioId;

  SalaChat({
    required this.id,
    required this.nombre,
    required this.comunidadId,
    required this.esGrupal,
    required this.fechaCreacion,
    this.otroUsuarioId,
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
      otroUsuarioId: _extraerOtroUsuarioId(json),
    );
  }

  static int? _extraerOtroUsuarioId(Map<String, dynamic> json) {
    if (json['es_grupal'] == true) return null;
    final miembros = json['miembros'];
    if (miembros != null && miembros is List) {
      // Intenta encontrar el que no es el id local, pero no tenemos el id local aquí fácilmente.
      // Así que lo dejamos para que el servicio lo asigne, o miramos 'miembros_detalle'.
      if (json['miembros_detalle'] != null && json['miembros_detalle'] is List) {
        final detalles = json['miembros_detalle'] as List;
        if (detalles.length == 2) {
          // No sabemos cuál es el nuestro sin el provider, así que esto se resolverá
          // en el servicio de mensajería.
        }
      }
    }
    return json['_otro_usuario_id']; // Lo inyectaremos en el parseo superior
  }
}
