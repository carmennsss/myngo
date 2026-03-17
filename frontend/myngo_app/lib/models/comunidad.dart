/// Modelo que representa una comunidad en la aplicación Myngo.
class Comunidad {
  final int id;
  final String nombre;
  final String descripcion;
  final int? creadorId;
  final String creadorNombre;
  final String urlPortada;
  final bool esPublica;
  final bool esVerificada;
  final double ratingMedio;
  final DateTime fechaCreacion;

  Comunidad({
    required this.id,
    required this.nombre,
    required this.descripcion,
    this.creadorId,
    required this.creadorNombre,
    required this.urlPortada,
    required this.esPublica,
    required this.esVerificada,
    required this.ratingMedio,
    required this.fechaCreacion,
  });

  /// Crea una instancia de [Comunidad] a partir de un mapa JSON.
  factory Comunidad.fromJson(Map<String, dynamic> json) {
    return Comunidad(
      id: json['id'],
      nombre: json['nombre'],
      descripcion: json['descripcion'] ?? '',
      creadorId: json['creador'],
      creadorNombre: json['creador_nombre'] ?? 'Sistema',
      urlPortada: json['url_portada'] ?? '',
      esPublica: json['es_publica'] ?? true,
      esVerificada: json['es_verificada'] ?? false,
      ratingMedio: double.tryParse(json['rating_medio'].toString()) ?? 0.0,
      fechaCreacion: DateTime.parse(json['fecha_creacion']),
    );
  }

  /// Convierte la instancia de [Comunidad] a un mapa JSON para enviar al backend.
  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'descripcion': descripcion,
      'url_portada': urlPortada,
      'es_publica': esPublica,
    };
  }
}