/// Modelo que representa una colección de imágenes del usuario.
///
/// Las colecciones pueden ser personales o estar vinculadas a una comunidad,
/// y pueden ser públicas o privadas.
class Coleccion {
  final int id;
  final int usuarioId;
  final int? comunidadId;
  String nombreColeccion;
  final String? descripcion;
  final String? categoria;
  bool esPrivada;

  /// Lista de IDs de las imágenes que pertenecen a esta colección.
  final List<int> imagenesIds;

  final int numeroImagenes;

  /// URLs de las primeras imágenes de la colección para mostrar en la previsualización.
  final List<String> previsualizaciones;

  final DateTime fechaCreacion;

  Coleccion({
    required this.id,
    required this.usuarioId,
    this.comunidadId,
    required this.nombreColeccion,
    this.descripcion,
    this.categoria,
    required this.esPrivada,
    required this.imagenesIds,
    required this.numeroImagenes,
    required this.previsualizaciones,
    required this.fechaCreacion,
  });

  /// Crea una instancia de [Coleccion] a partir de un mapa JSON.
  factory Coleccion.fromJson(Map<String, dynamic> json) {
    return Coleccion(
      id: json['id'] ?? 0,
      usuarioId: json['usuario'] ?? 0,
      comunidadId: json['comunidad'] as int?,
      nombreColeccion: json['nombre_coleccion']?.toString() ?? 'Sin nombre',
      descripcion: json['descripcion']?.toString(),
      categoria: json['categoria']?.toString(),
      esPrivada: json['es_privada'] ?? false,
      imagenesIds:
          json['imagenes'] != null ? List<int>.from(json['imagenes']) : [],
      numeroImagenes: json['numero_imagenes'] ?? 0,
      previsualizaciones: json['previsualizaciones'] != null
          ? List<String>.from(json['previsualizaciones'])
          : [],
      fechaCreacion: json['fecha_creacion'] != null
          ? DateTime.parse(json['fecha_creacion'])
          : DateTime.now(),
    );
  }
}