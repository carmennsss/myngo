import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/respuesta_api.dart';
import '../models/comunidad.dart';
import 'servicio_usuarios.dart';

/// Servicio para gestionar las operaciones relacionadas con las comunidades.
class ServicioComunidades {
  static const String _urlBase = 'http://127.0.0.1:8000/comunidades/';
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
        final dynamic datosJson = jsonDecode(respuesta.body);
        final List<dynamic> listaJson = datosJson is List ? datosJson : (datosJson['results'] ?? []);
        final comunidades = listaJson.map((item) => Comunidad.fromJson(item)).toList();
        
        return RespuestaApi(
          exito: true,
          mensaje: 'Comunidades obtenidas',
          datos: comunidades,
        );
      } else {
        return RespuestaApi(
          exito: false,
          mensaje: 'Error al obtener comunidades: ${respuesta.statusCode}',
        );
      }
    } catch (e) {
      return RespuestaApi(
        exito: false,
        mensaje: 'Error de conexión: $e',
      );
    }
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
        
        return RespuestaApi(
          exito: true,
          mensaje: 'Mis comunidades obtenidas',
          datos: comunidades,
        );
      } else {
        return RespuestaApi(
          exito: false,
          mensaje: 'Error al obtener tus comunidades: ${respuesta.statusCode}',
        );
      }
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  /// Permite unirse a una comunidad o enviar solicitud.
  Future<RespuestaApi<Map<String, dynamic>>> unirseAComunidad(int id) async {
    try {
      final respuesta = await http.post(
        Uri.parse('${_urlBase}$id/unirse/'),
        headers: await _getHeaders(),
      );

      if (respuesta.statusCode == 201 || respuesta.statusCode == 200) {
        final Map<String, dynamic> datosJson = jsonDecode(respuesta.body);
        return RespuestaApi(
          exito: true,
          mensaje: datosJson['mensaje'] ?? 'Operación exitosa',
          datos: datosJson,
        );
      } else {
        return RespuestaApi(
          exito: false,
          mensaje: 'Error al procesar solicitud: ${respuesta.statusCode}',
        );
      }
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  /// Crea una nueva comunidad en el servidor soportando subida de imagen.
  Future<RespuestaApi<Comunidad>> crearComunidad(Comunidad comunidad, {XFile? imagen}) async {
    try {
      final token = await _servicioUsuarios.obtenerToken();
      
      var solicitud = http.MultipartRequest('POST', Uri.parse(_urlBase));
      
      if (token != null) {
        solicitud.headers['Authorization'] = 'Token $token';
      }

      // Campos de texto
      solicitud.fields['nombre'] = comunidad.nombre;
      solicitud.fields['descripcion'] = comunidad.descripcion;
      solicitud.fields['es_publica'] = comunidad.esPublica.toString();

      // Archivo de imagen
      if (imagen != null) {
        if (kIsWeb) {
          final bytes = await imagen.readAsBytes();
          final ext = imagen.name.split('.').last.toLowerCase();
          final subtype = {'jpg': 'jpeg', 'jpeg': 'jpeg', 'png': 'png', 'webp': 'webp', 'gif': 'gif'}[ext] ?? 'jpeg';
          solicitud.files.add(http.MultipartFile.fromBytes(
            'url_portada',
            bytes,
            filename: imagen.name,
            contentType: MediaType('image', subtype),
          ));
        } else {
          solicitud.files.add(await http.MultipartFile.fromPath(
            'url_portada',
            imagen.path,
          ));
        }
      }

      final respuestaStream = await solicitud.send();
      final respuesta = await http.Response.fromStream(respuestaStream);

      if (respuesta.statusCode == 201) {
        final Map<String, dynamic> datosJson = jsonDecode(respuesta.body);
        return RespuestaApi(
          exito: true,
          mensaje: 'Comunidad creada con éxito',
          datos: Comunidad.fromJson(datosJson),
        );
      } else {
        return RespuestaApi(
          exito: false,
          mensaje: 'Error al crear comunidad: ${respuesta.statusCode}',
        );
      }
    } catch (e) {
      return RespuestaApi(
        exito: false,
        mensaje: 'Error de conexión: $e',
      );
    }
  }

  /// Responde a una petición de unión (Aceptar/Rechazar).
  Future<RespuestaApi<void>> responderPeticion(int idPeticion, bool aceptar) async {
    try {
      final respuesta = await http.post(
        Uri.parse('${_urlBase}peticiones/$idPeticion/responder/'),
        headers: await _getHeaders(),
        body: jsonEncode({'aceptar': aceptar}),
      );

      if (respuesta.statusCode == 200) {
        return RespuestaApi(exito: true, mensaje: 'Respuesta enviada');
      } else {
        return RespuestaApi(exito: false, mensaje: 'Error al responder: ${respuesta.statusCode}');
      }
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }
}
