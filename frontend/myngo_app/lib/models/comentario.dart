class Comentario {
  final int id;
  final int publicacionId;
  final int autorId;
  final String autorNombre;
  final String? autorFoto;
  final String contenido;
  final bool esValidoIa; // Validado para prevenir agresiones [cite: 46]
  final DateTime fechaCreacion;

  Comentario({
    required this.id,
    required this.publicacionId,
    required this.autorId,
    required this.autorNombre,
    this.autorFoto,
    required this.contenido,
    required this.esValidoIa,
    required this.fechaCreacion,
  });

  factory Comentario.fromJson(Map<String, dynamic> json) {
    return Comentario(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      publicacionId: int.tryParse(json['publicacion']?.toString() ?? '0') ?? 0,
      autorId: int.tryParse(json['autor']?.toString() ?? '0') ?? 0,
      autorNombre: json['autor_nombre']?.toString() ?? 'Anónimo',
      autorFoto: json['autor_foto']?.toString(),
      contenido: json['contenido']?.toString() ?? '',
      esValidoIa: json['es_valido_ia'] ?? true,
      fechaCreacion: json['fecha_creacion'] != null 
          ? DateTime.parse(json['fecha_creacion'].toString()) 
          : DateTime.now(),
    );
  }
}