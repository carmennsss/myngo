import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:myngo_app/services/servicio_usuarios.dart';
import '../models/respuesta_api.dart';
import '../utils/configuracion.dart';

class ServicioModeracion {
  final String _urlBase = Configuracion.baseUrl;
  final _servicioUsuarios = ServicioUsuarios();

  Future<RespuestaApi> reportarContenido({
    required String tipoObjeto,
    required int objetoId,
    required String motivo,
    String? comentario,
    int? comunidadId,
  }) async {
    try {
      final token = await _servicioUsuarios.obtenerToken();
      final body = {
        'tipo_objeto': tipoObjeto,
        'objeto_id': objetoId,
        'motivo': motivo,
        'comentario': comentario,
        'comunidad': comunidadId,
      };

      final response = await http.post(
        Uri.parse('$_urlBase/contenido/reportes/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 201) {
        return RespuestaApi(exito: true, mensaje: 'Reporte enviado correctamente');
      }
      return RespuestaApi(exito: false, mensaje: 'Error al enviar el reporte');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  Future<RespuestaApi<Map<String, dynamic>>> obtenerDashboardAdmin(int comunidadId) async {
    try {
      final token = await _servicioUsuarios.obtenerToken();
      final response = await http.get(
        Uri.parse('$_urlBase/comunidades/$comunidadId/admin-dashboard/'),
        headers: {'Authorization': 'Token $token'},
      );

      if (response.statusCode == 200) {
        return RespuestaApi(
          exito: true, 
          mensaje: 'Dashboard cargado con éxito',
          datos: jsonDecode(response.body),
        );
      }
      return RespuestaApi(exito: false, mensaje: 'No se pudo cargar el panel de administrador');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  Future<RespuestaApi> resolverReporte(int reporteId, String estado, {String? mensaje}) async {
    try {
      final token = await _servicioUsuarios.obtenerToken();
      final response = await http.post(
        Uri.parse('$_urlBase/contenido/reportes/$reporteId/resolver/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'estado': estado,
          'mensaje_resolucion': mensaje,
        }),
      );

      if (response.statusCode == 200) {
        return RespuestaApi(exito: true, mensaje: 'Reporte resuelto');
      }
      return RespuestaApi(exito: false, mensaje: 'Error al resolver el reporte');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }
}
