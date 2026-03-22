import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/respuesta_api.dart';
import '../models/usuario.dart';
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
}
