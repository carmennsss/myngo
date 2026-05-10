import 'package:flutter/material.dart';
import '../../../models/usuario.dart';
import '../../../models/comunidad.dart';
import '../../../widgets/comunes/post_preview.dart';
import '../../../widgets/comunes/profile_preview.dart';
import '../../../utils/configuracion.dart';
import 'package:myngo_app/utils/tr_helper.dart';

/// Widget que muestra la previsualización dinámica de las mejoras seleccionadas.
class TiendaPreviewSection extends StatelessWidget {
  final Usuario? usuarioActual;
  final Comunidad? comunidad;
  final String? previewAvatar;
  final String? previewMarco;
  final String? previewFondo;
  final Map<String, dynamic>? previewEstiloPost;

  const TiendaPreviewSection({
    super.key,
    this.usuarioActual,
    this.comunidad,
    this.previewAvatar,
    this.previewMarco,
    this.previewFondo,
    this.previewEstiloPost,
  });

  @override
  Widget build(BuildContext context) {
    final bool esAncho = MediaQuery.of(context).size.width > 1000;
    final bool esMedio = MediaQuery.of(context).size.width > 600;
    final double scale = esAncho ? 1.0 : 0.9;

    // Modo perfil de usuario
    if (usuarioActual == null) return const SizedBox.shrink();

    final content = esMedio && !esAncho
        ? Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Transform.scale(
                  scale: scale,
                  child: _buildProfilePreview(context),
                ),
              ),
              const SizedBox(width: 20),
              Flexible(
                child: Transform.scale(
                  scale: scale,
                  child: _buildPostPreview(context),
                ),
              ),
            ],
          )
        : Column(
            children: [
              Transform.scale(
                scale: scale,
                child: _buildProfilePreview(context),
              ),
              const SizedBox(height: 12),
              Transform.scale(
                scale: scale,
                child: _buildPostPreview(context),
              ),
            ],
          );

    return Container(
      margin: EdgeInsets.symmetric(horizontal: esAncho ? 40 : 24, vertical: 12),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(24),
      ),
      child: content,
    );
  }

  String? _getAbsoluteUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http')) return path;
    final base = Configuracion.baseUrl.endsWith('/') 
        ? Configuracion.baseUrl 
        : '${Configuracion.baseUrl}/';
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    return '$base$cleanPath';
  }

  Widget _buildComunidadPreview() {
    final fondo = _getAbsoluteUrl(previewFondo ?? comunidad!.urlFondo ?? comunidad!.urlPortada);
    final avatar = _getAbsoluteUrl(previewAvatar ?? comunidad!.urlAvatar ?? comunidad!.urlPortada);

    return ProfilePreview(
      fondoUrl: fondo,
      avatarUrl: avatar,
      marcoUrl: _getAbsoluteUrl(previewMarco),
      nombreUsuario: comunidad!.nombre,
      puntos: 0,
    );
  }

  Widget _buildProfilePreview(BuildContext context) {
    return ProfilePreview(
      fondoUrl: _getAbsoluteUrl(previewFondo),
      avatarUrl: _getAbsoluteUrl(previewAvatar),
      marcoUrl: _getAbsoluteUrl(previewMarco),
      nombreUsuario: usuarioActual?.nombreUsuario ?? tr('user'),
      puntos: usuarioActual?.puntos ?? 0,
    );
  }

  Widget _buildPostPreview(BuildContext context) {
    return PostPreview(
      estilo: previewEstiloPost,
      avatarUrl: _getAbsoluteUrl(previewAvatar),
      marcoUrl: _getAbsoluteUrl(previewMarco),
      nombreUsuario: usuarioActual?.nombreUsuario ?? tr('user'),
    );
  }
}
