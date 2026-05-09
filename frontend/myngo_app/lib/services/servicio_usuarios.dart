import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart' as dio;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
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
        body: jsonEncode({'email': correo.trim(), 'password': contrasena.trim()}),
      ).timeout(const Duration(seconds: 20));

      if (respuesta.body.contains('<!DOCTYPE') || respuesta.body.contains('<html')) {
        debugPrint('[Auth] Error Crítico: El servidor devolvió HTML en lugar de JSON. Status: ${respuesta.statusCode}');
        return RespuestaApi(
          exito: false,
          mensaje: 'Error técnico en el servidor (${respuesta.statusCode}). Por favor, contacta con soporte.',
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
          'nombre_usuario': nombreUsuario.trim(),
          'email': correo.trim(),
          'password': contrasena.trim(),
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

  /// Obtiene una lista de todos los usuarios registrados en la plataforma con paginación y búsqueda.
  Future<RespuestaApi<List<Usuario>>> listarUsuarios({int? pagina, String? busqueda}) async {
    try {
      String query = '';
      if (pagina != null) query += 'page=$pagina';
      if (busqueda != null && busqueda.isNotEmpty) {
        query += (query.isEmpty ? '' : '&') + 'search=$busqueda';
      }
      
      final url = query.isEmpty ? '$_urlUsuarios/datos/' : '$_urlUsuarios/datos/?$query';
      
      final respuesta = await http.get(
        Uri.parse(url),
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

  /// Obtiene la información detallada de un usuario específico por su ID o Nombre de Usuario.
  Future<RespuestaApi<Usuario>> obtenerDatosUsuario(dynamic identifier) async {
    try {
      final respuesta = await http.get(
        Uri.parse('$_urlUsuarios/datos/$identifier/'),
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

  /// Finaliza la sesión actual y limpia los datos locales de forma inmediata.
  Future<void> cerrarSesion() async {
    try {
      final preferencias = await SharedPreferences.getInstance();
      // Borramos de forma agresiva todo rastro de la sesión
      await preferencias.remove('auth_token');
      await preferencias.remove('usuario_id');
      await preferencias.remove('nombre_usuario');
      await preferencias.remove('orden_comunidades_local');
      
      debugPrint('[Auth] Sesión cerrada y SharedPreferences limpiadas.');
    } catch (e) {
      debugPrint('Error al cerrar sesión: $e');
    }
  }

  /// Limpia específicamente el token para forzar un re-login.
  Future<void> limpiarToken() async {
    final preferencias = await SharedPreferences.getInstance();
    await preferencias.remove('auth_token');
  }

  /// Actualiza los datos del perfil del usuario (incluyendo imágenes, bio y estilos).
  Future<RespuestaApi<Usuario>> actualizarPerfil({
    required int perfilId,
    String? biografia,
    List<int>? ordenComunidades,
    Map<String, dynamic>? estiloPost,
    dynamic imagenAvatar, // Puede ser XFile o String (URL/Ruta)
    dynamic imagenFondo,
    dynamic imagenFondoPerfil,
    String? colorTema,
    String? fuentePerfil,
  }) async {
    try {
      final token = await obtenerToken();
      final url = '${Configuracion.baseUrl}/usuarios/perfil/editar/';
      
      final cabeceras = {
        if (token != null) 'Authorization': 'Token $token',
      };

      final dio_client = dio.Dio();
      final datosFormulario = dio.FormData();

      datosFormulario.fields.add(MapEntry('perfil_id', perfilId.toString()));
      if (biografia != null) datosFormulario.fields.add(MapEntry('biografia', biografia));
      if (ordenComunidades != null) {
        datosFormulario.fields.add(MapEntry('orden_comunidades', jsonEncode(ordenComunidades)));
      }
      if (estiloPost != null) {
        datosFormulario.fields.add(MapEntry('estilo_post', jsonEncode(estiloPost)));
      }
      if (colorTema != null) {
        datosFormulario.fields.add(MapEntry('color_tema', colorTema));
      }
      if (fuentePerfil != null) {
        datosFormulario.fields.add(MapEntry('fuente_perfil', fuentePerfil));
      }

      final imagenes = {
        'url_avatar': imagenAvatar,
        'url_fondo': imagenFondo,
        'url_fondo_perfil': imagenFondoPerfil,
      };

      for (var entrada in imagenes.entries) {
        if (entrada.value is XFile) {
          final XFile archivo = entrada.value;
          final bytes = await archivo.readAsBytes();
          final mimeType = lookupMimeType(archivo.name, headerBytes: bytes) ?? 'image/jpeg';
          final typeParts = mimeType.split('/');

          datosFormulario.files.add(MapEntry(
            entrada.key,
            dio.MultipartFile.fromBytes(
              bytes,
              filename: archivo.name,
              contentType: MediaType(typeParts[0], typeParts[1]),
            ),
          ));
        } else if (entrada.value is String && entrada.value.isNotEmpty) {
          datosFormulario.fields.add(MapEntry(entrada.key, entrada.value));
        }
      }

      final respuesta = await dio_client.patch(
        url,
        data: datosFormulario,
        options: dio.Options(headers: cabeceras),
      );

      if (respuesta.statusCode == 200) {
        final datosJson = respuesta.data is String ? jsonDecode(respuesta.data) : respuesta.data;
        return RespuestaApi.fromJson(
          datosJson,
          transformador: (j) => Usuario.fromJson(j),
        );
      }
      return RespuestaApi(exito: false, mensaje: 'Error al actualizar perfil');
    } catch (e) {
      String msg = 'Error de conexión: $e';
      if (e is dio.DioException && e.response != null) {
        msg = e.response?.data?['mensaje'] ?? e.response?.data?['error'] ?? msg;
      }
      return RespuestaApi(exito: false, mensaje: msg);
    }
  }

  /// Guarda el orden personalizado de las comunidades del usuario.
  Future<RespuestaApi> actualizarOrdenComunidades(int perfilId, List<int> idsOrdenados) async {
    return actualizarPerfil(perfilId: perfilId, ordenComunidades: idsOrdenados);
  }
}
