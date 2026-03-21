import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/respuesta_api.dart';
import '../models/usuario.dart';
import 'servicio_usuarios.dart';

class ServicioPerfiles {
  // URLs para que crees los endpoints homólogos en tu backend
  static const String _urlBase = 'http://127.0.0.1:8000/usuarios/perfiles';
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
        final Map<String, dynamic> datosJson = jsonDecode(respuesta.body);
        final List<dynamic> listaJson = datosJson['datos'] ?? [];
        return RespuestaApi(
          exito: true,
          mensaje: datosJson['mensaje'] ?? 'Perfiles cargados',
          datos: listaJson.map((j) => Usuario.fromJson(j)).toList(),
        );
      }
      return RespuestaApi(
        exito: false, 
        mensaje: 'Error al cargar perfiles: ${respuesta.statusCode}'
      );
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Aún no existe el endpoint en tu servidor: $e');
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
      return RespuestaApi(exito: false, mensaje: 'Aún no existe el endpoint en tu servidor: $e');
    }
  }
}
