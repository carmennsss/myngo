class Coleccion {
  final int id;
  final int usuarioId;
  final String nombreColeccion;
  final String? categoria;
  final bool esPrivada;
  final DateTime fechaCreacion;

  Coleccion({
    required this.id,
    required this.usuarioId,
    required this.nombreColeccion,
    this.categoria,
    required this.esPrivada,
    required this.fechaCreacion,
  });

  factory Coleccion.fromJson(Map<String, dynamic> json) {
    return Coleccion(
      id: json['id'],
      usuarioId: json['usuario'],
      nombreColeccion: json['nombre_coleccion'],
      categoria: json['categoria'],
      esPrivada: json['es_privada'] ?? false,
      fechaCreacion: DateTime.parse(json['fecha_creacion']),
    );
  }
}