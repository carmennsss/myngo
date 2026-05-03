import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import '../models/coleccion.dart';
import '../models/imagen_galeria.dart';
import '../models/respuesta_api.dart';
import '../utils/configuracion.dart';
import 'servicio_usuarios.dart';

/// Servicio encargado de gestionar los recursos multimedia y las colecciones de imágenes.
///
/// Permite la subida de archivos a la galería (personal o comunitaria), la organización
/// en colecciones temáticas y la gestión de permisos de visibilidad.
class ServicioGaleria {
  /// URL base para los endpoints de contenido multimedia.
  static const String _urlContenido = '${Configuracion.baseUrl}/contenido';
  
  final _servicioUsuarios = ServicioUsuarios();

  /// Genera las cabeceras estándar (JSON + Token) para las peticiones API.
  Future<Map<String, String>> _obtenerCabeceras() async {
    final token = await _servicioUsuarios.obtenerToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Token $token',
    };
  }

  /// Obtiene una lista paginada de imágenes filtradas por comunidad, usuario o colección.
  Future<RespuestaApi<List<ImagenGaleria>>> obtenerGaleria({
    int? idComunidad,
    int? idUsuario,
    int? idColeccion,
    int limite = 20,
    int desplazamiento = 0,
  }) async {
    try {
      final queryParams = [
        'limit=$limite',
        'offset=$desplazamiento',
        if (idComunidad != null) 'comunidad_id=$idComunidad',
        if (idUsuario != null) 'usuario_id=$idUsuario',
        if (idColeccion != null) 'coleccion_id=$idColeccion',
      ].join('&');

      final url = '$_urlContenido/galeria/?$queryParams';
      final respuesta = await http.get(
        Uri.parse(url),
        headers: await _obtenerCabeceras(),
      ).timeout(const Duration(seconds: 15));

      if (respuesta.statusCode == 200) {
        final Map<String, dynamic> cuerpo = jsonDecode(respuesta.body);
        final List<dynamic> resultados = cuerpo['results'] ?? [];
        return RespuestaApi(
          exito: true,
          mensaje: 'Galería cargada correctamente',
          datos: resultados.map((j) => ImagenGaleria.fromJson(j)).toList(),
        );
      }
      return RespuestaApi(exito: false, mensaje: 'Error al cargar galería (${respuesta.statusCode})');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  /// Recupera las colecciones disponibles para un usuario o una comunidad.
  Future<RespuestaApi<List<Coleccion>>> obtenerColecciones({
    int? idComunidad,
    int? idUsuario,
  }) async {
    try {
      final query = idComunidad != null ? '?comunidad_id=$idComunidad' : (idUsuario != null ? '?usuario_id=$idUsuario' : '');
      final url = '$_urlContenido/colecciones/$query';

      final respuesta = await http.get(
        Uri.parse(url),
        headers: await _obtenerCabeceras(),
      ).timeout(const Duration(seconds: 15));

      if (respuesta.statusCode == 401) {
        return RespuestaApi(
          exito: true,
          datos: [],
          mensaje: 'Inicia sesión para ver colecciones privadas 🐾',
        );
      }

      if (respuesta.statusCode == 200) {
        final dynamic datosJson = jsonDecode(respuesta.body);
        final List<dynamic> listaJson = datosJson is List ? datosJson : (datosJson['results'] ?? []);
        return RespuestaApi(
          exito: true,
          mensaje: 'Colecciones recuperadas',
          datos: listaJson.map((j) => Coleccion.fromJson(j)).toList(),
        );
      }
      return RespuestaApi(exito: false, mensaje: 'Error al cargar colecciones');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  /// Actualiza los metadatos de una colección (ej. cambiar privacidad o nombre).
  Future<RespuestaApi<Coleccion>> editarColeccion(int idColeccion, Map<String, dynamic> datos) async {
    try {
      final respuesta = await http.patch(
        Uri.parse('$_urlContenido/colecciones/$idColeccion/'),
        headers: await _obtenerCabeceras(),
        body: jsonEncode(datos),
      ).timeout(const Duration(seconds: 15));

      if (respuesta.statusCode == 200) {
        return RespuestaApi(
          exito: true,
          mensaje: 'Colección actualizada',
          datos: Coleccion.fromJson(jsonDecode(respuesta.body)),
        );
      }
      return RespuestaApi(exito: false, mensaje: 'Error al actualizar colección');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  /// Crea una nueva colección multimedia personalizada.
  Future<RespuestaApi<Coleccion>> crearColeccion({
    required String nombre,
    String? descripcion,
    bool esPrivada = false,
    int? idComunidad,
  }) async {
    try {
      final respuesta = await http.post(
        Uri.parse('$_urlContenido/colecciones/'),
        headers: await _obtenerCabeceras(),
        body: jsonEncode({
          'nombre': nombre,
          'descripcion': descripcion,
          'es_privada': esPrivada,
          if (idComunidad != null) 'comunidad': idComunidad,
        }),
      ).timeout(const Duration(seconds: 15));

      if (respuesta.statusCode == 201) {
        return RespuestaApi(
          exito: true,
          mensaje: 'Colección creada con éxito',
          datos: Coleccion.fromJson(jsonDecode(respuesta.body)),
        );
      }
      return RespuestaApi(exito: false, mensaje: 'No se pudo crear la colección');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  /// Vincula o desvincula una imagen de una colección específica.
  Future<RespuestaApi<void>> gestionarImagenEnColeccion({
    required int idColeccion,
    required int idImagen,
    required bool agregar,
  }) async {
    try {
      final respuesta = await http.post(
        Uri.parse('$_urlContenido/colecciones/$idColeccion/gestionar_imagen/'),
        headers: await _obtenerCabeceras(),
        body: jsonEncode({
          'imagen_id': idImagen,
          'accion': agregar ? 'agregar' : 'quitar',
        }),
      ).timeout(const Duration(seconds: 15));

      if (respuesta.statusCode == 200) {
        return RespuestaApi(exito: true, mensaje: 'Operación realizada correctamente');
      }
      return RespuestaApi(exito: false, mensaje: 'Error al gestionar la imagen en la colección');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  /// Elimina una colección multimedia permanentemente.
  Future<RespuestaApi<void>> eliminarColeccion({required int idColeccion}) async {
    try {
      final respuesta = await http.delete(
        Uri.parse('$_urlContenido/colecciones/$idColeccion/'),
        headers: await _obtenerCabeceras(),
      ).timeout(const Duration(seconds: 15));

      if (respuesta.statusCode == 204) {
        return RespuestaApi(exito: true, mensaje: 'Colección eliminada con éxito');
      }
      return RespuestaApi(exito: false, mensaje: 'Error al eliminar la colección');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  /// Sube un nuevo archivo de imagen a la galería global o comunitaria.
  Future<RespuestaApi<ImagenGaleria>> subirImagenGaleria(
    XFile imagenArchivo, {
    int? idComunidad,
    bool esPublica = true,
  }) async {
    try {
      final token = await _servicioUsuarios.obtenerToken();
      final solicitud = http.MultipartRequest('POST', Uri.parse('$_urlContenido/galeria/'));
      
      if (token != null) solicitud.headers['Authorization'] = 'Token $token';
      if (idComunidad != null) solicitud.fields['comunidad'] = idComunidad.toString();
      solicitud.fields['es_publica'] = esPublica ? 'true' : 'false';

      final bytes = await imagenArchivo.readAsBytes();
      final mimeType = lookupMimeType(imagenArchivo.name, headerBytes: bytes) ?? 'application/octet-stream';
      final typeParts = mimeType.split('/');
      
      solicitud.files.add(http.MultipartFile.fromBytes(
        'url_s3',
        bytes,
        filename: imagenArchivo.name,
        contentType: MediaType(typeParts[0], typeParts[1]),
      ));

      final respuestaStream = await solicitud.send().timeout(const Duration(seconds: 40));
      final respuesta = await http.Response.fromStream(respuestaStream);

      if (respuesta.statusCode == 201) {
        return RespuestaApi(
          exito: true,
          mensaje: 'Imagen subida correctamente',
          datos: ImagenGaleria.fromJson(jsonDecode(respuesta.body)),
        );
      }
      final datosError = jsonDecode(respuesta.body);
      return RespuestaApi(exito: false, mensaje: datosError['mensaje'] ?? 'Error al subir la imagen');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  /// Obtiene información extendida de una imagen, incluyendo posts donde aparece.
  Future<RespuestaApi<Map<String, dynamic>>> obtenerDetalleImagenExtendido(int idImagen) async {
    try {
      final respuesta = await http.get(
        Uri.parse('$_urlContenido/galeria/$idImagen/detalle_extendido/'),
        headers: await _obtenerCabeceras(),
      ).timeout(const Duration(seconds: 15));

      if (respuesta.statusCode == 200) {
        return RespuestaApi(
          exito: true,
          mensaje: 'Detalles recuperados',
          datos: jsonDecode(respuesta.body) as Map<String, dynamic>,
        );
      }
      return RespuestaApi(exito: false, mensaje: 'Error al obtener detalles de la imagen');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  /// Elimina una publicación específica.
  Future<RespuestaApi> eliminarPublicacion(int idPublicacion, {String? razon}) async {
    try {
      final respuesta = await http.delete(
        Uri.parse('$_urlContenido/publicaciones/$idPublicacion/'),
        headers: await _obtenerCabeceras(),
        body: razon != null ? jsonEncode({'razon': razon}) : null,
      ).timeout(const Duration(seconds: 15));

      if (respuesta.statusCode == 200 || respuesta.statusCode == 204) {
        return RespuestaApi(exito: true, mensaje: 'Publicación eliminada correctamente');
      }
      return RespuestaApi(exito: false, mensaje: 'Error al eliminar la publicación');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  /// Actualiza los metadatos o contenido de una publicación.
  Future<RespuestaApi> editarPublicacion(int idPublicacion, Map<String, dynamic> datos) async {
    try {
      final respuesta = await http.patch(
        Uri.parse('$_urlContenido/publicaciones/$idPublicacion/'),
        headers: await _obtenerCabeceras(),
        body: jsonEncode(datos),
      ).timeout(const Duration(seconds: 15));

      if (respuesta.statusCode == 200) {
        return RespuestaApi(exito: true, mensaje: 'Publicación actualizada correctamente');
      }
      return RespuestaApi(exito: false, mensaje: 'Error al editar la publicación');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  /// Elimina una imagen de la galería de forma permanente.
  Future<RespuestaApi> eliminarImagen(int idImagen, {String? razon}) async {
    try {
      final respuesta = await http.delete(
        Uri.parse('$_urlContenido/galeria/$idImagen/'),
        headers: await _obtenerCabeceras(),
        body: razon != null ? jsonEncode({'razon': razon}) : null,
      ).timeout(const Duration(seconds: 15));

      if (respuesta.statusCode == 200 || respuesta.statusCode == 204) {
        return RespuestaApi(exito: true, mensaje: 'Imagen eliminada de la galería');
      }
      return RespuestaApi(exito: false, mensaje: 'Error al eliminar la imagen');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }
}
