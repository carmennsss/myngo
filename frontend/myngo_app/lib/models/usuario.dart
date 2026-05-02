/// Modelo que representa a un usuario del sistema Myngo.
///
/// Contiene la información básica de la cuenta, metadatos del perfil,
/// estadísticas de reputación y estado de conexión.
class Usuario {
  final int id;
  final int perfilId;
  final String nombreUsuario;
  final String email;
  final String? contrasena;

  /// Indica si el usuario ha verificado su cuenta (necesario para votar).
  final bool esVerificado;

  /// Determina si el perfil es público o si requiere solicitud de seguimiento.
  final bool esPublico;

  /// Puntuación de reputación media del usuario (0.0 a 5.0).
  final double ratingActual;

  final DateTime fechaRegistro;
  final String? biografia;
  final String? urlAvatar;
  final String? fondo;
  final String? marco;

  /// Puntos acumulados por actividad en la plataforma.
  int? puntos;

  final int numeroSeguidores;
  final int numeroSeguidos;

  /// Estado de la relación entre el usuario autenticado y este usuario
  /// (e.g., 'ACEPTADO', 'SOLICITUD', null).
  final String? estadoSeguimiento;

  /// Configuración visual para la personalización de posts.
  final Map<String, dynamic>? estiloPost;

  /// Estado de presencia en tiempo real ('ACTIVO', 'OCUPADO', 'DESCONECTADO').
  String? estado;

  Usuario({
    required this.id,
    required this.perfilId,
    required this.nombreUsuario,
    required this.email,
    this.contrasena,
    required this.esVerificado,
    required this.esPublico,
    required this.ratingActual,
    required this.fechaRegistro,
    this.biografia,
    this.urlAvatar,
    this.fondo,
    this.marco,
    this.puntos,
    this.numeroSeguidores = 0,
    this.numeroSeguidos = 0,
    this.estadoSeguimiento,
    this.estiloPost,
    this.estado = 'DESCONECTADO',
  });

  /// Crea una instancia de [Usuario] a partir de un mapa JSON.
  factory Usuario.fromJson(Map<String, dynamic> json) {
    try {
      return Usuario(
        id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
        perfilId: int.tryParse(json['perfil_id']?.toString() ?? json['autor_perfil_id']?.toString() ?? '0') ?? 0,
        nombreUsuario: json['nombre_usuario']?.toString() ?? json['autor_nombre']?.toString() ?? 'Desconocido',
        email: json['email']?.toString() ?? '',
        contrasena: json['contrasena']?.toString(),
        esVerificado: json['es_verificado'] == true,
        esPublico: json['es_publico'] != false,
        ratingActual:
            double.tryParse(json['rating_actual']?.toString() ?? '0.0') ?? 0.0,
        fechaRegistro: json['fecha_registro'] != null
            ? DateTime.tryParse(json['fecha_registro'].toString()) ??
                DateTime.now()
            : DateTime.now(),
        biografia: json['biografia']?.toString(),
        urlAvatar: json['url_avatar']?.toString() ?? json['autor_foto']?.toString(),
        fondo: json['fondo']?.toString() ?? json['autor_fondo']?.toString(),
        marco: json['marco']?.toString() ?? json['autor_marco']?.toString(),
        puntos: int.tryParse(json['puntos']?.toString() ?? '0'),
        numeroSeguidores:
            int.tryParse(json['numero_seguidores']?.toString() ?? '0') ?? 0,
        numeroSeguidos:
            int.tryParse(json['numero_seguidos']?.toString() ?? '0') ?? 0,
        estadoSeguimiento: json['estado_seguimiento']?.toString(),
        estiloPost: json['estilo_post'] is Map
            ? Map<String, dynamic>.from(json['estilo_post'])
            : null,
        estado: json['estado']?.toString() ?? 'DESCONECTADO',
      );
    } catch (e) {
      // ignore: avoid_print
      print('Error parsing Usuario: $e');
      return Usuario(
        id: 0,
        perfilId: 0,
        nombreUsuario: 'Error',
        email: '',
        esVerificado: false,
        esPublico: true,
        ratingActual: 0.0,
        fechaRegistro: DateTime.now(),
      );
    }
  }
}