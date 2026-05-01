/// Modelo que representa un artículo disponible en el catálogo de mejoras.
///
/// Incluye cosméticos globales (marcos, fondos) o específicos de comunidad,
/// junto con su precio en puntos y metadatos adicionales.
class CatalogoMejoras {
  final int id;

  /// Tipo de mejora (e.g., 'MARCO', 'FONDO', 'ESTILO_POST').
  final String tipo;

  final int precioPuntos;

  /// URL del recurso visual asociado a la mejora.
  final String urlRecurso;

  final int? comunidadId;
  final int? creadorId;
  final String? nombreCreador;
  final bool estaActivo;

  /// Datos técnicos adicionales para el renderizado (e.g., colores, bordes).
  final Map<String, dynamic>? datosExtra;

  CatalogoMejoras({
    required this.id,
    required this.tipo,
    required this.precioPuntos,
    required this.urlRecurso,
    this.comunidadId,
    this.creadorId,
    this.nombreCreador,
    this.estaActivo = true,
    this.datosExtra,
  });

  /// Crea una instancia de [CatalogoMejoras] a partir de un mapa JSON.
  factory CatalogoMejoras.fromJson(Map<String, dynamic> json) {
    return CatalogoMejoras(
      id: json['id'] ?? 0,
      tipo: json['tipo']?.toString() ?? 'OTRO',
      precioPuntos: (json['precio_puntos'] ?? 0).toInt(),
      urlRecurso: json['url_recurso']?.toString() ?? '',
      comunidadId: json['comunidad'],
      creadorId: json['creador'],
      nombreCreador: json['nombre_creador'],
      estaActivo: json['esta_activo'] ?? true,
      datosExtra: json['datos_extra'] is Map
          ? Map<String, dynamic>.from(json['datos_extra'])
          : null,
    );
  }
}