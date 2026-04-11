import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import '../models/respuesta_api.dart';
import '../models/catalogo_mejoras.dart';
import './servicio_usuarios.dart';

/// Servicio para gestionar las votaciones y el ranking.
class ServicioMejoras {
  static const String _urlBase = 'http://127.0.0.1:8000/mejoras';

  /// Envía un voto a un usuario o comunidad.
  Future<RespuestaApi> votar({int? receptorUsuarioId, int? receptorComunidadId, required int estrellas}) async {
    try {
      final token = await ServicioUsuarios().obtenerToken();

      final respuesta = await http.post(
        Uri.parse('$_urlBase/votar/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
        body: jsonEncode({
          if (receptorUsuarioId != null) 'receptor_usuario': receptorUsuarioId,
          if (receptorComunidadId != null) 'receptor_comunidad': receptorComunidadId,
          'estrellas': estrellas,
        }),
      );

      final Map<String, dynamic> datosJson = jsonDecode(respuesta.body);
      
      if (respuesta.statusCode == 200 || respuesta.statusCode == 201) {
        return RespuestaApi(
          exito: true, 
          mensaje: datosJson['mensaje'] ?? 'Voto registrado',
          datos: datosJson['estrellas']
        );
      } else {
        return RespuestaApi(
          exito: false, 
          mensaje: datosJson['error'] ?? 'Error al votar'
        );
      }
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  /// Obtiene el estado del voto actual y el tiempo para el próximo bono.
  Future<RespuestaApi<Map<String, dynamic>>> obtenerEstadoVoto({int? receptorUsuarioId, int? receptorComunidadId}) async {
    try {
      final token = await ServicioUsuarios().obtenerToken();

      String params = receptorUsuarioId != null ? 'receptor_usuario=$receptorUsuarioId' : 'receptor_comunidad=$receptorComunidadId';
      
      final respuesta = await http.get(
        Uri.parse('$_urlBase/votar/?$params'),
        headers: {
          'Authorization': 'Token $token',
        },
      );

      if (respuesta.statusCode == 200) {
        final Map<String, dynamic> datosJson = jsonDecode(respuesta.body);
        return RespuestaApi(exito: true, mensaje: 'OK', datos: datosJson);
      }
      return RespuestaApi(exito: false, mensaje: 'Error al obtener estado');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  /// Consulta el ranking de usuarios.
  Future<RespuestaApi<List<dynamic>>> obtenerRankingUsuarios() async {
    try {
      final respuesta = await http.get(Uri.parse('$_urlBase/ranking/usuarios/'));
      if (respuesta.statusCode == 200) {
        final List<dynamic> datos = jsonDecode(respuesta.body);
        return RespuestaApi(exito: true, mensaje: 'OK', datos: datos);
      }
      return RespuestaApi(exito: false, mensaje: 'Error al obtener ranking');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  /// Obtiene las mejoras globales
  Future<RespuestaApi<List<CatalogoMejoras>>> obtenerMejorasGlobales() async {
    try {
      final token = await ServicioUsuarios().obtenerToken();
      final respuesta = await http.get(
        Uri.parse('$_urlBase/tienda/global/'),
        headers: {'Authorization': 'Token $token'},
      );

      if (respuesta.statusCode == 200) {
        final List<dynamic> datos = jsonDecode(utf8.decode(respuesta.bodyBytes));
        final mejoras = datos.map((e) => CatalogoMejoras.fromJson(e)).toList();
        return RespuestaApi(exito: true, mensaje: 'OK', datos: mejoras);
      }
      return RespuestaApi(exito: false, mensaje: 'Error al obtener catálogo global');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  /// Obtiene las mejoras de una comunidad
  Future<RespuestaApi<List<CatalogoMejoras>>> obtenerMejorasComunidad(int comunidadId) async {
    try {
      final token = await ServicioUsuarios().obtenerToken();
      final respuesta = await http.get(
        Uri.parse('$_urlBase/tienda/comunidad/$comunidadId/'),
        headers: {'Authorization': 'Token $token'},
      );

      if (respuesta.statusCode == 200) {
        final List<dynamic> datos = jsonDecode(utf8.decode(respuesta.bodyBytes));
        final mejoras = datos.map((e) => CatalogoMejoras.fromJson(e)).toList();
        return RespuestaApi(exito: true, mensaje: 'OK', datos: mejoras);
      }
      return RespuestaApi(exito: false, mensaje: 'Error al obtener catálogo de comunidad');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  /// Envía una propuesta de diseño (Multipart para imagen)
  Future<RespuestaApi> enviarPeticionMejora({
    required int comunidadId,
    required String nombre,
    required String tipo,
    required String filePath,
    Uint8List? bytes,
    int precioSugerido = 0,
  }) async {
    try {
      final token = await ServicioUsuarios().obtenerToken();
      final url = Uri.parse('$_urlBase/tienda/peticiones/crear/');
      
      var request = http.MultipartRequest('POST', url);
      request.headers['Authorization'] = 'Token $token';
      request.fields['comunidad'] = comunidadId.toString();
      request.fields['nombre'] = nombre;
      request.fields['tipo'] = tipo;
      request.fields['precio_sugerido'] = precioSugerido.toString();
      
      if (kIsWeb && bytes != null) {
        request.files.add(http.MultipartFile.fromBytes(
          'url_recurso', 
          bytes,
          filename: 'upload.png'
        ));
      } else {
        request.files.add(await http.MultipartFile.fromPath('url_recurso', filePath));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        return RespuestaApi(exito: true, mensaje: 'Propuesta enviada con éxito');
      } else {
        final error = jsonDecode(response.body);
        return RespuestaApi(exito: false, mensaje: error['error'] ?? 'Error al enviar propuesta');
      }
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  /// Obtiene peticiones pendientes para moderar
  Future<RespuestaApi<List<dynamic>>> obtenerPeticionesModeracion(int comunidadId) async {
    try {
      final token = await ServicioUsuarios().obtenerToken();
      final respuesta = await http.get(
        Uri.parse('$_urlBase/tienda/peticiones/moderacion/$comunidadId/'),
        headers: {'Authorization': 'Token $token'},
      );

      if (respuesta.statusCode == 200) {
        final List<dynamic> datos = jsonDecode(utf8.decode(respuesta.bodyBytes));
        return RespuestaApi(exito: true, mensaje: 'OK', datos: datos);
      }
      return RespuestaApi(exito: false, mensaje: 'Error al obtener peticiones');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  /// Modera una petición
  Future<RespuestaApi> moderarPeticion(int pk, String estado, int precio) async {
    try {
      final token = await ServicioUsuarios().obtenerToken();
      final respuesta = await http.post(
        Uri.parse('$_urlBase/tienda/peticiones/$pk/moderar/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
        body: jsonEncode({'estado': estado, 'precio': precio}),
      );

      if (respuesta.statusCode == 200) {
        return RespuestaApi(exito: true, mensaje: 'Acción realizada correctamente');
      }
      return RespuestaApi(exito: false, mensaje: 'Error al moderar');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  /// Compra una mejora del catálogo
  Future<RespuestaApi> comprarMejora(int mejoraId) async {
    try {
      final token = await ServicioUsuarios().obtenerToken();
      final respuesta = await http.post(
        Uri.parse('$_urlBase/tienda/comprar/$mejoraId/'),
        headers: {'Authorization': 'Token $token'},
      );

      final datos = jsonDecode(respuesta.body);
      if (respuesta.statusCode == 200) {
        return RespuestaApi(exito: true, mensaje: datos['mensaje'], datos: datos['puntos_restantes']);
      }
      return RespuestaApi(exito: false, mensaje: datos['error'] ?? 'Error en la compra');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  /// Obtiene los elementos del catálogo según el tipo
  Future<RespuestaApi<List<CatalogoMejoras>>> obtenerMejorasCatalogo(String tipo) async {
    try {
      final token = await ServicioUsuarios().obtenerToken();
      final respuesta = await http.get(
        Uri.parse('$_urlBase/tienda/$tipo/'),
        headers: {
          'Authorization': 'Token $token',
        },
      );

      if (respuesta.statusCode == 200) {
        final List<dynamic> datos = jsonDecode(utf8.decode(respuesta.bodyBytes));
        final beneficios = datos.map((e) => CatalogoMejoras.fromJson(e)).toList();
        return RespuestaApi(exito: true, mensaje: 'OK', datos: beneficios);
      }
      return RespuestaApi(exito: false, mensaje: 'Error al obtener catálogo');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  /// Obtiene todo el catálogo de una comunidad (para gestión de admin)
  Future<RespuestaApi<List<CatalogoMejoras>>> obtenerCatalogoGestion(int comunidadId) async {
    try {
      final token = await ServicioUsuarios().obtenerToken();
      final respuesta = await http.get(
        Uri.parse('$_urlBase/tienda/gestion/$comunidadId/'),
        headers: {'Authorization': 'Token $token'},
      );

      if (respuesta.statusCode == 200) {
        final List<dynamic> datos = jsonDecode(utf8.decode(respuesta.bodyBytes));
        final mejoras = datos.map((e) => CatalogoMejoras.fromJson(e)).toList();
        return RespuestaApi(exito: true, mensaje: 'OK', datos: mejoras);
      }
      return RespuestaApi(exito: false, mensaje: 'Error al obtener catálogo de gestión');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  /// Actualiza el estado o precio de un item del catálogo
  Future<RespuestaApi> actualizarItemCatalogo(int comunidadId, int itemId, {bool? estaActivo, int? precio}) async {
    try {
      final token = await ServicioUsuarios().obtenerToken();
      final respuesta = await http.patch(
        Uri.parse('$_urlBase/tienda/gestion/$comunidadId/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
        body: jsonEncode({
          'item_id': itemId,
          if (estaActivo != null) 'esta_activo': estaActivo,
          if (precio != null) 'precio': precio,
        }),
      );

      final datos = jsonDecode(respuesta.body);
      if (respuesta.statusCode == 200) {
        return RespuestaApi(exito: true, mensaje: datos['mensaje']);
      }
      return RespuestaApi(exito: false, mensaje: datos['error'] ?? 'Error al actualizar item');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }
}
