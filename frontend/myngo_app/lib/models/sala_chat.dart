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

  factory SalaChat.fromJson(Map<String, dynamic> json) {
    return SalaChat(
      id: json['id'],
      nombre: json['nombre'],
      comunidadId: json['comunidad'],
      esGrupal: json['es_grupal'] ?? false,
      fechaCreacion: DateTime.parse(json['fecha_creacion']),
    );
  }
}
