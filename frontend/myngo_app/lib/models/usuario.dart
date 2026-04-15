// lib/models/usuario.dart

class Usuario {
  final int id;
  final int perfilId;
  final String nombreUsuario;
  final String email;
  final String? contrasena; 
  final bool esVerificado; // Necesario para poder votar 
  final bool esPublico; // Determina si la biografía es visible y cómo se le sigue
  final double ratingActual; // Sistema de 0 a 5 estrellas 
  final DateTime fechaRegistro;
  final String? biografia;
  final String? urlAvatar;
  final String? fondo;
  final String? marco;
  final int? puntos;
  final int numeroSeguidores;
  final int numeroSeguidos;
  final String? estadoSeguimiento;

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
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    try {
      return Usuario(
        id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
        perfilId: int.tryParse(json['perfil_id']?.toString()??'0')??0,
        nombreUsuario: json['nombre_usuario']?.toString() ?? 'Desconocido',
        email: json['email']?.toString() ?? '',
        contrasena: json['contrasena']?.toString(),
        esVerificado: json['es_verificado'] == true, 
        esPublico: json['es_publico'] != false, 
        ratingActual: double.tryParse(json['rating_actual']?.toString() ?? '0.0') ?? 0.0, 
        fechaRegistro: json['fecha_registro'] != null 
            ? DateTime.tryParse(json['fecha_registro'].toString()) ?? DateTime.now() 
            : DateTime.now(),
        biografia: json['biografia']?.toString(),
        urlAvatar: json['url_avatar']?.toString(),
        fondo: json['fondo']?.toString(),
        marco: json['marco']?.toString(),
        puntos: int.tryParse(json['puntos']?.toString() ?? '0'),
        numeroSeguidores: int.tryParse(json['numero_seguidores']?.toString() ?? '0') ?? 0,
        numeroSeguidos: int.tryParse(json['numero_seguidos']?.toString() ?? '0') ?? 0,
        estadoSeguimiento: json['estado_seguimiento']?.toString(),
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