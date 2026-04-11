import 'servicio_galeria.dart';

/// Servicio para la pantalla de inicio.
/// Delegado hacia ServicioGaleria para las operaciones de feed.
class ServicioInicio {
  final _servicioGaleria = ServicioGaleria();

  /// Obtiene publicaciones del feed de inicio llamando a ServicioGaleria.
  Future obtenerPostsInicio({
    int limit = 20,
    int offset = 0,
    String? etiquetas,
  }) =>  _servicioGaleria.obtenerGaleriaInicio(limit: limit, offset: offset, etiquetas: etiquetas);
}
