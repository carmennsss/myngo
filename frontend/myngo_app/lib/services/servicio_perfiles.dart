import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/respuesta_api.dart';
import '../models/usuario.dart';
import '../models/publicacion.dart';
import 'servicio_usuarios.dart';

class ServicioPerfiles {
  // URLs para que crees los endpoints homólogos en tu backend
  static const String _urlBase = 'http://127.0.0.1:8000/usuarios';
  final _servicioUsuarios = ServicioUsuarios();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _servicioUsuarios.obtenerToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Token $token',
    };
  }

  Future<RespuestaApi<List<Usuario>>> listarPerfiles({String? busqueda}) async {
    try {
      final uri = busqueda != null && busqueda.isNotEmpty 
          ? Uri.parse('$_urlBase/?search=$busqueda')
          : Uri.parse('$_urlBase/');
          
      final respuesta = await http.get(uri, headers: await _getHeaders());

      if (respuesta.statusCode == 200) {
        final dynamic datosJson = jsonDecode(respuesta.body);
        final List<dynamic> listaJson = datosJson is List ? datosJson : (datosJson['results'] ?? []);
        return RespuestaApi(
          exito: true,
          mensaje: 'Perfiles cargados',
          datos: listaJson.map((j) => Usuario.fromJson(j)).toList(),
        );
      }
      return RespuestaApi(
        exito: false, 
        mensaje: 'Error al cargar perfiles: ${respuesta.statusCode}'
      );
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Ha ocurrido un error en la api: $e');
    }
  }

  Future<RespuestaApi<Usuario>> obtenerPerfil(String nombreUsuario) async {
    try {
      final respuesta = await http.get(
        Uri.parse('$_urlBase/$nombreUsuario/'),
        headers: await _getHeaders(),
      );
      if (respuesta.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(respuesta.body);
        return RespuestaApi.fromJson(
          json, 
          transformador: (j) => Usuario.fromJson(j)
        );
      }
      return RespuestaApi(exito: false, mensaje: 'Error al cargar perfil');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Ha ocurrido un error en la api: $e');
    }
  }

  Future<RespuestaApi<String>> enviarSolicitud(String nombreUsuario) async {
    try {
      final respuesta = await http.post(
        Uri.parse('$_urlBase/$nombreUsuario/solicitud'),
        headers: await _getHeaders(),
      );
      if (respuesta.statusCode == 200 || respuesta.statusCode == 201) {
        final Map<String, dynamic> json = jsonDecode(respuesta.body);
        return RespuestaApi(
          exito: true, 
          mensaje: json['mensaje'] ?? 'Solicitud procesada con éxito',
          datos: json['estado'], // Extraemos el nuevo estado
        );
      } else {
        String mensajeError = 'Error al enviar solicitud: ${respuesta.statusCode}';
        try {
          final Map<String, dynamic> jsonErr = jsonDecode(respuesta.body);
          if (jsonErr.containsKey('error')) {
            mensajeError = jsonErr['error'];
          } else if (jsonErr.containsKey('mensaje')) {
            mensajeError = jsonErr['mensaje'];
          }
        } catch (_) {}
        return RespuestaApi(exito: false, mensaje: mensajeError);
      }
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  Future<RespuestaApi<void>> responderPeticion(int idPeticion, bool aceptar) async {
    try {
      final respuesta = await http.post(
        Uri.parse('$_urlBase/peticiones/$idPeticion/responder/'),
        headers: await _getHeaders(),
        body: jsonEncode({'aceptar': aceptar}),
      );
      if (respuesta.statusCode == 200 || respuesta.statusCode == 201) {
        return RespuestaApi(exito: true, mensaje: 'Respuesta enviada correctamente');
      }
      return RespuestaApi(exito: false, mensaje: 'Error: ${respuesta.statusCode}');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  Future<RespuestaApi<void>> crearPostPerfil({
    required String texto,
    dynamic imagen,
    String? etiquetas,
  }) async {
    try {
      final tokenInfo = await _servicioUsuarios.obtenerToken();
      final uri = Uri.parse('http://127.0.0.1:8000/contenido/publicaciones/crear/');
      
      var request = http.MultipartRequest('POST', uri);
      if (tokenInfo != null) {
        request.headers['Authorization'] = 'Token $tokenInfo';
      }
      
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
        return RespuestaApi(exito: true, mensaje: '¡Post subido a tu perfil!');
      }
      return RespuestaApi(exito: false, mensaje: 'Error al enviar publicación: ${response.statusCode}');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión con Myngo API: $e');
    }
  }

  Future<RespuestaApi<List<Publicacion>>> obtenerPublicacionesPerfil(int perfilId) async {
    try {
      final tokenInfo = await _servicioUsuarios.obtenerToken();
      final uri = Uri.parse('http://127.0.0.1:8000/contenido/publicaciones/?perfil_id=$perfilId');
      final respuesta = await http.get(uri, headers: {
        'Content-Type': 'application/json',
        if (tokenInfo != null) 'Authorization': 'Token $tokenInfo',
      });
      
      if (respuesta.statusCode == 200) {
        final dynamic datosJson = jsonDecode(respuesta.body);
        final List<dynamic> lista = datosJson is List ? datosJson : (datosJson['results'] ?? []);
        return RespuestaApi(
          exito: true, 
          datos: lista.map((p) => Publicacion.fromJson(p)).toList(), 
          mensaje: 'Publicaciones cargadas'
        );
      }
      return RespuestaApi(exito: false, mensaje: 'Error: ${respuesta.statusCode}');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  Future<RespuestaApi<void>> editarBiografia({
    required String biografia, 
    required int perfilId, // Nuevo parámetro
  }) async {
    try {
      final tokenInfo = await _servicioUsuarios.obtenerToken();
      final uri = Uri.parse('http://127.0.0.1:8000/usuarios/perfil/editar/');
      final respuesta = await http.patch(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (tokenInfo != null) 'Authorization': 'Token $tokenInfo',
        },
        body: jsonEncode({
          'perfil_id': perfilId, // Enviamos el ID al backend
          'biografia': biografia,
        }),
      );
      if (respuesta.statusCode == 200 || respuesta.statusCode == 204) {
        return RespuestaApi(exito: true, mensaje: '¡Biografía actualizada!');
      }
      return RespuestaApi(exito: false, mensaje: 'Error al actualizar: ${respuesta.statusCode}');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  Future<RespuestaApi<String>> editarAvatarPerfil({
    required dynamic imagen, 
    required int perfilId, // Nuevo parámetro
  }) async {
    try {
      final tokenInfo = await _servicioUsuarios.obtenerToken();
      final uri = Uri.parse('http://127.0.0.1:8000/usuarios/perfil/editar/');
      var request = http.MultipartRequest('PATCH', uri);
      
      if (tokenInfo != null) {
        request.headers['Authorization'] = 'Token $tokenInfo';
      }
      
      // Añadimos el perfil_id como campo de texto (convertido a String)
      request.fields['perfil_id'] = perfilId.toString();

      if (imagen is XFile) {
        if (kIsWeb) {
          final bytes = await imagen.readAsBytes();
          request.files.add(http.MultipartFile.fromBytes(
            'url_avatar', 
            bytes, 
            filename: imagen.name,
            contentType: MediaType('image', 'jpeg'),
          ));
        } else {
          request.files.add(await http.MultipartFile.fromPath('url_avatar', imagen.path));
        }
      }

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Extraer la url directamente de la raíz, que ahora la hemos puesto
        String? urlFinal = data['url_avatar']?.toString();
        
        // Fallback por si viene dentro de datos
        if (urlFinal == null && data['datos'] != null && data['datos'] is Map) {
            urlFinal = data['datos']['url_avatar']?.toString();
        }
            
        return RespuestaApi(
          exito: true, 
          mensaje: '¡Foto actualizada!', 
          datos: urlFinal
        );
      }
      return RespuestaApi(exito: false, mensaje: 'Error al subir imagen: ${response.statusCode}');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }
}
