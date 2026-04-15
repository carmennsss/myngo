import 'usuario.dart'; // Importante para el campo datosUsuario

class Perfil {
  final String? biografia;
  final String? urlAvatar;
  final String? fondo;
  final String? marco;
  final int numeroSeguidores;
  final int numeroSeguidos;
  final String? estadoSeguimiento;
  final Usuario? datosUsuario; // El "perro" que va dentro del "gato"
String get nombreUsuario => datosUsuario?.nombreUsuario ?? 'Desconocido';
  double get ratingActual => datosUsuario?.ratingActual ?? 0.0;
  bool get esVerificado => datosUsuario?.esVerificado ?? false;
  Perfil({
    this.biografia,
    this.urlAvatar,
    this.fondo,
    this.marco,
    required this.numeroSeguidores,
    required this.numeroSeguidos,
    this.estadoSeguimiento,
    this.datosUsuario,
  });

  factory Perfil.fromJson(Map<String, dynamic> json) {
    return Perfil(
      // 1. Biografía (String opcional)
      biografia: json['biografia']?.toString(),

      // 2. URL Avatar (String opcional generado por el SerializerMethodField)
      urlAvatar: json['url_avatar']?.toString(),

      fondo: json['fondo']?.toString(),
      marco: json['marco']?.toString(),

      // 3. Número de seguidores (int, con fallback a 0)
      numeroSeguidores: int.tryParse(json['numero_seguidores']?.toString() ?? '0') ?? 0,

      // 4. Número de seguidos (int, con fallback a 0)
      numeroSeguidos: int.tryParse(json['numero_seguidos']?.toString() ?? '0') ?? 0,

      // 5. Estado de seguimiento (String opcional: 'ACEPTADO', 'SOLICITUD', etc.)
      estadoSeguimiento: json['estado_seguimiento']?.toString(),

      // 6. Datos del Usuario (Objeto anidado transformado por el UsuarioSerializer)
      datosUsuario: json['datos_usuario'] != null 
          ? Usuario.fromJson(json['datos_usuario']) 
          : null,
    );
  }
}