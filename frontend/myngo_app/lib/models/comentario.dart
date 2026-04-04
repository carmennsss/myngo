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
      id: json['id'] ?? 0,
      publicacionId: json['publicacion'] ?? 0,
      autorId: json['autor'] ?? 0,
      contenido: json['contenido']?.toString() ?? '',
      esValidoIa: json['es_valido_ia'] ?? true,
      fechaCreacion: json['fecha_creacion'] != null 
          ? DateTime.parse(json['fecha_creacion']) 
          : DateTime.now(),
    );
  }
}