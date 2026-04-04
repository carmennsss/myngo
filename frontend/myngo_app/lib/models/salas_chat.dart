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
      id: json['id'] ?? 0,
      nombre: json['nombre']?.toString(),
      comunidadId: json['comunidad'] ?? 0,
      esGrupal: json['es_grupal'] ?? false,
      fechaCreacion: json['fecha_creacion'] != null 
          ? DateTime.parse(json['fecha_creacion']) 
          : DateTime.now(),
    );
  }
}