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

  /// Recupera la información detallada de un perfil por su NOMBRE DE USUARIO o ID.
  Future<RespuestaApi<Perfil>> obtenerPerfil(String identifier) async {
    try {
      final respuesta = await http.get(
        Uri.parse('$_urlUsuarios/$identifier/'),
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

  /// Obtiene las publicaciones asociadas a un perfil. Acepta String o int.
  Future<RespuestaApi<List<Publicacion>>> obtenerPublicacionesPerfil(dynamic identifier, {int? pagina}) async {
    try {
      final idStr = identifier.toString();
      final url = '$_urlUsuarios/$idStr/publicaciones/${pagina != null ? '?page=$pagina' : ''}';
      final respuesta = await http.get(
        Uri.parse(url),
        headers: await _obtenerCabeceras(),
      ).timeout(const Duration(seconds: 15));

      if (respuesta.statusCode == 200) {
        final List<dynamic> datosJson = jsonDecode(utf8.decode(respuesta.bodyBytes));
        return RespuestaApi(
          exito: true,
          mensaje: 'Publicaciones recuperadas',
          datos: datosJson.map((p) => Publicacion.fromJson(p)).toList(),
        );
      }
      return RespuestaApi(exito: false, mensaje: 'Error al cargar publicaciones');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  /// Envía solicitud de seguimiento (devuelve el String del estado para la UI).
  Future<RespuestaApi<String>> enviarSolicitudSeguimiento(String nombreUsuario) async {
    final res = await alternarSeguimiento(nombreUsuario);
    if (res.exito && res.datos != null) {
      return RespuestaApi(
        exito: true,
        mensaje: res.mensaje,
        datos: res.datos!['estado'] as String?,
      );
    }
    return RespuestaApi(exito: false, mensaje: res.mensaje);
  }

  /// Alterna el estado de seguimiento.
  Future<RespuestaApi<Map<String, dynamic>>> alternarSeguimiento(String nombreUsuario) async {
    try {
      final respuesta = await http.post(
        Uri.parse('$_urlUsuarios/$nombreUsuario/'),
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

  /// Acepta o rechaza una solicitud de seguimiento.
  Future<RespuestaApi<Map<String, dynamic>>> responderSolicitudSeguimiento(int peticionId, bool aceptar) async {
    try {
      final respuesta = await http.post(
        Uri.parse('$_urlUsuarios/peticiones/$peticionId/responder/'),
        headers: await _obtenerCabeceras(),
        body: jsonEncode({'aceptar': aceptar}),
      ).timeout(const Duration(seconds: 15));

      if (respuesta.statusCode == 200) {
        return RespuestaApi(exito: true, mensaje: 'Respuesta enviada correctamente');
      }
      return RespuestaApi(exito: false, mensaje: 'Error al responder la solicitud');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  /// Actualiza la biografía (coincide con el nombre de parámetro esperado).
  Future<RespuestaApi<Perfil>> editarBiografia({required String textoBiografia, required int perfilId}) async {
    return actualizarPerfil({'biografia': textoBiografia});
  }

  /// Actualiza el perfil de forma genérica.
  Future<RespuestaApi<Perfil>> actualizarPerfil(Map<String, dynamic> datos) async {
    try {
      final idPerfil = await _servicioUsuarios.obtenerIdUsuario();
      if (idPerfil == null) return RespuestaApi(exito: false, mensaje: 'Sesión no válida');

      final respuesta = await http.patch(
        Uri.parse('$_urlUsuarios/perfil/editar/'),
        headers: await _obtenerCabeceras(),
        body: jsonEncode({
          ...datos,
          'perfil_id': idPerfil,
        }),
      ).timeout(const Duration(seconds: 15));

      if (respuesta.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(respuesta.bodyBytes));
        return RespuestaApi(
          exito: true,
          mensaje: 'Perfil actualizado con éxito',
          datos: Perfil.fromJson(decoded['datos']),
        );
      }
      return RespuestaApi(exito: false, mensaje: 'Error al actualizar perfil');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  /// Sube un nuevo avatar.
  Future<RespuestaApi<Perfil>> editarAvatarPerfil({required XFile imagen, required int perfilId}) async {
    try {
      final token = await _servicioUsuarios.obtenerToken();
      final solicitud = http.MultipartRequest('PATCH', Uri.parse('$_urlUsuarios/perfil/editar/'));
      
      if (token != null) solicitud.headers['Authorization'] = 'Token $token';
      solicitud.fields['perfil_id'] = perfilId.toString();
      solicitud.fields['es_perfil'] = 'true';

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
        final decoded = jsonDecode(utf8.decode(respuesta.bodyBytes));
        return RespuestaApi(exito: true, mensaje: 'Avatar actualizado', datos: Perfil.fromJson(decoded['datos']));
      }
      return RespuestaApi(exito: false, mensaje: 'Error al subir avatar');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de red: $e');
    }
  }

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
          final mimeType = lookupMimeType(xfile.path) ?? 'image/jpeg';
          final typeParts = mimeType.split('/');
          if (kIsWeb) {
            final bytes = await xfile.readAsBytes();
            solicitud.files.add(http.MultipartFile.fromBytes('url_archivo_s3[]', bytes, filename: xfile.name, contentType: MediaType(typeParts[0], typeParts[1])));
          } else {
            solicitud.files.add(await http.MultipartFile.fromPath('url_archivo_s3[]', xfile.path, contentType: MediaType(typeParts[0], typeParts[1])));
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
