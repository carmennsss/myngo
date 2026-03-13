class Comentario {
  final int id;
  final int publicacionId;
  final int autorId;
  final String contenido;
  final bool esValidoIa; // Validado para prevenir agresiones [cite: 46]
  final DateTime fechaCreacion;

  Comentario({
    required this.id,
    required this.publicacionId,
    required this.autorId,
    required this.contenido,
    required this.esValidoIa,
    required this.fechaCreacion,
  });

  factory Comentario.fromJson(Map<String, dynamic> json) {
    return Comentario(
      id: json['id'],
      publicacionId: json['publicacion'],
      autorId: json['autor'],
      contenido: json['contenido'],
      esValidoIa: json['es_valido_ia'] ?? true,
      fechaCreacion: DateTime.parse(json['fecha_creacion']),
    );
  }
}