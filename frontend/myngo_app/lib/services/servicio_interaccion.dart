import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:myngo_app/services/servicio_usuarios.dart';
import '../models/respuesta_api.dart';
import '../utils/configuracion.dart';
import '../models/comentario.dart';

class ServicioInteraccion {
  final String _urlBase = Configuracion.baseUrl;
  final _servicioUsuarios = ServicioUsuarios();

  Future<RespuestaApi<Map<String, dynamic>>> toggleLike(int publicacionId) async {
    try {
      final token = await _servicioUsuarios.obtenerToken();
      final response = await http.post(
        Uri.parse('$_urlBase/contenido/publicaciones/$publicacionId/like/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return RespuestaApi(
          exito: true, 
          mensaje: 'Éxito', 
          datos: jsonDecode(response.body)
        );
      }
      
      String errorMsg = 'Error al procesar el like';
      try {
        final Map<String, dynamic> body = jsonDecode(response.body);
        if (body.containsKey('error')) errorMsg = body['error'];
      } catch (_) {}
      
      return RespuestaApi(exito: false, mensaje: errorMsg);
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  Future<RespuestaApi<List<Comentario>>> obtenerComentarios(int publicacionId, {int limit = 10, int offset = 0}) async {
    try {
      final token = await _servicioUsuarios.obtenerToken();
      final url = '$_urlBase/contenido/publicaciones/$publicacionId/comentarios/?limit=$limit&offset=$offset';
      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Token $token'},
      );

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        // Manejar tanto lista simple como respuesta paginada de Django (con 'results')
        final List dynamicList = (decoded is Map) ? (decoded['results'] ?? []) : (decoded is List ? decoded : []);
        final comentarios = dynamicList.map((j) => Comentario.fromJson(j)).toList();
        return RespuestaApi(exito: true, mensaje: 'Comentarios cargados', datos: comentarios);
      }
      return RespuestaApi(exito: false, mensaje: 'Error al cargar comentarios', datos: []);
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e', datos: []);
    }
  }

  Future<RespuestaApi<Comentario>> crearComentario(int publicacionId, String contenido) async {
    try {
      final token = await _servicioUsuarios.obtenerToken();
      final response = await http.post(
        Uri.parse('$_urlBase/contenido/publicaciones/$publicacionId/comentarios/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'contenido': contenido}),
      );

      if (response.statusCode == 201) {
        return RespuestaApi(
          exito: true, 
          mensaje: 'Comentario enviado', 
          datos: Comentario.fromJson(jsonDecode(response.body))
        );
      }
      
      String errorMsg = 'Error al enviar comentario';
      try {
        final Map<String, dynamic> body = jsonDecode(response.body);
        if (body.containsKey('error') || body.containsKey('detail')) {
            errorMsg = body['error'] ?? body['detail'];
        }
      } catch (_) {}
      
      return RespuestaApi(exito: false, mensaje: errorMsg);
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }
}
