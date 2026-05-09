import 'participante_chat.dart';

/// Modelo que representa la configuración visual detallada de una sala.
class PersonalizacionChat {
  final String? colorFondo;
  final String? colorBurbujaMio;
  final String? colorBurbujaOtro;
  final String? colorTextoMio;
  final String? colorTextoOtro;
  final String? colorNombreMio;
  final String? colorNombreOtro;
  final String? gradienteFondo;
  final String? patronFondo;
  final String? imagenFondoS3;
  final String formaBurbuja;
  final String estiloBurbuja;
  final int fontSize;
  final String tema;

  PersonalizacionChat({
    this.colorFondo,
    this.colorBurbujaMio,
    this.colorBurbujaOtro,
    this.colorTextoMio,
    this.colorTextoOtro,
    this.colorNombreMio,
    this.colorNombreOtro,
    this.gradienteFondo,
    this.patronFondo,
    this.imagenFondoS3,
    this.formaBurbuja = 'redondeada',
    this.estiloBurbuja = 'solido',
    this.fontSize = 14,
    this.tema = 'claro',
  });

  factory PersonalizacionChat.fromJson(Map<String, dynamic> json) {
    return PersonalizacionChat(
      colorFondo: json['color_fondo']?.toString(),
      colorBurbujaMio: json['color_burbuja_mio']?.toString(),
      colorBurbujaOtro: json['color_burbuja_otro']?.toString(),
      colorTextoMio: json['color_texto_mio']?.toString(),
      colorTextoOtro: json['color_texto_otro']?.toString(),
      colorNombreMio: json['color_nombre_mio']?.toString(),
      colorNombreOtro: json['color_nombre_otro']?.toString(),
      gradienteFondo: json['gradiente_fondo']?.toString(),
      patronFondo: json['patron_fondo']?.toString(),
      imagenFondoS3: json['imagen_fondo_s3']?.toString(),
      formaBurbuja: json['forma_burbuja']?.toString() ?? 'redondeada',
      estiloBurbuja: json['estilo_burbuja']?.toString() ?? 'solido',
      fontSize: int.tryParse(json['font_size']?.toString() ?? '') ?? 14,
      tema: json['tema']?.toString() ?? 'claro',
    );
  }

  Map<String, dynamic> toJson() => {
    'color_fondo': colorFondo,
    'color_burbuja_mio': colorBurbujaMio,
    'color_burbuja_otro': colorBurbujaOtro,
    'color_texto_mio': colorTextoMio,
    'color_texto_otro': colorTextoOtro,
    'color_nombre_mio': colorNombreMio,
    'color_nombre_otro': colorNombreOtro,
    'gradiente_fondo': gradienteFondo,
    'patron_fondo': patronFondo,
    'imagen_fondo_s3': imagenFondoS3,
    'forma_burbuja': formaBurbuja,
    'estilo_burbuja': estiloBurbuja,
    'font_size': fontSize,
    'tema': tema,
  };
}

/// Modelo que representa una sala de chat.
class SalaChat {
  final int id;
  final String nombre;
  final int comunidadId;
  final bool esGrupal;
  final DateTime fechaCreacion;
  final int? otroUsuarioId;
  final String? avatarS3;
  final Map<String, dynamic> configuracion;
  final List<ParticipanteChat> participantes;
  final PersonalizacionChat? personalizacion;
  final int numMiembros;
  final int? creador;

  SalaChat({
    required this.id,
    required this.nombre,
    required this.comunidadId,
    required this.esGrupal,
    required this.fechaCreacion,
    this.otroUsuarioId,
    this.avatarS3,
    this.configuracion = const {},
    this.participantes = const [],
    this.personalizacion,
    this.numMiembros = 0,
    this.creador,
  });

  factory SalaChat.fromJson(Map<String, dynamic> json) {
    return SalaChat(
      id: json['id'] ?? 0,
      nombre: json['nombre']?.toString() ?? 'General',
      comunidadId: json['comunidad'] ?? 0,
      esGrupal: json['es_grupal'] ?? false,
      fechaCreacion: json['fecha_creacion'] != null
          ? DateTime.parse(json['fecha_creacion'])
          : DateTime.now(),
      otroUsuarioId: _extraerOtroUsuarioId(json),
      avatarS3: json['avatar_s3'],
      configuracion: json['configuracion'] ?? {},
      participantes: (json['participantes_data'] as List? ?? [])
          .map((p) => ParticipanteChat.fromJson(p))
          .toList(),
      personalizacion: json['personalizacion'] != null 
          ? PersonalizacionChat.fromJson(json['personalizacion'])
          : null,
      numMiembros: json['num_miembros'] ?? 0,
      creador: json['creador'],
    );
  }

  static int? _extraerOtroUsuarioId(Map<String, dynamic> json) {
    if (json['es_grupal'] == true) return null;
    return json['otro_usuario_id'];
  }
}
