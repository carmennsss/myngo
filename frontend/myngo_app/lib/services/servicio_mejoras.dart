import 'dart:convert';
import 'package:http/http.dart' as http;
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

  /// Obtiene los elementos del catálogo según el tipo
  Future<RespuestaApi<List<CatalogoMejoras>>> obtenerMejorasCatalogo(String tipo) async {
    try {
      final token = await ServicioUsuarios().obtenerToken();
      final respuesta = await http.get(
        Uri.parse('$_urlBase/tienda/$tipo'),
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
}
