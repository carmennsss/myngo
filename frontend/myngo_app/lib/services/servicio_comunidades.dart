import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/respuesta_api.dart';
import '../models/comunidad.dart';
import '../models/publicacion.dart';
import '../models/imagen_galeria.dart';
import '../models/sala_chat.dart';
import 'servicio_usuarios.dart';

/// Servicio para gestionar las operaciones relacionadas con las comunidades.
class ServicioComunidades {
  static const String _urlBase = 'http://127.0.0.1:8000/comunidades/';
  static const String _urlContenido = 'http://127.0.0.1:8000/contenido/';
  static const String _urlMensajeria = 'http://127.0.0.1:8000/mensajeria/';
  
  final _servicioUsuarios = ServicioUsuarios();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _servicioUsuarios.obtenerToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Token $token',
    };
  }

  /// Obtiene la lista de comunidades filtradas opcionalmente por un término de búsqueda.
  Future<RespuestaApi<List<Comunidad>>> listarComunidades({String? busqueda}) async {
    try {
      String url = _urlBase;
      if (busqueda != null && busqueda.isNotEmpty) {
        url += '?search=$busqueda';
      }

      final respuesta = await http.get(
        Uri.parse(url),
        headers: await _getHeaders(),
      );
      
      if (respuesta.statusCode == 200) {
        final dynamic datosJson = jsonDecode(utf8.decode(respuesta.bodyBytes));
        final List<dynamic> listaJson = datosJson is List ? datosJson : (datosJson['results'] ?? []);
        final comunidades = listaJson.map((item) => Comunidad.fromJson(item)).toList();
        
        return RespuestaApi(exito: true, mensaje: 'Comunidades obtenidas', datos: comunidades);
      }
      return RespuestaApi(exito: false, mensaje: 'Error: ${respuesta.statusCode}');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  /// Obtiene comunidades populares para sugerencias.
  Future<RespuestaApi<List<Comunidad>>> listarComunidadesPopulares() async {
    // Por ahora usamos la lista general, pero podríamos filtrar por las más activas en el futuro.
    return listarComunidades();
  }

  /// Obtiene las comunidades donde el usuario es creador o miembro.
  Future<RespuestaApi<List<Comunidad>>> listarComunidadesPropias() async {
    try {
      final respuesta = await http.get(
        Uri.parse('${_urlBase}propias/'),
        headers: await _getHeaders(),
      );

      if (respuesta.statusCode == 200) {
        final dynamic datosJson = jsonDecode(respuesta.body);
        final List<dynamic> listaJson = datosJson is List ? datosJson : (datosJson['results'] ?? []);
        final comunidades = listaJson.map((item) => Comunidad.fromJson(item)).toList();
        return RespuestaApi(exito: true, mensaje: 'Mis comunidades obtenidas', datos: comunidades);
      }
      return RespuestaApi(exito: false, mensaje: 'Error: ${respuesta.statusCode}');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  /// Obtiene los detalles de una comunidad específica por su ID.
  Future<RespuestaApi<Comunidad>> obtenerComunidad(int id) async {
    try {
      final respuesta = await http.get(
        Uri.parse('$_urlBase$id/'),
        headers: await _getHeaders(),
      );
      
      if (respuesta.statusCode == 200) {
        final dynamic datosJson = jsonDecode(utf8.decode(respuesta.bodyBytes));
        return RespuestaApi(
          exito: true, 
          mensaje: 'Comunidad obtenida', 
          datos: Comunidad.fromJson(datosJson)
        );
      }
      return RespuestaApi(exito: false, mensaje: 'Error: ${respuesta.statusCode}');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  /// Permite unirse a una comunidad o enviar solicitud.
  Future<RespuestaApi<Map<String, dynamic>>> unirseAComunidad(int id) async {
    try {
      final respuesta = await http.post(Uri.parse('${_urlBase}$id/unirse/'), headers: await _getHeaders());
      if (respuesta.statusCode == 201 || respuesta.statusCode == 200) {
        final Map<String, dynamic> datosJson = jsonDecode(respuesta.body);
        return RespuestaApi(exito: true, mensaje: datosJson['mensaje'] ?? 'Operación exitosa', datos: datosJson);
      }
      return RespuestaApi(exito: false, mensaje: 'Error: ${respuesta.statusCode}');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  /// Crea una nueva comunidad en el servidor soportando subida de imagen.
  Future<RespuestaApi<Comunidad>> crearComunidad(Comunidad comunidad, {XFile? imagen}) async {
    try {
      final token = await _servicioUsuarios.obtenerToken();
      var solicitud = http.MultipartRequest('POST', Uri.parse(_urlBase));
      if (token != null) solicitud.headers['Authorization'] = 'Token $token';

      solicitud.fields['nombre'] = comunidad.nombre;
      solicitud.fields['descripcion'] = comunidad.descripcion;
      solicitud.fields['es_publica'] = comunidad.esPublica.toString();
      solicitud.fields['min_rating_acceso'] = comunidad.minRatingAcceso.toString();

      if (imagen != null) {
        if (kIsWeb) {
          final bytes = await imagen.readAsBytes();
          final ext = imagen.name.split('.').last.toLowerCase();
          final subtype = {'jpg': 'jpeg', 'jpeg': 'jpeg', 'png': 'png', 'webp': 'webp', 'gif': 'gif'}[ext] ?? 'jpeg';
          solicitud.files.add(http.MultipartFile.fromBytes('url_portada', bytes, filename: imagen.name, contentType: MediaType('image', subtype)));
        } else {
          solicitud.files.add(await http.MultipartFile.fromPath('url_portada', imagen.path));
        }
      }

      final respuestaStream = await solicitud.send();
      final respuesta = await http.Response.fromStream(respuestaStream);

      if (respuesta.statusCode == 201) {
        final Map<String, dynamic> datosJson = jsonDecode(respuesta.body);
        return RespuestaApi(exito: true, mensaje: 'Comunidad creada con éxito', datos: Comunidad.fromJson(datosJson));
      }
      return RespuestaApi(exito: false, mensaje: 'Error: ${respuesta.statusCode}');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  /// Responde a una petición de unión (Aceptar/Rechazar).
  Future<RespuestaApi<void>> responderPeticion(int idPeticion, bool aceptar) async {
    try {
      final respuesta = await http.post(
        Uri.parse('${_urlBase}responder-peticion/$idPeticion/'),
        headers: await _getHeaders(),
        body: jsonEncode({'aceptar': aceptar}),
      );
      if (respuesta.statusCode == 200) return RespuestaApi(exito: true, mensaje: 'Respuesta enviada');
      return RespuestaApi(exito: false, mensaje: 'Error: ${respuesta.statusCode}');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  /// Obtiene los datos del panel de administración (solicitudes y reportes).
  Future<RespuestaApi<Map<String, dynamic>>> obtenerAdminDashboard(int id) async {
    try {
      final respuesta = await http.get(
        Uri.parse('${_urlBase}$id/admin-dashboard/'),
        headers: await _getHeaders(),
      );
      if (respuesta.statusCode == 200) {
        return RespuestaApi(exito: true, mensaje: 'Dashboard obtenido', datos: jsonDecode(utf8.decode(respuesta.bodyBytes)));
      }
      return RespuestaApi(exito: false, mensaje: 'Error: ${respuesta.statusCode}');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  /// Actualiza los ajustes de una comunidad (Nombre, Descripción, Color, Banner).
  Future<RespuestaApi<Comunidad>> actualizarComunidad(int id, {
    String? nombre, 
    String? descripcion, 
    String? colorTema,
    bool? tiendaHabilitada,
    XFile? banner
  }) async {
    try {
      final token = await _servicioUsuarios.obtenerToken();
      var solicitud = http.MultipartRequest('PATCH', Uri.parse('${_urlBase}$id/'));
      if (token != null) solicitud.headers['Authorization'] = 'Token $token';

      if (nombre != null) solicitud.fields['nombre'] = nombre;
      if (descripcion != null) solicitud.fields['descripcion'] = descripcion;
      if (colorTema != null) solicitud.fields['color_tema'] = colorTema;
      if (tiendaHabilitada != null) solicitud.fields['tienda_habilitada'] = tiendaHabilitada.toString();

      if (banner != null) {
        if (kIsWeb) {
          final bytes = await banner.readAsBytes();
          final ext = banner.name.split('.').last.toLowerCase();
          final subtype = {'jpg': 'jpeg', 'jpeg': 'jpeg', 'png': 'png', 'webp': 'webp'}[ext] ?? 'jpeg';
          solicitud.files.add(http.MultipartFile.fromBytes('url_portada', bytes, filename: banner.name, contentType: MediaType('image', subtype)));
        } else {
          solicitud.files.add(await http.MultipartFile.fromPath('url_portada', banner.path));
        }
      }

      final respuestaStream = await solicitud.send();
      final respuesta = await http.Response.fromStream(respuestaStream);

      if (respuesta.statusCode == 200) {
        final Map<String, dynamic> datosJson = jsonDecode(utf8.decode(respuesta.bodyBytes));
        return RespuestaApi(exito: true, mensaje: 'Ajustes guardados ✨', datos: Comunidad.fromJson(datosJson));
      }
      return RespuestaApi(exito: false, mensaje: 'Error: ${respuesta.statusCode}');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  /// Cambia el rol de un miembro de la comunidad.
  Future<RespuestaApi<void>> gestionarRolMiembro(int miembroId, String nuevoRol) async {
    try {
      final respuesta = await http.post(
        Uri.parse('${_urlBase}$miembroId/gestionar-rol-miembro/'),
        headers: await _getHeaders(),
        body: jsonEncode({'rol': nuevoRol}),
      );
      if (respuesta.statusCode == 200) return RespuestaApi(exito: true, mensaje: 'Rol actualizado');
      return RespuestaApi(exito: false, mensaje: 'Error al actualizar el rol');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  /// Obtiene el rol de un usuario en una comunidad específica.
  Future<RespuestaApi<String>> obtenerRolUsuarioEnComunidad(int comunidadId, int usuarioId) async {
    try {
      final respuesta = await http.get(
        Uri.parse('${_urlBase}$comunidadId/obtener-rol-usuario/?usuario_id=$usuarioId'),
        headers: await _getHeaders(),
      );
      if (respuesta.statusCode == 200) {
        final datos = jsonDecode(utf8.decode(respuesta.bodyBytes));
        return RespuestaApi(exito: true, mensaje: 'Rol obtenido', datos: datos['rol']);
      }
      return RespuestaApi(exito: false, mensaje: 'Error: ${respuesta.statusCode}');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  // --- MÉTODOS DE CONTENIDO Y MENSAJERÍA ---

  Future<RespuestaApi<List<Publicacion>>> obtenerPublicacionesGlobales({String ordering = '-fecha_creacion'}) async {
    try {
      final respuesta = await http.get(
        Uri.parse('${_urlContenido}publicaciones/?ordering=$ordering'),
        headers: await _getHeaders(),
      );
      if (respuesta.statusCode == 200) {
        final dynamic datosJson = jsonDecode(respuesta.body);
        final List<dynamic> lista = datosJson is List ? datosJson : (datosJson['results'] ?? []);
        return RespuestaApi(exito: true, datos: lista.map((p) => Publicacion.fromJson(p)).toList(), mensaje: 'Feed global cargado');
      }
      return RespuestaApi(exito: false, mensaje: 'Error: ${respuesta.statusCode}');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  Future<RespuestaApi<List<Publicacion>>> obtenerPublicaciones(int comunidadId, {String ordering = '-fecha_creacion'}) async {
    try {
      final respuesta = await http.get(
        Uri.parse('${_urlContenido}publicaciones/?comunidad_id=$comunidadId&ordering=$ordering'),
        headers: await _getHeaders(),
      );
      if (respuesta.statusCode == 200) {
        final dynamic datosJson = jsonDecode(respuesta.body);
        final List<dynamic> lista = datosJson is List ? datosJson : (datosJson['results'] ?? []);
        return RespuestaApi(exito: true, datos: lista.map((p) => Publicacion.fromJson(p)).toList(), mensaje: 'Publicaciones cargadas');
      }
      return RespuestaApi(exito: false, mensaje: 'Error: ${respuesta.statusCode}');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  Future<RespuestaApi<List<ImagenGaleria>>> obtenerGaleria(int comunidadId) async {
    try {
      final respuesta = await http.get(
        Uri.parse('${_urlContenido}galeria/?comunidad_id=$comunidadId'),
        headers: await _getHeaders(),
      );
      if (respuesta.statusCode == 200) {
        final List<dynamic> datos = jsonDecode(respuesta.body);
        return RespuestaApi(exito: true, datos: datos.map((i) => ImagenGaleria.fromJson(i)).toList(), mensaje: 'Galería cargada');
      }
      return RespuestaApi(exito: false, mensaje: 'Error: ${respuesta.statusCode}');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  Future<RespuestaApi<List<SalaChat>>> obtenerSalasChat(int comunidadId) async {
    try {
      final respuesta = await http.get(
        Uri.parse('${_urlMensajeria}salas/?comunidad_id=$comunidadId'),
        headers: await _getHeaders(),
      );
      if (respuesta.statusCode == 200) {
        final List<dynamic> datos = jsonDecode(respuesta.body);
        return RespuestaApi(exito: true, datos: datos.map((s) => SalaChat.fromJson(s)).toList(), mensaje: 'Salas cargadas');
      }
      return RespuestaApi(exito: false, mensaje: 'Error: ${respuesta.statusCode}');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  Future<RespuestaApi<Publicacion>> crearPublicacion({
    required int comunidadId,
    required String texto,
    dynamic imagen, // Puede ser XFile o File
    String? etiquetas,
  }) async {
    try {
      final tokenInfo = await _servicioUsuarios.obtenerToken();
      final uri = Uri.parse('${_urlContenido}publicaciones/crear/');
      
      var request = http.MultipartRequest('POST', uri);
      if (tokenInfo != null) {
        request.headers['Authorization'] = 'Token $tokenInfo';
      }
      
      request.fields['comunidad'] = comunidadId.toString();
      request.fields['contenido_texto'] = texto;
      if (etiquetas != null && etiquetas.trim().isNotEmpty) {
        request.fields['etiquetas'] = etiquetas.trim();
      }
      
      if (imagen != null) {
        if (kIsWeb && imagen is XFile) {
          final bytes = await imagen.readAsBytes();
          request.files.add(http.MultipartFile.fromBytes(
            'url_archivo_s3', 
            bytes, 
            filename: imagen.name,
            contentType: MediaType('image', 'jpeg')
          ));
        } else if (imagen is XFile) {
          request.files.add(await http.MultipartFile.fromPath('url_archivo_s3', imagen.path));
        }
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        return RespuestaApi(
          exito: true, 
          datos: Publicacion.fromJson(jsonDecode(response.body)),
          mensaje: 'Publicación creada'
        );
      }

      final decoded = jsonDecode(response.body);
      final mensajeError = decoded is Map<String, dynamic>
          ? decoded['error']?.toString() ?? decoded['detail']?.toString() ?? 'Error al crear la publicación'
          : 'Error al crear la publicación';
      return RespuestaApi(exito: false, mensaje: mensajeError);
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  Future<RespuestaApi> eliminarComunidad(int id) async {
    try {
      final token = await _servicioUsuarios.obtenerToken();
      final response = await http.delete(
        Uri.parse('$_urlBase$id/'),
        headers: {'Authorization': 'Token $token'},
      );

      if (response.statusCode == 204) return RespuestaApi(exito: true, mensaje: 'Comunidad eliminada');
      return RespuestaApi(exito: false, mensaje: 'Error al eliminar la comunidad');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  Future<RespuestaApi> editarComunidad(int id, Map<String, dynamic> datos) async {
    try {
      final token = await _servicioUsuarios.obtenerToken();
      final response = await http.patch(
        Uri.parse('$_urlBase$id/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(datos),
      );

      if (response.statusCode == 200) return RespuestaApi(exito: true, mensaje: 'Comunidad actualizada');
      return RespuestaApi(exito: false, mensaje: 'Error al actualizar la comunidad');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  // --- MÉTODOS DE MODERACIÓN ---

  Future<RespuestaApi<Publicacion>> obtenerPublicacion(int id) async {
    try {
      final respuesta = await http.get(
        Uri.parse('${_urlContenido}publicaciones/$id/'),
        headers: await _getHeaders(),
      );
      if (respuesta.statusCode == 200) {
        return RespuestaApi(
          exito: true, 
          datos: Publicacion.fromJson(jsonDecode(respuesta.body)),
          mensaje: 'Publicación cargada'
        );
      }
      return RespuestaApi(exito: false, mensaje: 'Error: ${respuesta.statusCode}');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  Future<RespuestaApi> eliminarPublicacion(int id, {String? razon}) async {
    try {
      final respuesta = await http.delete(
        Uri.parse('${_urlContenido}publicaciones/$id/'),
        headers: await _getHeaders(),
        body: razon != null ? jsonEncode({'razon': razon}) : null,
      );
      if (respuesta.statusCode == 204 || respuesta.statusCode == 200) {
        return RespuestaApi(exito: true, mensaje: 'Publicación eliminada');
      }
      return RespuestaApi(exito: false, mensaje: 'Error: ${respuesta.statusCode}');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  Future<RespuestaApi> eliminarComentario(int id, {String? razon}) async {
    try {
      final respuesta = await http.delete(
        Uri.parse('${_urlContenido}comentarios/$id/'),
        headers: await _getHeaders(),
        body: razon != null ? jsonEncode({'razon': razon}) : null,
      );
      if (respuesta.statusCode == 204 || respuesta.statusCode == 200) {
        return RespuestaApi(exito: true, mensaje: 'Comentario eliminado');
      }
      return RespuestaApi(exito: false, mensaje: 'Error: ${respuesta.statusCode}');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }
}
