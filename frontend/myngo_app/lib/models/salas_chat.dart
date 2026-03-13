class SalaChat {
  final int id;
  final String? nombre; // Opcional para chats 1 a 1 [cite: 40]
  final int comunidadId; // ID de la comunidad vinculada [cite: 13, 66]
  final bool esGrupal; // Diferencia entre chats privados y de grupo [cite: 40, 66]
  final DateTime fechaCreacion;

  SalaChat({
    required this.id,
    this.nombre,
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