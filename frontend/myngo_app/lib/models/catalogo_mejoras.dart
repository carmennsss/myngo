// lib/models/catalogo_mejoras.dart

class CatalogoMejoras {
  final int id;
  final String tipo; // Ej: 'MARCO', 'FONDO'
  final int precioPuntos;
  final String urlRecurso;
  final int? comunidadId;
  final int? creadorId;
  final String? nombreCreador;
  final bool estaActivo;

  CatalogoMejoras({
    required this.id,
    required this.tipo,
    required this.precioPuntos,
    required this.urlRecurso,
    this.comunidadId,
    this.creadorId,
    this.nombreCreador,
    this.estaActivo = true,
  });

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
    );
  }
}