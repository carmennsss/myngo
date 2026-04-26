import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mime/mime.dart';
import '../models/respuesta_api.dart';
import '../models/imagen_galeria.dart';
import '../models/coleccion.dart';
import '../models/publicacion.dart';
import 'servicio_usuarios.dart';
import '../utils/configuracion.dart';

class ServicioGaleria {
  static const String _urlBase = '${Configuracion.baseUrl}/contenido';
  final _servicioUsuarios = ServicioUsuarios();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _servicioUsuarios.obtenerToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Token $token',
    };
  }

  /// Obtiene la galería con soporte para scroll infinito (paginación) y coleccion_id
  Future<RespuestaApi<List<ImagenGaleria>>> obtenerGaleria({
    int? comunidadId,
    int? usuarioId,
    int? coleccionId,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      String url = '$_urlBase/galeria/?limit=$limit&offset=$offset';
      if (comunidadId != null) url += '&comunidad_id=$comunidadId';
      if (usuarioId != null) url += '&usuario_id=$usuarioId';
      if (coleccionId != null) url += '&coleccion_id=$coleccionId';

      final respuesta = await http.get(Uri.parse(url), headers: await _getHeaders()).timeout(const Duration(seconds: 10));

      if (respuesta.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(respuesta.body);
        final List<dynamic> results = body['results'] ?? [];
        return RespuestaApi(
          exito: true,
          mensaje: 'Galería cargada',
          datos: results.map((j) => ImagenGaleria.fromJson(j)).toList(),
        );
      }
      return RespuestaApi(exito: false, mensaje: 'Error al cargar galería: ${respuesta.statusCode}');
    } on Exception catch (e) {
      if (e.toString().contains('TimeoutException')) {
        return RespuestaApi(exito: false, mensaje: 'Tiempo de espera agotado. Por favor, revisa tu conexión.');
      }
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  /// Obtiene las colecciones de un usuario o comunidad
  Future<RespuestaApi<List<Coleccion>>> obtenerColecciones({
    int? comunidadId,
    int? usuarioId,
  }) async {
    try {
      String url = '$_urlBase/colecciones/';
      if (comunidadId != null) url += '?comunidad_id=$comunidadId';
      else if (usuarioId != null) url += '?usuario_id=$usuarioId';

      final respuesta = await http.get(Uri.parse(url), headers: await _getHeaders()).timeout(const Duration(seconds: 10));

      if (respuesta.statusCode == 401) {
        return RespuestaApi(exito: true, datos: [], mensaje: 'Inicia sesión para ver colecciones privadas 🐾');
      }

      if (respuesta.statusCode == 200) {
        final dynamic jsonRes = jsonDecode(respuesta.body);
        final List<dynamic> lista = jsonRes is List ? jsonRes : (jsonRes['results'] ?? []);
        return RespuestaApi(
          exito: true,
          mensaje: 'Colecciones cargadas',
          datos: lista.map((j) => Coleccion.fromJson(j)).toList(),
        );
      }
      return RespuestaApi(exito: false, mensaje: 'Error al cargar colecciones');
    } on Exception catch (e) {
      if (e.toString().contains('TimeoutException')) {
        return RespuestaApi(exito: false, mensaje: 'Tiempo de espera agotado. Por favor, revisa tu conexión.');
      }
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  /// Crea una nueva colección
  Future<RespuestaApi<Coleccion>> crearColeccion({
    required String nombre,
    String? descripcion,
    bool esPrivada = false,
    int? comunidadId,
  }) async {
    try {
      final respuesta = await http.post(
        Uri.parse('$_urlBase/colecciones/'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'nombre': nombre,
          'descripcion': descripcion,
          'es_privada': esPrivada,
          if (comunidadId != null) 'comunidad': comunidadId,
        }),
      ).timeout(const Duration(seconds: 15));

      if (respuesta.statusCode == 201) {
        return RespuestaApi(
          exito: true,
          mensaje: 'Colección creada',
          datos: Coleccion.fromJson(jsonDecode(respuesta.body)),
        );
      }
      return RespuestaApi(exito: false, mensaje: 'Error al crear colección');
    } on Exception catch (e) {
      if (e.toString().contains('TimeoutException')) {
        return RespuestaApi(exito: false, mensaje: 'Tiempo de espera agotado. Por favor, revisa tu conexión.');
      }
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  /// Añade o elimina una imagen de una colección
  Future<RespuestaApi<void>> gestionarImagenEnColeccion({
    required int coleccionId,
    required int imagenId,
    required bool agregar,
  }) async {
    try {
      final respuesta = await http.post(
        Uri.parse('$_urlBase/colecciones/$coleccionId/gestionar_imagen/'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'imagen_id': imagenId,
          'accion': agregar ? 'agregar' : 'quitar',
        }),
      ).timeout(const Duration(seconds: 15));

      if (respuesta.statusCode == 200) {
        return RespuestaApi(exito: true, mensaje: 'Operación realizada con éxito');
      }
      return RespuestaApi(exito: false, mensaje: 'Error al gestionar imagen en colección');
    } on Exception catch (e) {
      if (e.toString().contains('TimeoutException')) {
        return RespuestaApi(exito: false, mensaje: 'Tiempo de espera agotado. Por favor, revisa tu conexión.');
      }
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  /// Elimina una colección completa (solo el propietario puede hacerlo)
  Future<RespuestaApi<void>> eliminarColeccion({required int coleccionId}) async {
    try {
      final respuesta = await http.delete(
        Uri.parse('$_urlBase/colecciones/$coleccionId/'),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 15));
      if (respuesta.statusCode == 204) {
        return RespuestaApi(exito: true, mensaje: 'Colección eliminada');
      }
      return RespuestaApi(exito: false, mensaje: 'Error al eliminar la colección (${respuesta.statusCode})');
    } on Exception catch (e) {
      if (e.toString().contains('TimeoutException')) {
        return RespuestaApi(exito: false, mensaje: 'Tiempo de espera agotado. Por favor, revisa tu conexión.');
      }
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  /// Sube una imagen cruda directamente a la galería de Myngo
  Future<RespuestaApi<ImagenGaleria>> subirImagenGaleria(
    XFile imagenPMA, {
    int? comunidadId,
    bool esPublica = true,
  }) async {
    try {
      final token = await _servicioUsuarios.obtenerToken();
      
      var request = http.MultipartRequest('POST', Uri.parse('$_urlBase/galeria/'));
      if (token != null) request.headers['Authorization'] = 'Token $token';
      
      if (comunidadId != null) {
        request.fields['comunidad'] = comunidadId.toString();
      }
      request.fields['es_publica'] = esPublica ? 'true' : 'false';
      
      final mimeTypeData = lookupMimeType(imagenPMA.path)?.split('/');
      final bytes = await imagenPMA.readAsBytes();
      final file = http.MultipartFile.fromBytes(
        'url_s3',
        bytes,
        filename: imagenPMA.name,
        contentType: mimeTypeData != null ? MediaType(mimeTypeData[0], mimeTypeData[1]) : null,
      );
      request.files.add(file);

      final streamedRespuesta = await request.send().timeout(const Duration(seconds: 25));
      final respuesta = await http.Response.fromStream(streamedRespuesta);

      if (respuesta.statusCode == 201) {
        return RespuestaApi(
          exito: true,
          mensaje: 'Imagen subida con éxito',
          datos: ImagenGaleria.fromJson(jsonDecode(respuesta.body)),
        );
      }
      final errorBody = jsonDecode(respuesta.body);
      return RespuestaApi(exito: false, mensaje: errorBody['mensaje'] ?? 'Error al subir la imagen a la galería');
    } on Exception catch (e) {
      if (e.toString().contains('TimeoutException')) {
        return RespuestaApi(exito: false, mensaje: 'Tiempo de espera agotado. Por favor, revisa tu conexión.');
      }
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  /// Obtiene los metadatos integrados extendidos para la vista minuciosa de una imagen (Posts, Colecciones)
  Future<RespuestaApi<Map<String, dynamic>>> obtenerDetalleImagenExtendido(int imagenId) async {
    try {
      final respuesta = await http.get(
        Uri.parse('$_urlBase/galeria/$imagenId/detalle_extendido/'),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 15));

      if (respuesta.statusCode == 200) {
        return RespuestaApi(
          exito: true,
          mensaje: 'Detalles cargados',
          datos: jsonDecode(respuesta.body) as Map<String, dynamic>,
        );
      }
      return RespuestaApi(exito: false, mensaje: 'No se pudieron recuperar los detalles');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error conectando con el servidor');
    }
  }

  Future<RespuestaApi> eliminarPublicacion(int id, {String? razon}) async {
    try {
      final token = await _servicioUsuarios.obtenerToken();
      final response = await http.delete(
        Uri.parse('$_urlBase/publicaciones/$id/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
        body: jsonEncode({'razon': razon}),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) return RespuestaApi(exito: true, mensaje: 'Publicación eliminada');
      return RespuestaApi(exito: false, mensaje: 'Error al eliminar la publicación');
    } on Exception catch (e) {
      if (e.toString().contains('TimeoutException')) {
        return RespuestaApi(exito: false, mensaje: 'Tiempo de espera agotado. Por favor, revisa tu conexión.');
      }
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  Future<RespuestaApi> editarPublicacion(int id, Map<String, dynamic> datos) async {
    try {
      final token = await _servicioUsuarios.obtenerToken();
      final response = await http.patch(
        Uri.parse('$_urlBase/publicaciones/$id/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
        body: jsonEncode(datos),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) return RespuestaApi(exito: true, mensaje: 'Publicación actualizada');
      return RespuestaApi(exito: false, mensaje: 'Error al actualizar la publicación');
    } on Exception catch (e) {
      if (e.toString().contains('TimeoutException')) {
        return RespuestaApi(exito: false, mensaje: 'Tiempo de espera agotado. Por favor, revisa tu conexión.');
      }
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  Future<RespuestaApi> eliminarImagen(int id, {String? razon}) async {
    try {
      final token = await _servicioUsuarios.obtenerToken();
      final response = await http.delete(
        Uri.parse('$_urlBase/galeria/$id/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
        body: jsonEncode({'razon': razon}),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) return RespuestaApi(exito: true, mensaje: 'Imagen eliminada de la galería');
      return RespuestaApi(exito: false, mensaje: 'Error al eliminar la imagen');
    } on Exception catch (e) {
      if (e.toString().contains('TimeoutException')) {
        return RespuestaApi(exito: false, mensaje: 'Tiempo de espera agotado. Por favor, revisa tu conexión.');
      }
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }
}
