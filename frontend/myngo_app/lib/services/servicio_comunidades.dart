import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart' as dio;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import '../models/comunidad.dart';
import '../models/imagen_galeria.dart';
import '../models/publicacion.dart';
import '../models/respuesta_api.dart';
import '../models/sala_chat.dart';
import '../utils/configuracion.dart';
import 'servicio_usuarios.dart';

/// Servicio encargado de gestionar el ciclo de vida de las comunidades y su contenido.
///
/// Provee funcionalidades para la administración de miembros, personalización estética,
/// gestión de publicaciones, galerías multimedia y salas de chat grupales.
class ServicioComunidades {
  /// URL base para los endpoints de comunidades.
  static const String _urlComunidades = '${Configuracion.baseUrl}/comunidades/';
  
  /// URL base para los endpoints de contenido multimedia y publicaciones.
  static const String _urlContenido = '${Configuracion.baseUrl}/contenido/';
  
  /// URL base para los endpoints de mensajería grupal.
  static const String _urlMensajeria = '${Configuracion.baseUrl}/mensajeria/';

  final _servicioUsuarios = ServicioUsuarios();

  /// Genera las cabeceras estándar (JSON + Token) para las peticiones API.
  Future<Map<String, String>> _obtenerCabeceras() async {
    final token = await _servicioUsuarios.obtenerToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Token $token',
    };
  }

  /// Obtiene la lista de comunidades, permitiendo filtrar por término de búsqueda y tags.
  Future<RespuestaApi<List<Comunidad>>> listarComunidades({String? busqueda, List<String>? tags, int limit = 20, int offset = 0}) async {
    try {
      List<String> queryParts = [];
      if (busqueda != null && busqueda.isNotEmpty) queryParts.add('search=$busqueda');
      if (tags != null && tags.isNotEmpty) {
        queryParts.add('tags=${tags.join(',')}');
      }
      queryParts.add('limit=$limit');
      queryParts.add('offset=$offset');
      
      final fullQuery = queryParts.isNotEmpty ? '?${queryParts.join('&')}' : '';
      final respuesta = await http.get(
        Uri.parse('$_urlComunidades$fullQuery'),
        headers: await _obtenerCabeceras(),
      ).timeout(const Duration(seconds: 15));

      if (respuesta.statusCode == 200) {
        final dynamic datosJson = jsonDecode(utf8.decode(respuesta.bodyBytes));
        final List<dynamic> listaJson = datosJson is List ? datosJson : (datosJson['results'] ?? []);
        return RespuestaApi(
          exito: true,
          mensaje: 'Comunidades recuperadas',
          datos: listaJson.map((item) => Comunidad.fromJson(item)).toList(),
        );
      }
      return RespuestaApi(exito: false, mensaje: 'Error al listar comunidades (${respuesta.statusCode})');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  /// Sugiere comunidades populares basadas en su actividad.
  Future<RespuestaApi<List<Comunidad>>> listarComunidadesPopulares() async {
    return listarComunidades();
  }

  /// Obtiene las comunidades a las que pertenece el usuario autenticado.
  Future<RespuestaApi<List<Comunidad>>> listarComunidadesPropias() async {
    try {
      final respuesta = await http.get(
        Uri.parse('${_urlComunidades}propias/'),
        headers: await _obtenerCabeceras(),
      ).timeout(const Duration(seconds: 15));

      if (respuesta.statusCode == 200) {
        final dynamic datosJson = jsonDecode(respuesta.body);
        final List<dynamic> listaJson = datosJson is List ? datosJson : (datosJson['results'] ?? []);
        return RespuestaApi(
          exito: true,
          mensaje: 'Comunidades propias recuperadas',
          datos: listaJson.map((item) => Comunidad.fromJson(item)).toList(),
        );
      }
      return RespuestaApi(exito: false, mensaje: 'Error al obtener comunidades propias');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  /// Recupera la información detallada de una comunidad por su ID.
  Future<RespuestaApi<Comunidad>> obtenerComunidad(int idComunidad) async {
    try {
      final respuesta = await http.get(
        Uri.parse('$_urlComunidades$idComunidad/'),
        headers: await _obtenerCabeceras(),
      ).timeout(const Duration(seconds: 15));

      if (respuesta.statusCode == 200) {
        final dynamic datosJson = jsonDecode(utf8.decode(respuesta.bodyBytes));
        return RespuestaApi(
          exito: true,
          mensaje: 'Detalle de comunidad cargado',
          datos: Comunidad.fromJson(datosJson),
        );
      }
      return RespuestaApi(exito: false, mensaje: 'Error al cargar comunidad');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  /// Obtiene la lista de miembros de una comunidad con sus roles.
  Future<RespuestaApi<List<Map<String, dynamic>>>> obtenerMiembrosComunidad(int idComunidad) async {
    try {
      final respuesta = await http.get(
        Uri.parse('$_urlComunidades$idComunidad/miembros/'),
        headers: await _obtenerCabeceras(),
      ).timeout(const Duration(seconds: 15));

      if (respuesta.statusCode == 200) {
        final List<dynamic> datos = jsonDecode(utf8.decode(respuesta.bodyBytes));
        return RespuestaApi(
          exito: true,
          mensaje: 'Miembros cargados',
          datos: List<Map<String, dynamic>>.from(datos),
        );
      }
      return RespuestaApi(exito: false, mensaje: 'Error al cargar miembros');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  /// Solicita el acceso o se une directamente a una comunidad.
  Future<RespuestaApi<Map<String, dynamic>>> unirseAComunidad(int idComunidad) async {
    try {
      final respuesta = await http.post(
        Uri.parse('${_urlComunidades}$idComunidad/unirse/'),
        headers: await _obtenerCabeceras(),
      ).timeout(const Duration(seconds: 15));

      if (respuesta.statusCode == 201 || respuesta.statusCode == 200) {
        return RespuestaApi(
          exito: true,
          mensaje: 'Operación realizada correctamente',
          datos: jsonDecode(respuesta.body),
        );
      }
      return RespuestaApi(exito: false, mensaje: 'No se pudo procesar la unión');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  /// Crea una nueva comunidad permitiendo la subida de una imagen de portada y etiquetas.
  Future<RespuestaApi<Comunidad>> crearComunidad(Comunidad comunidad, {XFile? imagenPortada, List<String>? tags}) async {
    try {
      final token = await _servicioUsuarios.obtenerToken();
      final url = _urlComunidades;
      
      final clienteDio = dio.Dio();
      final cabeceras = {
        if (token != null) 'Authorization': 'Token $token',
      };
 
      final datosFormulario = dio.FormData();
      datosFormulario.fields.add(MapEntry('nombre', comunidad.nombre));
      datosFormulario.fields.add(MapEntry('descripcion', comunidad.descripcion));
      datosFormulario.fields.add(MapEntry('es_publica', comunidad.esPublica.toString()));
      datosFormulario.fields.add(MapEntry('min_rating_acceso', comunidad.minRatingAcceso.toString()));
 
      if (tags != null && tags.isNotEmpty) {
        for (var tag in tags) {
          datosFormulario.fields.add(MapEntry('tags', tag));
        }
      }
 
      if (imagenPortada != null) {
        final bytes = await imagenPortada.readAsBytes();
        final mimeType = lookupMimeType(imagenPortada.name, headerBytes: bytes) ?? 'image/jpeg';
        final typeParts = mimeType.split('/');
        
        datosFormulario.files.add(MapEntry(
          'url_portada',
          dio.MultipartFile.fromBytes(
            bytes,
            filename: imagenPortada.name,
            contentType: MediaType(typeParts[0], typeParts[1]),
          ),
        ));
      }
 
      final respuesta = await clienteDio.post(
        url,
        data: datosFormulario,
        options: dio.Options(headers: cabeceras),
      );
 
      if (respuesta.statusCode == 201 || respuesta.statusCode == 200) {
        final datosJson = respuesta.data is String ? jsonDecode(respuesta.data) : respuesta.data;
        return RespuestaApi(
          exito: true,
          mensaje: '¡Comunidad creada con éxito!',
          datos: Comunidad.fromJson(datosJson),
        );
      }
      return RespuestaApi(exito: false, mensaje: 'Error al crear comunidad (${respuesta.statusCode})');
    } catch (e) {
      String msg = 'Error de conexión: $e';
      if (e is dio.DioException) {
        msg = e.response?.data?.toString() ?? e.message ?? msg;
      }
      return RespuestaApi(exito: false, mensaje: msg);
    }
  }

  /// Moderación: Acepta o rechaza una solicitud de unión pendiente.
  Future<RespuestaApi<void>> responderPeticionAcceso(int idPeticion, bool aceptar) async {
    try {
      final respuesta = await http.post(
        Uri.parse('${_urlComunidades}responder-peticion/$idPeticion/'),
        headers: await _obtenerCabeceras(),
        body: jsonEncode({'aceptar': aceptar}),
      ).timeout(const Duration(seconds: 15));

      if (respuesta.statusCode == 200) {
        return RespuestaApi(exito: true, mensaje: 'Petición procesada');
      }
      return RespuestaApi(exito: false, mensaje: 'Error al responder petición');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  /// Recupera métricas y solicitudes para el panel de administración de la comunidad.
  Future<RespuestaApi<Map<String, dynamic>>> obtenerDashboardAdmin(int idComunidad) async {
    try {
      final respuesta = await http.get(
        Uri.parse('${_urlComunidades}$idComunidad/admin-dashboard/'),
        headers: await _obtenerCabeceras(),
      ).timeout(const Duration(seconds: 25));

      if (respuesta.statusCode == 200) {
        return RespuestaApi(
          exito: true,
          mensaje: 'Datos de administración cargados',
          datos: jsonDecode(utf8.decode(respuesta.bodyBytes)),
        );
      }
      return RespuestaApi(exito: false, mensaje: 'Error al cargar panel administrativo');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  /// Actualiza los parámetros estéticos y funcionales de una comunidad.
  Future<RespuestaApi<Comunidad>> actualizarComunidad(
    int idComunidad, {
    String? nombre,
    String? descripcion,
    String? colorTema,
    bool? tiendaHabilitada,
    XFile? banner,
    XFile? avatar,
    XFile? fondo,
    Map<String, dynamic>? fondoPostsConfig,
    String? fuenteComunidad,
    List<String>? tags,
  }) async {
    try {
      final token = await _servicioUsuarios.obtenerToken();
      final url = '${_urlComunidades}$idComunidad/';
      
      final clienteDio = dio.Dio();
      final cabeceras = {
        if (token != null) 'Authorization': 'Token $token',
      };
 
      final datosFormulario = dio.FormData();
 
      if (nombre != null) datosFormulario.fields.add(MapEntry('nombre', nombre));
      if (descripcion != null) datosFormulario.fields.add(MapEntry('descripcion', descripcion));
      if (colorTema != null) datosFormulario.fields.add(MapEntry('color_tema', colorTema));
      if (tiendaHabilitada != null) datosFormulario.fields.add(MapEntry('tienda_habilitada', tiendaHabilitada.toString()));
      if (fondoPostsConfig != null) datosFormulario.fields.add(MapEntry('fondo_posts_config', jsonEncode(fondoPostsConfig)));
      if (fuenteComunidad != null) datosFormulario.fields.add(MapEntry('fuente_comunidad', fuenteComunidad));
      
      if (tags != null) {
        for (var tag in tags) {
          datosFormulario.fields.add(MapEntry('tags', tag));
        }
      }
 
      final archivos = {
        'url_portada': banner,
        'url_avatar': avatar,
        'url_fondo': fondo,
      };
 
      for (var entrada in archivos.entries) {
        final archivo = entrada.value;
        if (archivo != null) {
          final bytes = await archivo.readAsBytes();
          final mimeType = lookupMimeType(archivo.name, headerBytes: bytes) ?? 'application/octet-stream';
          final typeParts = mimeType.split('/');
          
          datosFormulario.files.add(MapEntry(
            entrada.key,
            dio.MultipartFile.fromBytes(
              bytes,
              filename: archivo.name,
              contentType: MediaType(typeParts[0], typeParts[1]),
            ),
          ));
        }
      }
 
      final respuesta = await clienteDio.patch(
        url,
        data: datosFormulario,
        options: dio.Options(headers: cabeceras),
      );
 
      if (respuesta.statusCode == 200) {
        final datosRespuesta = respuesta.data is String ? jsonDecode(respuesta.data) : respuesta.data;
        return RespuestaApi(
          exito: true,
          mensaje: '¡Comunidad actualizada!',
          datos: Comunidad.fromJson(datosRespuesta),
        );
      }
      return RespuestaApi(exito: false, mensaje: 'Error al actualizar comunidad (${respuesta.statusCode})');
    } catch (e) {
      String msg = 'Error de conexión: $e';
      if (e is dio.DioException) {
        msg = e.response?.data?['error']?.toString() ?? e.message ?? msg;
      }
      return RespuestaApi(exito: false, mensaje: msg);
    }
  }

  /// Cambia el rango administrativo de un miembro en la comunidad.
  Future<RespuestaApi<void>> gestionarRolMiembro(int idMiembro, String nuevoRol) async {
    try {
      final respuesta = await http.post(
        Uri.parse('${_urlComunidades}$idMiembro/gestionar-rol-miembro/'),
        headers: await _obtenerCabeceras(),
        body: jsonEncode({'rol': nuevoRol}),
      ).timeout(const Duration(seconds: 15));

      if (respuesta.statusCode == 200) {
        return RespuestaApi(exito: true, mensaje: 'Rol de miembro actualizado');
      }
      return RespuestaApi(exito: false, mensaje: 'Error al cambiar rol');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  /// Recupera el rango oficial de un usuario dentro de una comunidad.
  Future<RespuestaApi<String>> obtenerRolUsuarioEnComunidad(int idComunidad, int idUsuario) async {
    try {
      final respuesta = await http.get(
        Uri.parse('${_urlComunidades}$idComunidad/obtener-rol-usuario/?usuario_id=$idUsuario'),
        headers: await _obtenerCabeceras(),
      ).timeout(const Duration(seconds: 15));

      if (respuesta.statusCode == 200) {
        final datos = jsonDecode(utf8.decode(respuesta.bodyBytes));
        return RespuestaApi(exito: true, mensaje: 'Rol recuperado', datos: datos['rol']);
      }
      return RespuestaApi(exito: false, mensaje: 'No se pudo obtener el rol');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  // --- CONTENIDO Y MENSAJERÍA ---

  /// Obtiene publicaciones de comunidades públicas para el feed global.
  Future<RespuestaApi<List<Publicacion>>> obtenerPublicacionesGlobales({String orden = '-fecha_creacion'}) async {
    try {
      final respuesta = await http.get(
        Uri.parse('${_urlContenido}publicaciones/global/?ordering=$orden'),
        headers: await _obtenerCabeceras(),
      ).timeout(const Duration(seconds: 20));

      if (respuesta.statusCode == 200) {
        final dynamic datosJson = jsonDecode(respuesta.body);
        final List<dynamic> lista = datosJson is List ? datosJson : (datosJson['results'] ?? []);
        return RespuestaApi(
          exito: true,
          mensaje: 'Feed global cargado',
          datos: lista.map((p) => Publicacion.fromJson(p)).toList(),
        );
      }
      return RespuestaApi(exito: false, mensaje: 'Error al cargar feed');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  /// Actualiza una publicación existente.
  Future<RespuestaApi<Publicacion>> actualizarPublicacion({
    required int idPublicacion,
    String? titulo,
    String? texto,
    String? etiquetas,
  }) async {
    try {
      final token = await _servicioUsuarios.obtenerToken();
      final clienteDio = dio.Dio();
      
      final respuesta = await clienteDio.patch(
        '${_urlContenido}publicaciones/$idPublicacion/',
        options: dio.Options(headers: {
          if (token != null) 'Authorization': 'Token $token',
        }),
        data: {
          if (titulo != null) 'titulo': titulo,
          if (texto != null) 'contenido_texto': texto,
          if (etiquetas != null) 'etiquetas': etiquetas,
        },
      );

      if (respuesta.statusCode == 200) {
        return RespuestaApi(
          exito: true,
          mensaje: 'Publicación actualizada',
          datos: Publicacion.fromJson(respuesta.data is String ? jsonDecode(respuesta.data) : respuesta.data),
        );
      }
      return RespuestaApi(exito: false, mensaje: 'Error al actualizar (${respuesta.statusCode})');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  /// Recupera las publicaciones registradas en una comunidad específica.
  Future<RespuestaApi<List<Publicacion>>> obtenerPublicacionesComunidad(int idComunidad, {String orden = '-fecha_creacion', int pagina = 1, int tamanoPagina = 20}) async {
    try {
      final offset = (pagina - 1) * tamanoPagina;
      final respuesta = await http.get(
        Uri.parse('${_urlContenido}publicaciones/?comunidad_id=$idComunidad&ordering=$orden&limit=$tamanoPagina&offset=$offset'),
        headers: await _obtenerCabeceras(),
      ).timeout(const Duration(seconds: 20));

      if (respuesta.statusCode == 200) {
        final dynamic datosJson = jsonDecode(respuesta.body);
        final List<dynamic> lista = datosJson is List ? datosJson : (datosJson['results'] ?? []);
        return RespuestaApi(
          exito: true,
          mensaje: 'Publicaciones de comunidad cargadas',
          datos: lista.map((p) => Publicacion.fromJson(p)).toList(),
        );
      }
      return RespuestaApi(exito: false, mensaje: 'Error al cargar publicaciones');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  /// Recupera la galería de imágenes destacadas de la comunidad.
  Future<RespuestaApi<List<ImagenGaleria>>> obtenerGaleriaComunidad(int idComunidad) async {
    try {
      final respuesta = await http.get(
        Uri.parse('${_urlContenido}galeria/?comunidad_id=$idComunidad'),
        headers: await _obtenerCabeceras(),
      ).timeout(const Duration(seconds: 20));

      if (respuesta.statusCode == 200) {
        final List<dynamic> datos = jsonDecode(respuesta.body);
        return RespuestaApi(
          exito: true,
          mensaje: 'Galería de comunidad cargada',
          datos: datos.map((i) => ImagenGaleria.fromJson(i)).toList(),
        );
      }
      return RespuestaApi(exito: false, mensaje: 'Error al cargar galería');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  /// Obtiene las salas de chat activas vinculadas a la comunidad.
  Future<RespuestaApi<List<SalaChat>>> obtenerSalasChat(int idComunidad) async {
    try {
      final respuesta = await http.get(
        Uri.parse('${_urlMensajeria}salas/?comunidad_id=$idComunidad'),
        headers: await _obtenerCabeceras(),
      ).timeout(const Duration(seconds: 20));

      if (respuesta.statusCode == 200) {
        final List<dynamic> datos = jsonDecode(respuesta.body);
        return RespuestaApi(
          exito: true,
          mensaje: 'Salas de chat cargadas',
          datos: datos.map((s) => SalaChat.fromJson(s)).toList(),
        );
      }
      return RespuestaApi(exito: false, mensaje: 'Error al cargar salas de chat');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  /// Crea una nueva publicación permitiendo el envío de múltiples archivos multimedia.
  /// Ahora soporta seguimiento de progreso de subida.
  Future<RespuestaApi<Publicacion>> crearPublicacion({
    int? idComunidad,
    required String texto,
    List<XFile>? imagenes,
    String? etiquetas,
    void Function(int, int)? alProgresar,
  }) async {
    try {
      final token = await _servicioUsuarios.obtenerToken();
      final url = '${_urlContenido}publicaciones/crear/';
      
      final clienteDio = dio.Dio();
      final cabeceras = {
        if (token != null) 'Authorization': 'Token $token',
      };

      final datosFormulario = dio.FormData();
      
      if (idComunidad != null && idComunidad != 0) {
        datosFormulario.fields.add(MapEntry('comunidad', idComunidad.toString()));
      }
      datosFormulario.fields.add(MapEntry('contenido_texto', texto));
      if (etiquetas != null && etiquetas.trim().isNotEmpty) {
        datosFormulario.fields.add(MapEntry('etiquetas', etiquetas.trim()));
      }

      if (imagenes != null && imagenes.isNotEmpty) {
        for (var img in imagenes) {
          final bytes = await img.readAsBytes();
          final mimeType = lookupMimeType(img.name, headerBytes: bytes) ?? 'application/octet-stream';
          final typeParts = mimeType.split('/');
          
          datosFormulario.files.add(MapEntry(
            'url_archivo_s3[]',
            dio.MultipartFile.fromBytes(
              bytes,
              filename: img.name,
              contentType: MediaType(typeParts[0], typeParts[1]),
            ),
          ));
        }
      }

      final respuesta = await clienteDio.post(
        url,
        data: datosFormulario,
        options: dio.Options(headers: cabeceras),
        onSendProgress: alProgresar,
      );

      if (respuesta.statusCode == 201 || respuesta.statusCode == 200) {
        return RespuestaApi(
          exito: true,
          mensaje: '¡Publicación enviada!',
          datos: Publicacion.fromJson(respuesta.data is String ? jsonDecode(respuesta.data) : respuesta.data),
        );
      }

      return RespuestaApi(exito: false, mensaje: 'Error en la publicación (${respuesta.statusCode})');
    } catch (e) {
      String msg = 'Error de conexión: $e';
      if (e is dio.DioException) {
        msg = e.response?.data?['error']?.toString() ?? e.message ?? msg;
      }
      return RespuestaApi(exito: false, mensaje: msg);
    }
  }

  /// Elimina una comunidad y todo su contenido asociado permanentemente.
  Future<RespuestaApi> eliminarComunidad(int idComunidad) async {
    try {
      final respuesta = await http.delete(
        Uri.parse('$_urlComunidades$idComunidad/'),
        headers: await _obtenerCabeceras(),
      ).timeout(const Duration(seconds: 20));

      if (respuesta.statusCode == 204) {
        return RespuestaApi(exito: true, mensaje: 'Comunidad eliminada correctamente');
      }
      return RespuestaApi(exito: false, mensaje: 'No se pudo eliminar la comunidad');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  // --- MODERACIÓN DE CONTENIDO ---

  /// Recupera los detalles técnicos y de contenido de una publicación.
  Future<RespuestaApi<Publicacion>> obtenerDetallePublicacion(int idPublicacion) async {
    try {
      final respuesta = await http.get(
        Uri.parse('${_urlContenido}publicaciones/$idPublicacion/'),
        headers: await _obtenerCabeceras(),
      ).timeout(const Duration(seconds: 15));

      if (respuesta.statusCode == 200) {
        return RespuestaApi(
          exito: true,
          mensaje: 'Publicación cargada',
          datos: Publicacion.fromJson(jsonDecode(respuesta.body)),
        );
      }
      return RespuestaApi(exito: false, mensaje: 'Publicación no encontrada');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  /// Retira una publicación del sistema por motivos de moderación.
  Future<RespuestaApi> eliminarPublicacionModeracion(int idPublicacion, {String? razon}) async {
    try {
      final respuesta = await http.delete(
        Uri.parse('${_urlContenido}publicaciones/$idPublicacion/'),
        headers: await _obtenerCabeceras(),
        body: razon != null ? jsonEncode({'razon': razon}) : null,
      ).timeout(const Duration(seconds: 20));

      if (respuesta.statusCode == 204 || respuesta.statusCode == 200) {
        return RespuestaApi(exito: true, mensaje: 'Publicación retirada');
      }
      return RespuestaApi(exito: false, mensaje: 'Error al retirar publicación');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  /// Retira un comentario individual del sistema por motivos de moderación.
  Future<RespuestaApi> eliminarComentarioModeracion(int idComentario, {String? razon}) async {
    try {
      final respuesta = await http.delete(
        Uri.parse('${_urlContenido}comentarios/$idComentario/'),
        headers: await _obtenerCabeceras(),
        body: razon != null ? jsonEncode({'razon': razon}) : null,
      ).timeout(const Duration(seconds: 20));

      if (respuesta.statusCode == 204 || respuesta.statusCode == 200) {
        return RespuestaApi(exito: true, mensaje: 'Comentario retirado');
      }
      return RespuestaApi(exito: false, mensaje: 'Error al retirar comentario');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  /// Alterna el estado de guardado (bookmark) de una publicación en el perfil del usuario.
  Future<RespuestaApi> alternarGuardadoPost(int idPublicacion) async {
    try {
      final respuesta = await http.post(
        Uri.parse('${_urlContenido}publicaciones/$idPublicacion/guardar/'),
        headers: await _obtenerCabeceras(),
      ).timeout(const Duration(seconds: 20));

      if (respuesta.statusCode == 200 || respuesta.statusCode == 201) {
        final datos = jsonDecode(respuesta.body);
        return RespuestaApi(
          exito: true,
          mensaje: datos['mensaje'] ?? 'Operación exitosa',
          datos: datos['resultado'],
        );
      }
      return RespuestaApi(exito: false, mensaje: 'Error al procesar guardado');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  /// Busca o sugiere tags existentes para comunidades.
  Future<RespuestaApi<List<Map<String, dynamic>>>> buscarTags({String? query, bool popular = false}) async {
    try {
      String params = '';
      if (query != null && query.isNotEmpty) params += 'search=$query';
      if (popular) params += (params.isEmpty ? '' : '&') + 'popular=true';
      
      final url = '${_urlComunidades}tags/${params.isNotEmpty ? '?$params' : ''}';
      final respuesta = await http.get(
        Uri.parse(url),
        headers: await _obtenerCabeceras(),
      ).timeout(const Duration(seconds: 15));

      if (respuesta.statusCode == 200) {
        final List<dynamic> datos = jsonDecode(utf8.decode(respuesta.bodyBytes));
        return RespuestaApi(
          exito: true,
          mensaje: 'Tags recuperados',
          datos: List<Map<String, dynamic>>.from(datos),
        );
      }
      return RespuestaApi(exito: false, mensaje: 'Error al buscar tags');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }
}
