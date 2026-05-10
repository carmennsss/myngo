import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/respuesta_api.dart';
import '../utils/configuracion.dart';
import 'servicio_usuarios.dart';

// Gestiona todo lo relacionado con denuncias y control de contenido.
// Permite a los usuarios reportar cosas raras y a los admins revisar su comunidad.
class ServicioModeracion {
  // Ruta base del backend
  static const String _urlBase = Configuracion.baseUrl;

  final _servicioUsuarios = ServicioUsuarios();

  // Adjunta el token del usuario para validar que está logueado
  Future<Map<String, String>> _obtenerCabeceras() async {
    final token = await _servicioUsuarios.obtenerToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Token $token',
    };
  }

  // Envía un reporte al backend cuando un usuario denuncia un post o perfil
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
        'comunidad': (comunidadId != null && comunidadId != 0) ? comunidadId : null,
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

  // Trae las estadísticas y reportes pendientes para que el admin pueda revisarlos
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

  // Permite a un administrador marcar un reporte como resuelto o ignorado
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
