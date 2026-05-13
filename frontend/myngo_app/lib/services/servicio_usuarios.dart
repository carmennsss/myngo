/**
 * @author Carmen Tamayo Doña
 * @author Ainhoa Gomez Toro
 * @version 1.0
 * @date 2026-05-14
 */

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
import 'api_base.dart';

// Se encarga de gestionar a los usuarios y sus sesiones.
// Lo usamos para hacer login, registrar cuentas, y guardar el token para no pedir la contraseña todo el rato.
class ServicioUsuarios {
  late final http.Client _client;
  late final dio.Dio _dio;
  ServicioUsuarios({http.Client? httpClient, dio.Dio? dioClient}) {
    _client = httpClient ?? http.Client();
    _dio = dioClient ?? dio.Dio();
    ApiBase.configurarDio(_dio);
  }
  http.Client get client => _client;
  dio.Dio get dioClient => _dio;

  /// URL base para los endpoints relacionados con la gestión de usuarios.
  // URL donde el backend escucha las peticiones de usuarios
  static const String _urlUsuarios = '${Configuracion.baseUrl}/usuarios';

  // Prepara la "llave" (token) para que el servidor nos deje pasar
  Future<Map<String, String>> _obtenerCabeceras() async {
    final token = await obtenerToken();
    return ApiBase.obtenerHeaders(token: token);
  }

