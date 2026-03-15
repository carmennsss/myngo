import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/respuesta_api.dart';
import '../models/usuario.dart';

/// Clase de servicio que encapsula la lógica de comunicación con la API de usuarios.
/// 
/// Centraliza todas las llamadas HTTP relacionadas con la gestión de usuarios,
/// abstrayendo la implementación de la red de la interfaz de usuario.
class ServicioUsuarios {
  /// URL base para los endpoints relacionados con usuarios.
  static const String _urlBase = 'http://localhost:8000/usuarios';

  /// Realiza una solicitud de autenticación al servidor.
  ///
  /// Envía un [email] y una [contrasena] en el cuerpo de una petición POST.
  /// Devuelve una instancia de [RespuestaApi<Usuario>] que contiene el resultado 
  /// de la operación, incluyendo los datos del usuario si el login es exitoso.
  Future<RespuestaApi<Usuario>> iniciarSesion(String email, String contrasena) async {
    try {
      final respuesta = await http.post(
        Uri.parse('$_urlBase/login/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'contrasena': contrasena,
        }),
      );

      final Map<String, dynamic> datosJson = jsonDecode(respuesta.body);

      if (respuesta.statusCode == 200) {
        return RespuestaApi.fromJson(
          datosJson,
          transformador: (json) => Usuario.fromJson(json),
        );
      } else {
        return RespuestaApi(
          exito: false,
          mensaje: datosJson['mensaje'] ?? 'Error en la autenticación',
          errores: datosJson['errores'],
        );
      }
    } catch (e) {
      return RespuestaApi(
        exito: false,
        mensaje: 'Error de conexión con el servidor: $e',
      );
    }
  }
  Future<RespuestaApi<Usuario>> registrarse(String nombre_usuario,String email, String contrasena) async {
    try {
      final respuesta = await http.post(
        Uri.parse('$_urlBase/registrar/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nombre_usuario':nombre_usuario,
          'email': email,
          'contrasena': contrasena,
        }),
      );

      final Map<String, dynamic> datosJson = jsonDecode(respuesta.body);

      if (respuesta.statusCode >= 200 && respuesta.statusCode < 300) {
        return RespuestaApi.fromJson(
          datosJson,
          transformador: (json) => Usuario.fromJson(json),
        );
      } else {
        return RespuestaApi(
          exito: false,
          mensaje: datosJson['mensaje'] ?? 'Error en el registro',
          errores: datosJson['errores'],
        );
      }
    } catch (e) {
      return RespuestaApi(
        exito: false,
        mensaje: 'Error de conexión con el servidor: $e',
      );
    }
  }

  /// Solicita el restablecimiento de la contraseña enviando un correo al usuario.
  /// 
  /// Recibe el [email] del usuario y devuelve una [RespuestaApi] indicando 
  /// si el correo de recuperación fue enviado con éxito.
  Future<RespuestaApi> recuperarContrasena(String email) async {
    try {
      final respuesta = await http.post(
        Uri.parse('$_urlBase/recuperar-password/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      final Map<String, dynamic> datosJson = jsonDecode(respuesta.body);

      return RespuestaApi.fromJson(datosJson);
    } catch (e) {
      return RespuestaApi(
        exito: false,
        mensaje: 'Error de conexión con el servidor: $e',
      );
    }
  }
}
