import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import '../models/catalogo_mejoras.dart';
import '../models/respuesta_api.dart';
import '../utils/configuracion.dart';
import './servicio_usuarios.dart';

/// Servicio encargado de gestionar el sistema de puntos, reputación y la tienda de cosméticos.
///
/// Administra las votaciones entre usuarios/comunidades, el catálogo de mejoras
/// visuales (marcos, fondos, estilos) y el flujo de propuestas de nuevos artículos.
class ServicioMejoras {
  /// URL base para los endpoints del módulo de mejoras y reputación.
  static const String _urlMejoras = '${Configuracion.baseUrl}/mejoras';

  final _servicioUsuarios = ServicioUsuarios();

  /// Genera las cabeceras estándar (JSON + Token) para las peticiones API.
  Future<Map<String, String>> _obtenerCabeceras() async {
    final token = await _servicioUsuarios.obtenerToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Token $token',
    };
  }

  /// Registra una valoración de estrellas para un usuario o una comunidad.
  Future<RespuestaApi> votar({
    int? idReceptorUsuario,
    int? idReceptorComunidad,
    required int cantidadEstrellas,
  }) async {
    try {
      final respuesta = await http.post(
        Uri.parse('$_urlMejoras/votar/'),
        headers: await _obtenerCabeceras(),
        body: jsonEncode({
          if (idReceptorUsuario != null) 'receptor_usuario': idReceptorUsuario,
          if (idReceptorComunidad != null) 'receptor_comunidad': idReceptorComunidad,
          'estrellas': cantidadEstrellas,
        }),
      ).timeout(const Duration(seconds: 25));

      final Map<String, dynamic> datosJson = jsonDecode(respuesta.body);

      if (respuesta.statusCode == 200 || respuesta.statusCode == 201) {
        return RespuestaApi(
          exito: true,
          mensaje: datosJson['mensaje'] ?? '¡Voto registrado!',
          datos: datosJson['nueva_media'],
        );
      }
      return RespuestaApi(exito: false, mensaje: datosJson['error'] ?? 'Error al procesar el voto');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  /// Recupera el estado actual de la valoración y el tiempo de espera (cooldown) restante.
  Future<RespuestaApi<Map<String, dynamic>>> obtenerEstadoVoto({
    int? idReceptorUsuario,
    int? idReceptorComunidad,
  }) async {
    try {
      final parametros = idReceptorUsuario != null
          ? 'receptor_usuario=$idReceptorUsuario'
          : 'receptor_comunidad=$idReceptorComunidad';

      final respuesta = await http.get(
        Uri.parse('$_urlMejoras/votar/?$parametros'),
        headers: await _obtenerCabeceras(),
      ).timeout(const Duration(seconds: 15));

      if (respuesta.statusCode == 200) {
        final Map<String, dynamic> datosJson = jsonDecode(respuesta.body);
        return RespuestaApi(exito: true, mensaje: 'Estado recuperado', datos: datosJson);
      }
      return RespuestaApi(exito: false, mensaje: 'Error al obtener estado de votación');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  /// Elimina un voto registrado hoy para un receptor.
  Future<RespuestaApi> eliminarVoto({
    int? idReceptorUsuario,
    int? idReceptorComunidad,
  }) async {
    try {
      final parametros = idReceptorUsuario != null
          ? 'receptor_usuario=$idReceptorUsuario'
          : 'receptor_comunidad=$idReceptorComunidad';

      final respuesta = await http.delete(
        Uri.parse('$_urlMejoras/votar/?$parametros'),
        headers: await _obtenerCabeceras(),
      ).timeout(const Duration(seconds: 15));

      final Map<String, dynamic> datosJson = jsonDecode(respuesta.body);

      if (respuesta.statusCode == 200) {
        return RespuestaApi(
          exito: true,
          mensaje: datosJson['mensaje'] ?? 'Voto eliminado',
          datos: datosJson['nueva_media'],
        );
      }
      return RespuestaApi(exito: false, mensaje: datosJson['error'] ?? 'Error al eliminar el voto');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  /// Obtiene la lista de artículos cosméticos disponibles en la tienda global.
  Future<RespuestaApi<List<CatalogoMejoras>>> obtenerMejorasGlobales() async {
    try {
      final respuesta = await http.get(
        Uri.parse('$_urlMejoras/tienda/global/'),
        headers: await _obtenerCabeceras(),
      ).timeout(const Duration(seconds: 20));

      if (respuesta.statusCode == 200) {
        final List<dynamic> datosJson = jsonDecode(utf8.decode(respuesta.bodyBytes));
        final listaMejoras = datosJson.map((e) => CatalogoMejoras.fromJson(e)).toList();
        return RespuestaApi(exito: true, mensaje: 'Catálogo global cargado', datos: listaMejoras);
      }
      return RespuestaApi(exito: false, mensaje: 'No se pudo cargar la tienda global');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  /// Obtiene los artículos cosméticos exclusivos de una comunidad específica.
  Future<RespuestaApi<List<CatalogoMejoras>>> obtenerMejorasComunidad(int idComunidad) async {
    try {
      final respuesta = await http.get(
        Uri.parse('$_urlMejoras/tienda/comunidad/$idComunidad/'),
        headers: await _obtenerCabeceras(),
      ).timeout(const Duration(seconds: 20));

      if (respuesta.statusCode == 200) {
        final List<dynamic> datosJson = jsonDecode(utf8.decode(respuesta.bodyBytes));
        final listaMejoras = datosJson.map((e) => CatalogoMejoras.fromJson(e)).toList();
        return RespuestaApi(exito: true, mensaje: 'Catálogo de comunidad cargado', datos: listaMejoras);
      }
      return RespuestaApi(exito: false, mensaje: 'No se pudo cargar la tienda de la comunidad');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  /// Envía una propuesta de diseño artístico para ser integrada en el catálogo.
  Future<RespuestaApi> enviarPropuestaMejora({
    required int idComunidad,
    required String tipoArticulo,
    required String rutaArchivo,
    Uint8List? bytesWeb,
    int precioSugerido = 0,
  }) async {
    try {
      final token = await _servicioUsuarios.obtenerToken();
      final url = Uri.parse('$_urlMejoras/tienda/peticiones/crear/');

      var solicitud = http.MultipartRequest('POST', url);
      if (token != null) solicitud.headers['Authorization'] = 'Token $token';
      
      solicitud.fields['comunidad'] = idComunidad.toString();
      solicitud.fields['tipo'] = tipoArticulo;
      solicitud.fields['precio_sugerido'] = precioSugerido.toString();

      if (kIsWeb && bytesWeb != null) {
        solicitud.files.add(http.MultipartFile.fromBytes(
          'url_recurso',
          bytesWeb,
          filename: 'propuesta_web.png',
        ));
      } else {
        solicitud.files.add(await http.MultipartFile.fromPath('url_recurso', rutaArchivo));
      }

      final respuestaStream = await solicitud.send().timeout(const Duration(seconds: 40));
      final respuesta = await http.Response.fromStream(respuestaStream);

      if (respuesta.statusCode == 201) {
        return RespuestaApi(exito: true, mensaje: '¡Propuesta enviada a moderación!');
      }
      final datosError = jsonDecode(respuesta.body);
      return RespuestaApi(exito: false, mensaje: datosError['error'] ?? 'Error al enviar propuesta');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  /// Recupera las propuestas de mejoras pendientes de revisión para una comunidad.
  Future<RespuestaApi<List<dynamic>>> obtenerPropuestasPendientes(int idComunidad) async {
    try {
      final respuesta = await http.get(
        Uri.parse('$_urlMejoras/tienda/peticiones/moderacion/$idComunidad/'),
        headers: await _obtenerCabeceras(),
      ).timeout(const Duration(seconds: 20));

      if (respuesta.statusCode == 200) {
        final List<dynamic> datosJson = jsonDecode(utf8.decode(respuesta.bodyBytes));
        return RespuestaApi(exito: true, mensaje: 'Propuestas cargadas', datos: datosJson);
      }
      return RespuestaApi(exito: false, mensaje: 'No se pudieron recuperar las propuestas');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  /// Aprueba o rechaza una propuesta de mejora configurando su precio final.
  Future<RespuestaApi> moderarPropuesta(int idPropuesta, String nuevoEstado, int precioFinal) async {
    try {
      final respuesta = await http.post(
        Uri.parse('$_urlMejoras/tienda/peticiones/$idPropuesta/moderar/'),
        headers: await _obtenerCabeceras(),
        body: jsonEncode({'estado': nuevoEstado, 'precio': precioFinal}),
      ).timeout(const Duration(seconds: 20));

      if (respuesta.statusCode == 200) {
        return RespuestaApi(exito: true, mensaje: 'Moderación completada');
      }
      return RespuestaApi(exito: false, mensaje: 'Error al procesar la moderación');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  /// Realiza la compra de un artículo del catálogo utilizando puntos del usuario.
  Future<RespuestaApi> comprarMejora(int idMejora) async {
    try {
      final respuesta = await http.post(
        Uri.parse('$_urlMejoras/tienda/comprar/$idMejora/'),
        headers: await _obtenerCabeceras(),
      ).timeout(const Duration(seconds: 20));

      final datosJson = jsonDecode(respuesta.body);
      if (respuesta.statusCode == 200) {
        return RespuestaApi(
          exito: true,
          mensaje: datosJson['mensaje'] ?? '¡Compra realizada!',
          datos: datosJson['puntos_restantes'],
        );
      }
      return RespuestaApi(exito: false, mensaje: datosJson['error'] ?? 'Error en la transacción');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  /// Recupera el inventario completo de artículos adquiridos por el usuario actual.
  Future<RespuestaApi<List<dynamic>>> obtenerMisMejoras() async {
    try {
      final respuesta = await http.get(
        Uri.parse('$_urlMejoras/tienda/mis-mejoras/'),
        headers: await _obtenerCabeceras(),
      ).timeout(const Duration(seconds: 20));

      if (respuesta.statusCode == 200) {
        final List<dynamic> datosJson = jsonDecode(utf8.decode(respuesta.bodyBytes));
        return RespuestaApi(exito: true, mensaje: 'Inventario cargado', datos: datosJson);
      }
      return RespuestaApi(exito: false, mensaje: 'Error al cargar tu inventario');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  /// Activa o desactiva visualmente un cosmético del inventario.
  Future<RespuestaApi> equiparMejora(int idMejora) async {
    try {
      final respuesta = await http.post(
        Uri.parse('$_urlMejoras/tienda/equipar/'),
        headers: await _obtenerCabeceras(),
        body: jsonEncode({'mejora_id': idMejora}),
      ).timeout(const Duration(seconds: 20));

      final datosJson = jsonDecode(respuesta.body);
      if (respuesta.statusCode == 200) {
        return RespuestaApi(exito: true, mensaje: datosJson['resultado'] ?? 'Cambio aplicado');
      }
      return RespuestaApi(exito: false, mensaje: datosJson['error'] ?? 'Error al equipar mejora');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  /// Recupera el catálogo completo de una comunidad para fines de gestión administrativa.
  Future<RespuestaApi<List<CatalogoMejoras>>> obtenerCatalogoGestion(int idComunidad) async {
    try {
      final respuesta = await http.get(
        Uri.parse('$_urlMejoras/tienda/gestion/$idComunidad/'),
        headers: await _obtenerCabeceras(),
      ).timeout(const Duration(seconds: 20));

      if (respuesta.statusCode == 200) {
        final List<dynamic> datosJson = jsonDecode(utf8.decode(respuesta.bodyBytes));
        final listaMejoras = datosJson.map((e) => CatalogoMejoras.fromJson(e)).toList();
        return RespuestaApi(exito: true, mensaje: 'Catálogo administrativo cargado', datos: listaMejoras);
      }
      return RespuestaApi(exito: false, mensaje: 'Error al obtener catálogo de gestión');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }

  /// Actualiza los parámetros de precio y disponibilidad de un artículo en el catálogo.
  Future<RespuestaApi> actualizarArticuloCatalogo(
    int idComunidad,
    int idArticulo, {
    bool? estaActivo,
    int? precioFinal,
  }) async {
    try {
      final respuesta = await http.patch(
        Uri.parse('$_urlMejoras/tienda/gestion/$idComunidad/'),
        headers: await _obtenerCabeceras(),
        body: jsonEncode({
          'item_id': idArticulo,
          if (estaActivo != null) 'esta_activo': estaActivo,
          if (precioFinal != null) 'precio': precioFinal,
        }),
      ).timeout(const Duration(seconds: 20));

      final Map<String, dynamic> datosJson = jsonDecode(respuesta.body);
      if (respuesta.statusCode == 200) {
        return RespuestaApi(exito: true, mensaje: datosJson['mensaje'] ?? 'Artículo actualizado');
      }
      return RespuestaApi(exito: false, mensaje: datosJson['error'] ?? 'Error al actualizar el artículo');
    } catch (e) {
      return RespuestaApi(exito: false, mensaje: 'Error de conexión: $e');
    }
  }
}
