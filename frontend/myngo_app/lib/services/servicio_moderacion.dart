import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/respuesta_api.dart';
import '../utils/configuracion.dart';
import 'servicio_usuarios.dart';

/// Servicio encargado de la gestión de reportes y la moderación de contenidos.
///
/// Permite a los usuarios denunciar conductas inapropiadas y a los
/// administradores gestionar la resolución de conflictos y el estado de la comunidad.
class ServicioModeracion {
  /// URL base para las peticiones a la API.
  static const String _urlBase = Configuracion.baseUrl;

  final _servicioUsuarios = ServicioUsuarios();

  /// Genera las cabeceras estándar (JSON + Token) para las peticiones.
  Future<Map<String, String>> _obtenerCabeceras() async {
    final token = await _servicioUsuarios.obtenerToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Token $token',
    };
  }

  /// Registra una denuncia sobre una publicación, comentario o imagen.
  Future<RespuestaApi> reportarContenido({
    required String tipoObjeto,
    required int idObjeto,
    required String motivo,
    String? comentario,
    int? comunidadId,
  }) async {
    try {
      final cuerpo = {
        'tipo_objeto': tipoObjeto,
        'objeto_id': idObjeto,
        'motivo': motivo,
        'comentario': comentario,
        'comunidad': comunidadId,
      };

      final respuesta = await http.post(
        Uri.parse('$_urlBase/contenido/reportes/'),
        headers: await _obtenerCabeceras(),
        body: jsonEncode(cuerpo),
      ).timeout(const Duration(seconds: 15));

      if (respuesta.statusCode == 201) {
        return RespuestaApi(exito: true, mensaje: 'Denuncia registrada correctamente');
      }
      return RespuestaApi(exito: false, mensaje: 'Error al enviar la denuncia');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  /// Recupera los datos métricos y de gestión para el panel de administración de una comunidad.
  Future<RespuestaApi<Map<String, dynamic>>> obtenerDashboardAdmin(int comunidadId) async {
    try {
      final respuesta = await http.get(
        Uri.parse('$_urlBase/comunidades/$comunidadId/admin-dashboard/'),
        headers: await _obtenerCabeceras(),
      ).timeout(const Duration(seconds: 20));

      if (respuesta.statusCode == 200) {
        return RespuestaApi(
          exito: true,
          mensaje: 'Panel de control cargado con éxito',
          datos: jsonDecode(respuesta.body),
        );
      }
      return RespuestaApi(exito: false, mensaje: 'No se pudo recuperar la información administrativa');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  /// Finaliza un reporte pendiente estableciendo una resolución oficial.
  Future<RespuestaApi> resolverReporte(int idReporte, String nuevoEstado, {String? mensajeResolucion}) async {
    try {
      final respuesta = await http.post(
        Uri.parse('$_urlBase/contenido/reportes/$idReporte/resolver/'),
        headers: await _obtenerCabeceras(),
        body: jsonEncode({
          'estado': nuevoEstado,
          'mensaje_resolucion': mensajeResolucion,
        }),
      ).timeout(const Duration(seconds: 15));

      if (respuesta.statusCode == 200) {
        return RespuestaApi(exito: true, mensaje: 'Resolución aplicada correctamente');
      }
      return RespuestaApi(exito: false, mensaje: 'Error al procesar la resolución del reporte');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }
}
