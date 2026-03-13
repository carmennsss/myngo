class ImagenesEnColecciones {
  final int id;
  final int coleccionId;
  final int imagenId;

  ImagenesEnColecciones({
    required this.id,
    required this.coleccionId,
    required this.imagenId,
  });

  factory ImagenesEnColecciones.fromJson(Map<String, dynamic> json) {
    return ImagenesEnColecciones(
      id: json['id'],
      coleccionId: json['coleccion'],
      imagenId: json['imagen'],
    );
  }
}