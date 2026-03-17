import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/respuesta_api.dart';
import '../models/usuario.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Clase de servicio que encapsula la lógica de comunicación con la API de usuarios.
class ServicioUsuarios {
  /// URL base para los endpoints relacionados con usuarios.
  static const String _urlBase = 'http://127.0.0.1:8000/usuarios';

  /// Realiza una solicitud de autenticación al servidor.
  Future<RespuestaApi<Usuario>> iniciarSesion(String email, String contrasena) async {
    try {
      final respuesta = await http.post(
        Uri.parse('$_urlBase/login/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': contrasena,
        }),
      );

      if (respuesta.statusCode == 200) {
        final Map<String, dynamic> datosJson = jsonDecode(respuesta.body);
        
        if (datosJson.containsKey('token')) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', datosJson['token']);
          // Guardamos también el ID del usuario para comparaciones locales
          if (datosJson.containsKey('datos') && datosJson['datos']['id'] != null) {
            await prefs.setInt('usuario_id', datosJson['datos']['id']);
          }
        }

        return RespuestaApi.fromJson(
          datosJson,
          transformador: (json) => Usuario.fromJson(json),
        );
      } else {
        try {
          final Map<String, dynamic> datosJson = jsonDecode(respuesta.body);
          return RespuestaApi(
            exito: false,
            mensaje: datosJson['mensaje'] ?? 'Error en la autenticación',
            errores: datosJson['errores'],
          );
        } catch (_) {
          return RespuestaApi(
            exito: false,
            mensaje: 'Error en la autenticación: ${respuesta.statusCode}',
          );
        }
      }
    } catch (e) {
      return RespuestaApi(
        exito: false,
        mensaje: 'Error de conexión con el servidor: $e',
      );
    }
  }

  Future<RespuestaApi<Usuario>> registrarse(String nombre_usuario, String email, String contrasena) async {
    try {
      final respuesta = await http.post(
        Uri.parse('$_urlBase/registrar/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nombre_usuario': nombre_usuario,
          'email': email,
          'password': contrasena,
        }),
      );

      if (respuesta.statusCode >= 200 && respuesta.statusCode < 300) {
        final Map<String, dynamic> datosJson = jsonDecode(respuesta.body);
        return RespuestaApi.fromJson(
          datosJson,
          transformador: (json) => Usuario.fromJson(json),
        );
      } else {
        try {
          final Map<String, dynamic> datosJson = jsonDecode(respuesta.body);
          return RespuestaApi(
            exito: false,
            mensaje: datosJson['mensaje'] ?? 'Error en el registro',
            errores: datosJson['errores'],
          );
        } catch (_) {
          return RespuestaApi(
            exito: false,
            mensaje: 'Error en el registro: ${respuesta.statusCode}',
          );
        }
      }
    } catch (e) {
      return RespuestaApi(
        exito: false,
        mensaje: 'Error de conexión con el servidor: $e',
      );
    }
  }

  Future<RespuestaApi> recuperarContrasena(String email) async {
    try {
      final respuesta = await http.post(
        Uri.parse('$_urlBase/recuperar-password/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      if (respuesta.statusCode == 200) {
        final Map<String, dynamic> datosJson = jsonDecode(respuesta.body);
        return RespuestaApi.fromJson(datosJson);
      }
      return RespuestaApi(exito: false, mensaje: 'Error al recuperar contraseña: ${respuesta.statusCode}');
    } catch (e) {
      return RespuestaApi(
        exito: false,
        mensaje: 'Error de conexión con el servidor: $e',
      );
    }
  }

  /// Obtiene el token de acceso almacenado de forma persistente.
  Future<String?> obtenerToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('auth_token');
    } catch (e) {
      return null;
    }
  }

  /// Obtiene el ID del usuario logueado.
  Future<int?> obtenerIdUsuario() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt('usuario_id');
    } catch (e) {
      return null;
    }
  }

  /// Cierra la sesión borrando el token y el ID.
  Future<void> cerrarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('usuario_id');
  }
}