  // Intenta hacer login con email y contraseña, y si va bien, guarda el token en el móvil
  Future<RespuestaApi<Usuario>> iniciarSesion(String correo, String contrasena) async {
    try {
      final respuesta = await client.post(
        Uri.parse('$_urlUsuarios/login/'),
        headers: ApiBase.obtenerHeaders(),
        body: jsonEncode({'email': correo.trim(), 'password': contrasena.trim()}),
      ).timeout(const Duration(seconds: 20));

      if (respuesta.body.contains('<!DOCTYPE') || respuesta.body.contains('<html')) {

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

  // Crea una cuenta nueva
  Future<RespuestaApi<Usuario>> registrarse(
      String nombreUsuario, String correo, String contrasena) async {
    try {
      final respuesta = await client.post(
        Uri.parse('$_urlUsuarios/registrar/'),
        headers: ApiBase.obtenerHeaders(),
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
      final respuesta = await client.post(
        Uri.parse('$_urlUsuarios/recuperar-password/'),
        headers: ApiBase.obtenerHeaders(),
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

  /// Confirma el registro de un usuario mediante el token recibido por email.
  Future<RespuestaApi> confirmarRegistro(String token) async {
    try {
      final respuesta = await client.get(
        Uri.parse('$_urlUsuarios/confirmar/$token/'),
        headers: ApiBase.obtenerHeaders(),
      ).timeout(const Duration(seconds: 20));

      final Map<String, dynamic> datosJson = jsonDecode(respuesta.body);
      
      if (respuesta.statusCode >= 200 && respuesta.statusCode < 300) {
        return RespuestaApi.fromJson(datosJson);
      }
      return RespuestaApi(
        exito: false, 
        mensaje: datosJson['mensaje'] ?? 'Error al activar la cuenta',
      );
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  /// Confirma la recuperación de contraseña y obtiene la nueva generada.
  Future<RespuestaApi<String>> confirmarRecuperacion(String token) async {
    try {
      final respuesta = await client.get(
        Uri.parse('$_urlUsuarios/recuperar-password/confirmar/$token/'),
        headers: ApiBase.obtenerHeaders(),
      ).timeout(const Duration(seconds: 20));

      final Map<String, dynamic> datosJson = jsonDecode(respuesta.body);
      
      if (respuesta.statusCode == 200) {
        return RespuestaApi(
          exito: true, 
          mensaje: datosJson['mensaje'],
          datos: datosJson['nueva_password'],
        );
      }
      return RespuestaApi(exito: false, mensaje: datosJson['mensaje'] ?? 'Error al confirmar recuperación');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  // Lee el token guardado en el almacenamiento del móvil
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

  // Pide al servidor toda la info del usuario que tiene la sesión iniciada
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
      
      final respuesta = await client.get(
        Uri.parse(url),
        headers: await _obtenerCabeceras(),
      ).timeout(const Duration(seconds: 20));

      if (respuesta.statusCode == 200) {
        final dynamic datosJson = jsonDecode(respuesta.body);
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
      final respuesta = await client.get(
        Uri.parse('$_urlUsuarios/ranking/'),
        headers: await _obtenerCabeceras(),
      ).timeout(const Duration(seconds: 20));

      if (respuesta.statusCode == 200) {
        final dynamic datosJson = jsonDecode(respuesta.body);
        final List<dynamic> lista = datosJson is List ? datosJson : (datosJson['datos'] ?? datosJson['results'] ?? []);
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

  /// Obtiene la lista de seguidores de un usuario.
  Future<RespuestaApi<List<Usuario>>> obtenerSeguidores(int usuarioId) async {
    try {
      final respuesta = await client.get(
        Uri.parse('$_urlUsuarios/seguidores/$usuarioId/'),
        headers: await _obtenerCabeceras(),
      ).timeout(const Duration(seconds: 20));

      if (respuesta.statusCode == 200) {
        final dynamic datosJson = jsonDecode(respuesta.body);
        final List<dynamic> lista = datosJson is List ? datosJson : (datosJson['results'] ?? datosJson['datos'] ?? []);
        return RespuestaApi(
          exito: true,
          mensaje: 'Seguidores recuperados',
          datos: lista.map((j) => Usuario.fromJson(j)).toList(),
        );
      }
      return RespuestaApi(exito: false, mensaje: 'Error al obtener seguidores');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  /// Obtiene la lista de usuarios seguidos por un usuario.
  Future<RespuestaApi<List<Usuario>>> obtenerSeguidos(int usuarioId) async {
    try {
      final respuesta = await client.get(
        Uri.parse('$_urlUsuarios/seguidos/$usuarioId/'),
        headers: await _obtenerCabeceras(),
      ).timeout(const Duration(seconds: 20));

      if (respuesta.statusCode == 200) {
        final dynamic datosJson = jsonDecode(respuesta.body);
        final List<dynamic> lista = datosJson is List ? datosJson : (datosJson['results'] ?? datosJson['datos'] ?? []);
        return RespuestaApi(
          exito: true,
          mensaje: 'Seguidos recuperados',
          datos: lista.map((j) => Usuario.fromJson(j)).toList(),
        );
      }
      return RespuestaApi(exito: false, mensaje: 'Error al obtener seguidos');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  /// Obtiene la información detallada de un usuario específico por su ID o Nombre de Usuario.
  Future<RespuestaApi<Usuario>> obtenerDatosUsuario(dynamic identifier) async {
    try {
      final respuesta = await client.get(
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

  // Cierra la sesión y borra el token del móvil
  Future<void> cerrarSesion() async {
    try {
      final preferencias = await SharedPreferences.getInstance();

      await preferencias.remove('auth_token');
      await preferencias.remove('usuario_id');
      await preferencias.remove('nombre_usuario');
      await preferencias.remove('orden_comunidades_local');
      
      // Limpiar cookies si estamos en web (opcional pero recomendado si el backend las usa)
      // En Flutter nativo no es necesario, pero en web el http.Client puede tener estado
      

    } catch (e) {

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
    dynamic imagenAvatar,
    dynamic imagenFondo,
    dynamic imagenFondoPerfil,
    String? colorTema,
    String? fuentePerfil,
    bool? esPublico,
  }) async {
    try {
      final token = await obtenerToken();
      final url = '${Configuracion.baseUrl}/usuarios/perfil/editar/';
      
      final cabeceras = {
        if (token != null) 'Authorization': 'Token $token',
      };

      final dio_client = dioClient;
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
      if (esPublico != null) {
        datosFormulario.fields.add(MapEntry('es_publico', esPublico.toString()));
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

  /// Actualiza el nombre de usuario de la cuenta actual.
  Future<RespuestaApi> actualizarNombreUsuario(int id, String nuevoNombre) async {
    try {
      final respuesta = await http.put(
        Uri.parse('$_urlUsuarios/actualizar_usuario/'),
        headers: await _obtenerCabeceras(),
        body: jsonEncode({
          'id': id,
          'nombre_usuario': nuevoNombre.trim(),
        }),
      ).timeout(const Duration(seconds: 20));

      final Map<String, dynamic> datosJson = jsonDecode(respuesta.body);
      
      if (respuesta.statusCode == 200) {
        final preferencias = await SharedPreferences.getInstance();
        await preferencias.setString('nombre_usuario', nuevoNombre.trim());
        return RespuestaApi.fromJson(datosJson);
      }
      
      return RespuestaApi(
        exito: false,
        mensaje: datosJson['mensaje'] ?? 'El nombre de usuario ya está en uso o es inválido',
        errores: datosJson['errores'],
      );
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  /// Cambia la contraseña del usuario actual.
  Future<RespuestaApi> cambiarPassword(String nuevaPassword) async {
    try {
      final respuesta = await http.post(
        Uri.parse('$_urlUsuarios/configuracion/cambiar-password/'),
        headers: await _obtenerCabeceras(),
        body: jsonEncode({'nueva_password': nuevaPassword.trim()}),
      ).timeout(const Duration(seconds: 20));

      final Map<String, dynamic> datosJson = jsonDecode(respuesta.body);
      
      if (respuesta.statusCode == 200) {
        return RespuestaApi.fromJson(datosJson);
      }
      return RespuestaApi(
        exito: false,
        mensaje: datosJson['mensaje'] ?? 'Error al cambiar contraseña',
      );
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  /// Elimina la cuenta del usuario actual.
  Future<RespuestaApi> eliminarCuenta() async {
    try {
      final respuesta = await http.delete(
        Uri.parse('$_urlUsuarios/configuracion/eliminar-cuenta/'),
        headers: await _obtenerCabeceras(),
      ).timeout(const Duration(seconds: 20));

      final Map<String, dynamic> datosJson = jsonDecode(respuesta.body);
      
      if (respuesta.statusCode == 200) {
        await cerrarSesion();
        return RespuestaApi.fromJson(datosJson);
      }
      return RespuestaApi(
        exito: false,
        mensaje: datosJson['mensaje'] ?? 'Error al eliminar cuenta',
      );
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }
}
