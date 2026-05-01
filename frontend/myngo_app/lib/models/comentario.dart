/// Modelo que representa un comentario en una publicación.
///
/// Incluye el contenido del comentario, metadatos del autor y la fecha
/// de creación.
class Comentario {
  final int id;
  final int publicacionId;
  final int autorId;
  final String autorNombre;
  final String? autorFoto;
  final String? autorMarco;
  final String? autorFondo;
  final String contenido;

  /// Indica si el comentario ha pasado el filtro de seguridad de la IA.
  final bool esValidoIa;

  final DateTime fechaCreacion;

  Comentario({
    required this.id,
    required this.publicacionId,
    required this.autorId,
    required this.autorNombre,
    this.autorFoto,
    this.autorMarco,
    this.autorFondo,
    required this.contenido,
    required this.esValidoIa,
    required this.fechaCreacion,
  });

  /// Crea una instancia de [Comentario] a partir de un mapa JSON.
  factory Comentario.fromJson(Map<String, dynamic> json) {
    return Comentario(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      publicacionId: int.tryParse(json['publicacion']?.toString() ?? '0') ?? 0,
      autorId: int.tryParse(json['autor']?.toString() ?? '0') ?? 0,
      autorNombre: json['autor_nombre']?.toString() ?? 'Anónimo',
      autorFoto: json['autor_foto']?.toString(),
      autorMarco: json['autor_marco']?.toString(),
      autorFondo: json['autor_fondo']?.toString(),
      contenido: json['contenido']?.toString() ?? '',
      esValidoIa: json['es_valido_ia'] ?? true,
      fechaCreacion: json['fecha_creacion'] != null
          ? DateTime.tryParse(json['fecha_creacion'].toString()) ??
              DateTime.now()
          : DateTime.now(),
    );
  }
}