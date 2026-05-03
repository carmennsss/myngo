import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import '../models/perfil.dart';
import '../models/publicacion.dart';
import '../models/respuesta_api.dart';
import '../models/usuario.dart';
import '../utils/configuracion.dart';
import 'servicio_usuarios.dart';

/// Servicio encargado de la gestión de perfiles de usuario y sus interacciones sociales.
///
/// Ofrece funcionalidades para consultar perfiles, gestionar seguimientos,
/// editar información personal y recuperar el historial de publicaciones.
class ServicioPerfiles {
  /// URL base para los endpoints relacionados con usuarios.
  static const String _urlUsuarios = '${Configuracion.baseUrl}/usuarios';

  final _servicioUsuarios = ServicioUsuarios();

  /// Genera las cabeceras estándar (JSON + Token) para las peticiones API.
  Future<Map<String, String>> _obtenerCabeceras() async {
    final token = await _servicioUsuarios.obtenerToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Token $token',
    };
  }

  /// Recupera una lista de perfiles, con soporte para filtrado por búsqueda.
  Future<RespuestaApi<List<Perfil>>> listarPerfiles({String? busqueda}) async {
    try {
      final query = busqueda != null && busqueda.isNotEmpty ? '?search=$busqueda' : '';
      final respuesta = await http.get(
        Uri.parse('$_urlUsuarios/$query'),
        headers: await _obtenerCabeceras(),
      ).timeout(const Duration(seconds: 20));

      final dynamic datosJson = jsonDecode(respuesta.body);

      if (respuesta.statusCode == 200) {
        final List<dynamic> listaJson = datosJson is List ? datosJson : (datosJson['results'] ?? []);
        return RespuestaApi(
          exito: true,
          mensaje: 'Perfiles recuperados',
          datos: listaJson.map((j) => Perfil.fromJson(j)).toList(),
        );
      }

      return RespuestaApi(exito: false, mensaje: 'Error al cargar perfiles (${respuesta.statusCode})');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  /// Obtiene la información detallada de un usuario mediante su identificador único.
  Future<RespuestaApi<Usuario>> obtenerPerfil(String nombreUsuario) async {
    try {
      final respuesta = await http.get(
        Uri.parse('$_urlUsuarios/$nombreUsuario/'),
        headers: await _obtenerCabeceras(),
      ).timeout(const Duration(seconds: 20));

      final Map<String, dynamic> datosJson = jsonDecode(respuesta.body);

      if (respuesta.statusCode == 200) {
        return RespuestaApi.fromJson(
          datosJson,
          transformador: (j) => Usuario.fromJson(j),
        );
      }

      return RespuestaApi(exito: false, mensaje: datosJson['mensaje'] ?? 'Error al cargar perfil');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  /// Envía una solicitud de seguimiento a un usuario específico.
  Future<RespuestaApi<String>> enviarSolicitudSeguimiento(String nombreUsuario) async {
    try {
      final respuesta = await http.post(
        Uri.parse('$_urlUsuarios/$nombreUsuario/solicitud'),
        headers: await _obtenerCabeceras(),
      ).timeout(const Duration(seconds: 20));

      final Map<String, dynamic> datosJson = jsonDecode(respuesta.body);

      if (respuesta.statusCode == 200 || respuesta.statusCode == 201) {
        return RespuestaApi(
          exito: true,
          mensaje: datosJson['mensaje'] ?? 'Operación exitosa',
          datos: datosJson['estado'],
        );
      }

      return RespuestaApi(
        exito: false,
        mensaje: datosJson['mensaje'] ?? datosJson['error'] ?? 'Error al enviar solicitud',
      );
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  /// Gestiona la respuesta (aceptar/rechazar) a una solicitud de seguimiento recibida.
  Future<RespuestaApi<void>> responderSolicitudSeguimiento(int idSolicitud, bool aceptar) async {
    try {
      final respuesta = await http.post(
        Uri.parse('$_urlUsuarios/peticiones/$idSolicitud/responder/'),
        headers: await _obtenerCabeceras(),
        body: jsonEncode({'aceptar': aceptar}),
      ).timeout(const Duration(seconds: 20));

      if (respuesta.statusCode == 200 || respuesta.statusCode == 201) {
        return RespuestaApi(exito: true, mensaje: 'Solicitud procesada');
      }

      return RespuestaApi(exito: false, mensaje: 'Error al responder la solicitud');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  /// Publica contenido en el muro personal del usuario con soporte multimedia.
  Future<RespuestaApi<void>> crearPublicacionPerfil({
    required String texto,
    List<XFile>? imagenes,
    String? etiquetas,
  }) async {
    try {
      final token = await _servicioUsuarios.obtenerToken();
      final uri = Uri.parse('${Configuracion.baseUrl}/contenido/publicaciones/crear/');

      var solicitud = http.MultipartRequest('POST', uri);
      if (token != null) solicitud.headers['Authorization'] = 'Token $token';

      solicitud.fields['contenido_texto'] = texto;
      if (etiquetas != null && etiquetas.trim().isNotEmpty) {
        solicitud.fields['etiquetas'] = etiquetas.trim();
      }

      if (imagenes != null && imagenes.isNotEmpty) {
        for (var img in imagenes) {
          if (kIsWeb) {
            final bytes = await img.readAsBytes();
            solicitud.files.add(http.MultipartFile.fromBytes(
              'url_archivo_s3[]',
              bytes,
              filename: img.name,
              contentType: MediaType('image', 'jpeg'),
            ));
          } else {
            solicitud.files.add(await http.MultipartFile.fromPath('url_archivo_s3[]', img.path));
          }
        }
      }

      final respuestaStream = await solicitud.send().timeout(const Duration(seconds: 40));
      final respuesta = await http.Response.fromStream(respuestaStream);

      if (respuesta.statusCode == 201) {
        final datosJson = jsonDecode(utf8.decode(respuesta.bodyBytes));
        final nuevaPublicacion = Publicacion.fromJson(datosJson);
        if (!nuevaPublicacion.esValidoIa) {
          return RespuestaApi(
            exito: false,
            mensaje: 'Contenido rechazado por el filtro de seguridad (IA) 🐾',
          );
        }
        return RespuestaApi(exito: true, mensaje: '¡Publicación realizada!');
      }

      return RespuestaApi(exito: false, mensaje: 'Error al publicar (${respuesta.statusCode})');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  /// Recupera la lista de publicaciones que el usuario ha marcado como favoritas.
  Future<RespuestaApi<List<Publicacion>>> obtenerPublicacionesGuardadas({int? comunidadId}) async {
    try {
      final query = comunidadId != null ? '&comunidad_id=$comunidadId' : '';
      final uri = Uri.parse('${Configuracion.baseUrl}/contenido/publicaciones/?solo_guardados=true$query');
      
      final respuesta = await http.get(
        uri,
        headers: await _obtenerCabeceras(),
      ).timeout(const Duration(seconds: 20));

      if (respuesta.statusCode == 200) {
        final dynamic datosJson = jsonDecode(respuesta.body);
        final List<dynamic> lista = datosJson is List ? datosJson : (datosJson['results'] ?? []);
        return RespuestaApi(
          exito: true,
          mensaje: 'Favoritos recuperados',
          datos: lista.map((p) => Publicacion.fromJson(p)).toList(),
        );
      }
      return RespuestaApi(exito: false, mensaje: 'Error al cargar favoritos');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  /// Recupera el historial completo de publicaciones de un perfil específico.
  Future<RespuestaApi<List<Publicacion>>> obtenerPublicacionesPerfil(int perfilId) async {
    try {
      final uri = Uri.parse('${Configuracion.baseUrl}/contenido/publicaciones/?perfil_id=$perfilId');
      final respuesta = await http.get(
        uri,
        headers: await _obtenerCabeceras(),
      ).timeout(const Duration(seconds: 20));

      if (respuesta.statusCode == 200) {
        final dynamic datosJson = jsonDecode(respuesta.body);
        final List<dynamic> lista = datosJson is List ? datosJson : (datosJson['results'] ?? []);
        return RespuestaApi(
          exito: true,
          mensaje: 'Publicaciones del perfil recuperadas',
          datos: lista.map((p) => Publicacion.fromJson(p)).toList(),
        );
      }
      return RespuestaApi(exito: false, mensaje: 'Error al cargar publicaciones');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  /// Actualiza la descripción biográfica del perfil del usuario.
  Future<RespuestaApi<void>> editarBiografia({
    required String textoBiografia,
    required int perfilId,
  }) async {
    try {
      final respuesta = await http.patch(
        Uri.parse('${Configuracion.baseUrl}/usuarios/perfil/editar/'),
        headers: await _obtenerCabeceras(),
        body: jsonEncode({
          'perfil_id': perfilId,
          'biografia': textoBiografia,
        }),
      ).timeout(const Duration(seconds: 20));

      if (respuesta.statusCode == 200 || respuesta.statusCode == 204) {
        return RespuestaApi(exito: true, mensaje: 'Biografía actualizada');
      }
      return RespuestaApi(exito: false, mensaje: 'Error al actualizar biografía');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  /// Actualiza la imagen de avatar del perfil del usuario.
  Future<RespuestaApi<String>> editarAvatarPerfil({
    required dynamic imagen,
    required int perfilId,
  }) async {
    try {
      final token = await _servicioUsuarios.obtenerToken();
      final uri = Uri.parse('${Configuracion.baseUrl}/usuarios/perfil/editar/');
      var solicitud = http.MultipartRequest('PATCH', uri);

      if (token != null) solicitud.headers['Authorization'] = 'Token $token';

      solicitud.fields['perfil_id'] = perfilId.toString();
      solicitud.fields['es_perfil'] = 'True';

      if (imagen is XFile) {
        if (kIsWeb) {
          final bytes = await imagen.readAsBytes();
          solicitud.files.add(http.MultipartFile.fromBytes(
            'url_avatar',
            bytes,
            filename: imagen.name,
            contentType: MediaType('image', 'jpeg'),
          ));
        } else {
          solicitud.files.add(await http.MultipartFile.fromPath('url_avatar', imagen.path));
        }
      }

      final respuestaStream = await solicitud.send().timeout(const Duration(seconds: 40));
      final respuesta = await http.Response.fromStream(respuestaStream);

      if (respuesta.statusCode == 200) {
        final datosJson = jsonDecode(respuesta.body);
        String? urlFinal = datosJson['url_avatar']?.toString();

        if (urlFinal == null && datosJson['datos'] != null) {
          urlFinal = datosJson['datos']['url_avatar']?.toString();
        }

        return RespuestaApi(
          exito: true,
          mensaje: '¡Foto de perfil actualizada!',
          datos: urlFinal,
        );
      }
      return RespuestaApi(exito: false, mensaje: 'Error al subir la imagen');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  /// Actualiza la imagen de fondo (banner o feed) del perfil del usuario.
  Future<RespuestaApi<String>> editarFondoPerfil({
    required dynamic imagen,
    required int perfilId,
    String destino = 'banner',
  }) async {
    try {
      final token = await _servicioUsuarios.obtenerToken();
      final uri = Uri.parse('${Configuracion.baseUrl}/usuarios/perfil/editar/');
      var solicitud = http.MultipartRequest('PATCH', uri);

      if (token != null) solicitud.headers['Authorization'] = 'Token $token';

      solicitud.fields['perfil_id'] = perfilId.toString();
      solicitud.fields['es_perfil'] = 'True';

      final fieldName = (destino == 'fondo_feed') ? 'url_fondo_perfil' : 'url_fondo';

      if (imagen is XFile) {
        if (kIsWeb) {
          final bytes = await imagen.readAsBytes();
          solicitud.files.add(http.MultipartFile.fromBytes(
            fieldName,
            bytes,
            filename: imagen.name,
            contentType: MediaType('image', 'jpeg'),
          ));
        } else {
          solicitud.files.add(await http.MultipartFile.fromPath(fieldName, imagen.path));
        }
      }

      final respuestaStream = await solicitud.send().timeout(const Duration(seconds: 40));
      final respuesta = await http.Response.fromStream(respuestaStream);

      if (respuesta.statusCode == 200) {
        final datosJson = jsonDecode(respuesta.body);
        final resultKey = (destino == 'fondo_feed') ? 'fondo_perfil' : 'fondo';
        String? urlFinal = datosJson['datos']?[resultKey]?.toString();

        return RespuestaApi(
          exito: true,
          mensaje: (destino == 'fondo_feed') ? '¡Fondo del feed actualizado!' : '¡Fondo (banner) actualizado!',
          datos: urlFinal,
        );
      }
      return RespuestaApi(exito: false, mensaje: 'Error al subir la imagen');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }
}
