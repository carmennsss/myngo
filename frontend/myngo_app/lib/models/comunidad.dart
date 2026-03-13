class Comunidad {
  final int id;
  final String nombre;
  final String? descripcion;
  final int? creadorId;
  final String? urlPortada;
  final bool esPublica; // Si es pública, se pueden ver posts al seguirla
  final bool esVerificada; // Requisito para poder votar
  final double ratingActual; // Sistema de 0 a 5 estrellas
  final DateTime fechaCreacion;

  Comunidad({
    required this.id,
    required this.nombre,
    this.descripcion,
    this.creadorId,
    this.urlPortada,
    required this.esPublica,
    required this.esVerificada,
    required this.ratingActual,
    required this.fechaCreacion,
  });

  factory Comunidad.fromJson(Map<String, dynamic> json) {
    return Comunidad(
      id: json['id'],
      nombre: json['nombre'],
      descripcion: json['descripcion'],
      creadorId: json['creador'],
      urlPortada: json['url_portada'],
      esPublica: json['es_publica'] ?? true,
      esVerificada: json['es_verificada'] ?? false,
      ratingActual: double.parse(json['rating_actual'].toString()),
      fechaCreacion: DateTime.parse(json['fecha_creacion']),
    );
  }
}