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
        body: jsonEncode({'email': email, 'password': contrasena}),
      ).timeout(const Duration(seconds: 25));

      if (respuesta.statusCode == 200) {
        final Map<String, dynamic> datosJson = jsonDecode(respuesta.body);
        
        if (datosJson.containsKey('token')) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', datosJson['token']);
          if (datosJson.containsKey('datos') && datosJson['datos']['id'] != null) {
            await prefs.setInt('usuario_id', datosJson['datos']['id']);
            if (datosJson['datos']['nombre_usuario'] != null) {
              await prefs.setString('nombre_usuario', datosJson['datos']['nombre_usuario']);
            }
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
        Uri.parse('$_urlBase/registro/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nombre_usuario': nombre_usuario,
          'email': email,
          'password': contrasena,
        }),
      ).timeout(const Duration(seconds: 25));

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
        Uri.parse('$_urlBase/recuperar-contrasena/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      ).timeout(const Duration(seconds: 25));

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

  Future<String?> obtenerToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('auth_token');
    } catch (e) {
      return null;
    }
  }

  Future<int?> obtenerIdUsuario() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt('usuario_id');
    } catch (e) {
      return null;
    }
  }

  Future<String?> obtenerNombreUsuario() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('nombre_usuario');
    } catch (e) {
      return null;
    }
  }

  Future<RespuestaApi<Usuario>> obtenerDatosPropios() async {
    try {
      final id = await obtenerIdUsuario();
      if (id == null) return RespuestaApi(exito: false, mensaje: 'Usuario no logueado');
      return obtenerDatosUsuario(id);
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error: $e');
    }
  }

  Future<RespuestaApi<List<Usuario>>> listarUsuarios() async {
    try {
      final token = await obtenerToken();
      final uri = Uri.parse('$_urlBase/datos/');
      final respuesta = await http.get(
        uri,
        headers: token != null ? {'Authorization': 'Token $token'} : {},
      ).timeout(const Duration(seconds: 25));
      if (respuesta.statusCode == 200) {
        final Map<String, dynamic> datosJson = jsonDecode(respuesta.body);
        final List<dynamic> lista = datosJson['datos'] ?? [];
        final usuarios = lista.map((js) => Usuario.fromJson(js)).toList();
        return RespuestaApi(exito: true, mensaje: 'OK', datos: usuarios);
      }
      return RespuestaApi(exito: false, mensaje: 'Error al listar usuarios');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  Future<RespuestaApi<List<Usuario>>> obtenerRanking() async {
    try {
      final respuesta = await http.get(Uri.parse('$_urlBase/ranking/')).timeout(const Duration(seconds: 25));
      if (respuesta.statusCode == 200) {
        final Map<String, dynamic> datosJson = jsonDecode(respuesta.body);
        final List<dynamic> lista = datosJson['datos'] ?? [];
        final usuarios = lista.map((js) => Usuario.fromJson(js)).toList();
        return RespuestaApi(exito: true, mensaje: 'OK', datos: usuarios);
      }
      return RespuestaApi(exito: false, mensaje: 'Error al obtener el ranking');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  Future<RespuestaApi<Usuario>> obtenerDatosUsuario(int id) async {
    try {
      final respuesta = await http.get(Uri.parse('$_urlBase/datos/$id/')).timeout(const Duration(seconds: 25));
      if (respuesta.statusCode == 200) {
        final Map<String, dynamic> datosJson = jsonDecode(respuesta.body);
        return RespuestaApi.fromJson(
          datosJson,
          transformador: (json) => Usuario.fromJson(json),
        );
      }
      return RespuestaApi(exito: false, mensaje: 'Error al obtener datos del usuario');
    } on Exception catch (e) {
      if (e.toString().contains('TimeoutException')) {
        return RespuestaApi(exito: false, mensaje: 'Tiempo de espera agotado. Por favor, revisa tu conexión.');
      }
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  Future<void> cerrarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
