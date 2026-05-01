import 'usuario.dart';

/// Modelo que representa el perfil extendido de un usuario.
///
/// Incluye personalizaciones visuales, estadísticas de seguidores
/// y el objeto [Usuario] anidado con los datos de cuenta.
class Perfil {
  final String? biografia;
  final String? urlAvatar;
  final String? fondo;
  final String? marco;
  final int numeroSeguidores;
  final int numeroSeguidos;

  /// Estado de la relación de seguimiento entre el usuario autenticado y este perfil.
  final String? estadoSeguimiento;

  /// Configuración visual de los posts para este perfil.
  final Map<String, dynamic>? estiloPost;

  /// Datos básicos de cuenta del usuario asociado a este perfil.
  final Usuario? datosUsuario;

  /// Nombre de usuario heredado de los datos de cuenta.
  String get nombreUsuario => datosUsuario?.nombreUsuario ?? 'Desconocido';

  /// Reputación media heredada de los datos de cuenta.
  double get ratingActual => datosUsuario?.ratingActual ?? 0.0;

  /// Estado de verificación heredado de los datos de cuenta.
  bool get esVerificado => datosUsuario?.esVerificado ?? false;

  Perfil({
    this.biografia,
    this.urlAvatar,
    this.fondo,
    this.marco,
    required this.numeroSeguidores,
    required this.numeroSeguidos,
    this.estadoSeguimiento,
    this.estiloPost,
    this.datosUsuario,
  });

  /// Crea una instancia de [Perfil] a partir de un mapa JSON.
  factory Perfil.fromJson(Map<String, dynamic> json) {
    return Perfil(
      biografia: json['biografia']?.toString(),
      urlAvatar: json['url_avatar']?.toString(),
      fondo: json['fondo']?.toString(),
      marco: json['marco']?.toString(),
      estiloPost: json['estilo_post'] is Map
          ? Map<String, dynamic>.from(json['estilo_post'])
          : null,
      numeroSeguidores:
          int.tryParse(json['numero_seguidores']?.toString() ?? '0') ?? 0,
      numeroSeguidos:
          int.tryParse(json['numero_seguidos']?.toString() ?? '0') ?? 0,
      estadoSeguimiento: json['estado_seguimiento']?.toString(),
      datosUsuario: json['datos_usuario'] != null
          ? Usuario.fromJson(json['datos_usuario'])
          : null,
    );
  }
}