import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/respuesta_api.dart';
import '../models/usuario.dart';
import '../utils/configuracion.dart';

/// Servicio encargado de la gestión de usuarios, autenticación y sesiones.
///
/// Proporciona métodos para el inicio de sesión, registro, recuperación de
/// credenciales y persistencia de la sesión en el dispositivo.
class ServicioUsuarios {
  /// URL base para los endpoints relacionados con la gestión de usuarios.
  static const String _urlUsuarios = '${Configuracion.baseUrl}/usuarios';

  /// Genera las cabeceras estándar (JSON + Token) para las peticiones API.
  Future<Map<String, String>> _obtenerCabeceras() async {
    final token = await obtenerToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Token $token',
    };
  }

  /// Realiza la autenticación del usuario en la plataforma.
  ///
  /// Tras un inicio de sesión exitoso, persiste el token y los datos básicos
  /// del usuario en las preferencias compartidas del dispositivo.
  Future<RespuestaApi<Usuario>> iniciarSesion(String correo, String contrasena) async {
    try {
      final respuesta = await http.post(
        Uri.parse('$_urlUsuarios/login/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': correo, 'password': contrasena}),
      ).timeout(const Duration(seconds: 20));

      if (respuesta.body.contains('<!DOCTYPE') || respuesta.body.contains('<html')) {
        return RespuestaApi(
          exito: false,
          mensaje: 'Error del servidor (${respuesta.statusCode}). La respuesta no es válida.',
        );
      }

      final Map<String, dynamic> datosJson = jsonDecode(respuesta.body);

      if (respuesta.statusCode == 200) {
        if (datosJson.containsKey('token')) {
          final preferencias = await SharedPreferences.getInstance();
          await preferencias.setString('auth_token', datosJson['token']);

          if (datosJson['datos'] != null) {
            final datos = datosJson['datos'];
            if (datos['id'] != null) {
              await preferencias.setInt('usuario_id', datos['id']);
            }
            if (datos['nombre_usuario'] != null) {
              await preferencias.setString('nombre_usuario', datos['nombre_usuario']);
            }
          }
        }

        return RespuestaApi.fromJson(
          datosJson,
          transformador: (j) => Usuario.fromJson(j),
        );
      }

      return RespuestaApi(
        exito: false,
        mensaje: datosJson['mensaje'] ?? 'Error en la autenticación (${respuesta.statusCode})',
        errores: datosJson['errores'],
      );
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  /// Registra una nueva cuenta de usuario en el sistema.
  Future<RespuestaApi<Usuario>> registrarse(
      String nombreUsuario, String correo, String contrasena) async {
    try {
      final respuesta = await http.post(
        Uri.parse('$_urlUsuarios/registrar/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nombre_usuario': nombreUsuario,
          'email': correo,
          'password': contrasena,
        }),
      ).timeout(const Duration(seconds: 20));

      final Map<String, dynamic> datosJson = jsonDecode(respuesta.body);

      if (respuesta.statusCode >= 200 && respuesta.statusCode < 300) {
        return RespuestaApi.fromJson(
          datosJson,
          transformador: (j) => Usuario.fromJson(j),
        );
      }

      return RespuestaApi(
        exito: false,
        mensaje: datosJson['mensaje'] ?? 'Error en el registro (${respuesta.statusCode})',
        errores: datosJson['errores'],
      );
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  /// Solicita el restablecimiento de contraseña para el correo proporcionado.
  Future<RespuestaApi> recuperarContrasena(String correo) async {
    try {
      final respuesta = await http.post(
        Uri.parse('$_urlUsuarios/recuperar-password/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': correo}),
      ).timeout(const Duration(seconds: 20));

      final Map<String, dynamic> datosJson = jsonDecode(respuesta.body);
      
      if (respuesta.statusCode == 200) {
        return RespuestaApi.fromJson(datosJson);
      }

      return RespuestaApi(
        exito: false,
        mensaje: datosJson['mensaje'] ?? 'Error al recuperar la contraseña',
      );
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  /// Recupera el token de sesión almacenado localmente.
  Future<String?> obtenerToken() async {
    try {
      final preferencias = await SharedPreferences.getInstance();
      return preferencias.getString('auth_token');
    } catch (_) {
      return null;
    }
  }

  /// Obtiene el identificador numérico del usuario actual.
  Future<int?> obtenerIdUsuario() async {
    try {
      final preferencias = await SharedPreferences.getInstance();
      return preferencias.getInt('usuario_id');
    } catch (_) {
      return null;
    }
  }

  /// Obtiene el nombre de usuario de la sesión actual.
  Future<String?> obtenerNombreUsuario() async {
    try {
      final preferencias = await SharedPreferences.getInstance();
      return preferencias.getString('nombre_usuario');
    } catch (_) {
      return null;
    }
  }

  /// Obtiene la información completa del usuario que ha iniciado sesión.
  Future<RespuestaApi<Usuario>> obtenerDatosPropios() async {
    final id = await obtenerIdUsuario();
    if (id == null) return RespuestaApi(exito: false, mensaje: 'Sesión no activa');
    return obtenerDatosUsuario(id);
  }

  /// Obtiene una lista de todos los usuarios registrados en la plataforma con paginación.
  Future<RespuestaApi<List<Usuario>>> listarUsuarios({int? pagina}) async {
    try {
      final query = pagina != null ? '?page=$pagina' : '';
      final respuesta = await http.get(
        Uri.parse('$_urlUsuarios/datos/$query'),
        headers: await _obtenerCabeceras(),
      ).timeout(const Duration(seconds: 20));

      if (respuesta.statusCode == 200) {
        final Map<String, dynamic> datosJson = jsonDecode(respuesta.body);
        final List<dynamic> lista = datosJson is List ? datosJson : (datosJson['results'] ?? datosJson['datos'] ?? []);
        return RespuestaApi(
          exito: true,
          mensaje: 'Usuarios recuperados',
          datos: lista.map((j) => Usuario.fromJson(j)).toList(),
        );
      }
      return RespuestaApi(exito: false, mensaje: 'Error al listar usuarios');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  /// Obtiene el ranking global de usuarios basado en su reputación.
  Future<RespuestaApi<List<Usuario>>> obtenerRanking() async {
    try {
      final respuesta = await http.get(
        Uri.parse('$_urlUsuarios/ranking/'),
        headers: await _obtenerCabeceras(),
      ).timeout(const Duration(seconds: 20));

      if (respuesta.statusCode == 200) {
        final Map<String, dynamic> datosJson = jsonDecode(respuesta.body);
        final List<dynamic> lista = datosJson['datos'] ?? [];
        return RespuestaApi(
          exito: true,
          mensaje: 'Ranking recuperado',
          datos: lista.map((j) => Usuario.fromJson(j)).toList(),
        );
      }
      return RespuestaApi(exito: false, mensaje: 'Error al obtener ranking');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  /// Obtiene la información detallada de un usuario específico por su ID.
  Future<RespuestaApi<Usuario>> obtenerDatosUsuario(int idUsuario) async {
    try {
      final respuesta = await http.get(
        Uri.parse('$_urlUsuarios/datos/$idUsuario/'),
        headers: await _obtenerCabeceras(),
      ).timeout(const Duration(seconds: 20));

      final Map<String, dynamic> datosJson = jsonDecode(respuesta.body);

      if (respuesta.statusCode == 200) {
        return RespuestaApi.fromJson(
          datosJson,
          transformador: (j) => Usuario.fromJson(j),
        );
      }
      return RespuestaApi(
        exito: false,
        mensaje: datosJson['mensaje'] ?? 'Error al obtener datos',
      );
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  /// Finaliza la sesión actual y limpia los datos locales.
  Future<void> cerrarSesion() async {
    try {
      final preferencias = await SharedPreferences.getInstance();
      await preferencias.clear();
    } catch (_) {}
  }

  /// Actualiza los datos del perfil del usuario (incluyendo avatar, bio, y orden de comunidades).
  Future<RespuestaApi<Usuario>> actualizarPerfil({
    required int perfilId,
    String? biografia,
    List<int>? ordenComunidades,
  }) async {
    try {
      final respuesta = await http.patch(
        Uri.parse('$_urlUsuarios/perfil/editar/'),
        headers: await _obtenerCabeceras(),
        body: jsonEncode({
          'perfil_id': perfilId,
          if (biografia != null) 'biografia': biografia,
          if (ordenComunidades != null) 'orden_comunidades': ordenComunidades,
        }),
      ).timeout(const Duration(seconds: 20));

      final Map<String, dynamic> datosJson = jsonDecode(respuesta.body);

      if (respuesta.statusCode == 200) {
        return RespuestaApi.fromJson(
          datosJson,
          transformador: (j) => Usuario.fromJson(j),
        );
      }
      return RespuestaApi(
        exito: false,
        mensaje: datosJson['mensaje'] ?? 'Error al actualizar perfil',
      );
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  /// Guarda el orden personalizado de las comunidades del usuario.
  Future<RespuestaApi> actualizarOrdenComunidades(int perfilId, List<int> idsOrdenados) async {
    return actualizarPerfil(perfilId: perfilId, ordenComunidades: idsOrdenados);
  }
}
