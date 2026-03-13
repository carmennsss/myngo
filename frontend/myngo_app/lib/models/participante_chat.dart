class ParticipanteChat {
  final int id;
  final int salaId;
  final int usuarioId;
  final DateTime fechaUnion;

  ParticipanteChat({
    required this.id,
    required this.salaId,
    required this.usuarioId,
    required this.fechaUnion,
  });

  factory ParticipanteChat.fromJson(Map<String, dynamic> json) {
    return ParticipanteChat(
      id: json['id'],
      salaId: json['sala'],
      usuarioId: json['usuario'],
      fechaUnion: DateTime.parse(json['fecha_union']),
    );
  }
}