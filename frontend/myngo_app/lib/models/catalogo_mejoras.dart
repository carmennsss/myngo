// lib/models/catalogo_mejoras.dart

class CatalogoMejoras {
  final int id;
  final String nombre;
  final String tipo; // Ej: 'MARCO', 'FONDO'
  final int precioPuntos; // Se restarán de los puntos del perfil (máx 5000) [cite: 37, 62]
  final String urlRecurso;

  CatalogoMejoras({
    required this.id,
    required this.nombre,
    required this.tipo,
    required this.precioPuntos,
    required this.urlRecurso,
  });

  factory CatalogoMejoras.fromJson(Map<String, dynamic> json) {
    return CatalogoMejoras(
      id: json['id'],
      nombre: json['nombre'],
      tipo: json['tipo'],
      precioPuntos: json['precio_puntos'] ?? 0,
      urlRecurso: json['url_recurso'],
    );
  }
}