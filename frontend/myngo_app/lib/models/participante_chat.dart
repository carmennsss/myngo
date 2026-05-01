/// Modelo que representa la participación de un usuario en una sala de chat.
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

  /// Crea una instancia de [ParticipanteChat] a partir de un mapa JSON.
  factory ParticipanteChat.fromJson(Map<String, dynamic> json) {
    return ParticipanteChat(
      id: json['id'] ?? 0,
      salaId: json['sala'] ?? 0,
      usuarioId: json['usuario'] ?? 0,
      fechaUnion: json['fecha_union'] != null
          ? DateTime.parse(json['fecha_union'])
          : DateTime.now(),
    );
  }
}