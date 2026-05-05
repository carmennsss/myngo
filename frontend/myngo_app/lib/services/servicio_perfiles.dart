import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import '../models/perfil.dart';
import '../models/publicacion.dart';
import '../models/respuesta_api.dart';
import '../models/usuario.dart';
import '../utils/configuracion.dart';
import 'servicio_usuarios.dart';

/// Servicio encargado de la gestión de perfiles de usuario y sus interacciones sociales.
class ServicioPerfiles {
  static const String _urlUsuarios = '${Configuracion.baseUrl}/usuarios';
  final _servicioUsuarios = ServicioUsuarios();

  Future<Map<String, String>> _obtenerCabeceras() async {
    final token = await _servicioUsuarios.obtenerToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Token $token',
    };
  }

  /// Recupera la información detallada de un perfil de usuario por su ID.
  Future<RespuestaApi<Perfil>> obtenerPerfil(int userId) async {
    try {
      final respuesta = await http.get(
        Uri.parse('$_urlUsuarios/perfiles/$userId/'),
        headers: await _obtenerCabeceras(),
      ).timeout(const Duration(seconds: 15));

      if (respuesta.statusCode == 200) {
        return RespuestaApi(
          exito: true,
          mensaje: 'Perfil recuperado',
          datos: Perfil.fromJson(jsonDecode(utf8.decode(respuesta.bodyBytes))),
        );
      }
      return RespuestaApi(exito: false, mensaje: 'Error al cargar el perfil');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  /// Obtiene las publicaciones asociadas a un perfil específico con paginación.
  Future<RespuestaApi<List<Publicacion>>> obtenerPublicacionesPerfil(int perfilId, {int? pagina}) async {
    try {
      String query = 'perfil_id=$perfilId';
      if (pagina != null) query += '&page=$pagina';
      final uri = Uri.parse('${Configuracion.baseUrl}/contenido/publicaciones/?$query');
      final respuesta = await http.get(uri, headers: await _obtenerCabeceras()).timeout(const Duration(seconds: 20));

      if (respuesta.statusCode == 200) {
        final dynamic datosJson = jsonDecode(utf8.decode(respuesta.bodyBytes));
        final List<dynamic> lista = datosJson is List ? datosJson : (datosJson['results'] ?? []);
        return RespuestaApi(
          exito: true,
          mensaje: 'Publicaciones recuperadas',
          datos: lista.map((p) => Publicacion.fromJson(p)).toList(),
        );
      }
      return RespuestaApi(exito: false, mensaje: 'Error al cargar publicaciones');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  /// Alterna el estado de seguimiento entre el usuario actual y otro usuario.
  Future<RespuestaApi<Map<String, dynamic>>> alternarSeguimiento(int userId) async {
    try {
      final respuesta = await http.post(
        Uri.parse('$_urlUsuarios/perfiles/$userId/seguir/'),
        headers: await _obtenerCabeceras(),
      ).timeout(const Duration(seconds: 15));

      if (respuesta.statusCode == 200 || respuesta.statusCode == 201) {
        return RespuestaApi(
          exito: true,
          mensaje: 'Acción de seguimiento procesada',
          datos: jsonDecode(respuesta.body),
        );
      }
      return RespuestaApi(exito: false, mensaje: 'Error al procesar seguimiento');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  /// Método para enviar solicitud de seguimiento (usado en PantallaDetallePerfil).
  Future<RespuestaApi<String>> enviarSolicitudSeguimiento(String nombreUsuario) async {
    try {
      final respuesta = await http.post(
        Uri.parse('$_urlUsuarios/$nombreUsuario/'),
        headers: await _obtenerCabeceras(),
      ).timeout(const Duration(seconds: 15));

      if (respuesta.statusCode == 200 || respuesta.statusCode == 201) {
        final datos = jsonDecode(respuesta.body);
        return RespuestaApi(
          exito: true,
          mensaje: 'Acción procesada',
          datos: datos['estado'] as String?,
        );
      }
      return RespuestaApi(exito: false, mensaje: 'Error al enviar solicitud');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  /// Responde a una solicitud de seguimiento.
  Future<RespuestaApi<Map<String, dynamic>>> responderSolicitudSeguimiento(int peticionId, bool aceptar) async {
    try {
      final respuesta = await http.post(
        Uri.parse('$_urlUsuarios/peticiones/$peticionId/responder/'),
        headers: await _obtenerCabeceras(),
        body: jsonEncode({'aceptar': aceptar}),
      ).timeout(const Duration(seconds: 15));

      if (respuesta.statusCode == 200) {
        return RespuestaApi(exito: true, mensaje: 'Respuesta enviada');
      }
      return RespuestaApi(exito: false, mensaje: 'Error al responder solicitud');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  /// Actualiza los datos del perfil del usuario autenticado.
  Future<RespuestaApi<Perfil>> actualizarPerfil(Map<String, dynamic> datos) async {
    try {
      final idPerfil = await _servicioUsuarios.obtenerIdUsuario();
      if (idPerfil == null) return RespuestaApi(exito: false, mensaje: 'Sesión no válida');

      final respuesta = await http.patch(
        Uri.parse('$_urlUsuarios/perfiles/$idPerfil/'),
        headers: await _obtenerCabeceras(),
        body: jsonEncode(datos),
      ).timeout(const Duration(seconds: 15));

      if (respuesta.statusCode == 200) {
        return RespuestaApi(
          exito: true,
          mensaje: 'Perfil actualizado con éxito',
          datos: Perfil.fromJson(jsonDecode(utf8.decode(respuesta.bodyBytes))),
        );
      }
      return RespuestaApi(exito: false, mensaje: 'Error al actualizar perfil');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  /// Edita la biografía (compatibilidad).
  Future<RespuestaApi<Perfil>> editarBiografia({required String textoBiografia, required int perfilId}) async {
    return actualizarPerfil({'biografia': textoBiografia});
  }

  /// Sube un nuevo avatar.
  Future<RespuestaApi<Perfil>> editarAvatarPerfil({required XFile imagen, required int perfilId}) async {
    try {
      final token = await _servicioUsuarios.obtenerToken();
      final solicitud = http.MultipartRequest('PATCH', Uri.parse('$_urlUsuarios/perfiles/$perfilId/'));
      
      if (token != null) solicitud.headers['Authorization'] = 'Token $token';

      final mimeType = lookupMimeType(imagen.path) ?? 'image/jpeg';
      final typeParts = mimeType.split('/');

      if (kIsWeb) {
        final bytes = await imagen.readAsBytes();
        solicitud.files.add(http.MultipartFile.fromBytes('url_avatar', bytes, filename: imagen.name, contentType: MediaType(typeParts[0], typeParts[1])));
      } else {
        solicitud.files.add(await http.MultipartFile.fromPath('url_avatar', imagen.path, contentType: MediaType(typeParts[0], typeParts[1])));
      }

      final respuestaStream = await solicitud.send().timeout(const Duration(minutes: 2));
      final respuesta = await http.Response.fromStream(respuestaStream);

      if (respuesta.statusCode == 200) {
        return RespuestaApi(exito: true, mensaje: 'Avatar actualizado', datos: Perfil.fromJson(jsonDecode(utf8.decode(respuesta.bodyBytes))));
      }
      return RespuestaApi(exito: false, mensaje: 'Error al subir avatar');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de red: $e');
    }
  }

  /// Publica un nuevo post (con soporte mejorado para vídeos).
  Future<RespuestaApi<Publicacion>> crearPublicacionPerfil({
    required String texto,
    List<XFile>? imagenes,
    String? etiquetas,
    int? comunidadId,
  }) async {
    try {
      final token = await _servicioUsuarios.obtenerToken();
      final url = '${Configuracion.baseUrl}/contenido/publicaciones/';
      final solicitud = http.MultipartRequest('POST', Uri.parse(url));

      if (token != null) solicitud.headers['Authorization'] = 'Token $token';
      solicitud.fields['contenido_texto'] = texto;
      if (etiquetas != null && etiquetas.trim().isNotEmpty) solicitud.fields['etiquetas'] = etiquetas.trim();
      if (comunidadId != null) solicitud.fields['comunidad'] = comunidadId.toString();

      if (imagenes != null && imagenes.isNotEmpty) {
        for (var xfile in imagenes) {
          // Usamos el nombre para detectar el tipo real (mp4, mov...) en Web
          final mimeType = lookupMimeType(xfile.name) ?? (xfile.name.endsWith('.mp4') ? 'video/mp4' : 'image/jpeg');
          final typeParts = mimeType.split('/');
          
          if (kIsWeb) {
            final bytes = await xfile.readAsBytes();
            solicitud.files.add(http.MultipartFile.fromBytes(
              'url_archivo_s3[]', 
              bytes, 
              filename: xfile.name, 
              contentType: MediaType(typeParts[0], typeParts[1])
            ));
          } else {
            solicitud.files.add(await http.MultipartFile.fromPath(
              'url_archivo_s3[]', 
              xfile.path, 
              contentType: MediaType(typeParts[0], typeParts[1])
            ));
          }
        }
      }

      final respuestaStream = await solicitud.send().timeout(const Duration(minutes: 5));
      final respuesta = await http.Response.fromStream(respuestaStream);

      if (respuesta.statusCode == 201) {
        final datosJson = jsonDecode(utf8.decode(respuesta.bodyBytes));
        final nuevaPublicacion = Publicacion.fromJson(datosJson);
        if (!nuevaPublicacion.esValidoIa) return RespuestaApi(exito: false, mensaje: 'Contenido rechazado por la IA 🐾');
        return RespuestaApi(exito: true, mensaje: '¡Publicación realizada!');
      }
      return RespuestaApi(exito: false, mensaje: 'Error al publicar (${respuesta.statusCode})');
    } catch (e) {
      debugPrint('Error en crearPublicacionPerfil: $e');
      return RespuestaApi(exito: false, mensaje: 'Error de red: $e');
    }
  }

  Future<RespuestaApi<List<Publicacion>>> obtenerPublicacionesGuardadas({int? comunidadId, int? pagina}) async {
    try {
      String query = 'solo_guardados=true';
      if (comunidadId != null) query += '&comunidad_id=$comunidadId';
      if (pagina != null) query += '&page=$pagina';
      final uri = Uri.parse('${Configuracion.baseUrl}/contenido/publicaciones/?$query');
      final respuesta = await http.get(uri, headers: await _obtenerCabeceras()).timeout(const Duration(seconds: 20));

      if (respuesta.statusCode == 200) {
        final dynamic datosJson = jsonDecode(utf8.decode(respuesta.bodyBytes));
        final List<dynamic> lista = datosJson is List ? datosJson : (datosJson['results'] ?? []);
        return RespuestaApi(exito: true, mensaje: 'Favoritos recuperados', datos: lista.map((p) => Publicacion.fromJson(p)).toList());
      }
      return RespuestaApi(exito: false, mensaje: 'Error al cargar favoritos');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  Future<RespuestaApi<List<Usuario>>> obtenerSugerenciasSeguimiento() async {
    try {
      final respuesta = await http.get(Uri.parse('$_urlUsuarios/ranking/'), headers: await _obtenerCabeceras()).timeout(const Duration(seconds: 15));
      if (respuesta.statusCode == 200) {
        final dynamic decoded = jsonDecode(utf8.decode(respuesta.bodyBytes));
        final List<dynamic> lista = decoded['datos'] ?? [];
        return RespuestaApi(exito: true, mensaje: 'Sugerencias recuperadas', datos: lista.map((u) => Usuario.fromJson(u)).toList());
      }
      return RespuestaApi(exito: false, mensaje: 'Error al cargar sugerencias');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }
}
