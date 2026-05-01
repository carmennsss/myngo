import 'package:flutter/material.dart';
import '../../../models/usuario.dart';
import '../../../widgets/comunes/post_preview.dart';
import '../../../widgets/comunes/profile_preview.dart';

/// Widget que muestra la previsualización dinámica de las mejoras seleccionadas.
class TiendaPreviewSection extends StatelessWidget {
  final Usuario? usuarioActual;
  final String? previewAvatar;
  final String? previewMarco;
  final String? previewFondo;
  final Map<String, dynamic>? previewEstiloPost;

  const TiendaPreviewSection({
    super.key,
    this.usuarioActual,
    this.previewAvatar,
    this.previewMarco,
    this.previewFondo,
    this.previewEstiloPost,
  });

  @override
  Widget build(BuildContext context) {
    if (usuarioActual == null) return const SizedBox.shrink();
    final bool esAncho = MediaQuery.of(context).size.width > 1000;
    final bool esMedio = MediaQuery.of(context).size.width > 600;

    final double scale = esAncho ? 1.0 : 0.9;

    final content = esMedio && !esAncho
        ? Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Transform.scale(
                  scale: scale,
                  child: _buildProfilePreview(),
                ),
              ),
              const SizedBox(width: 20),
              Flexible(
                child: Transform.scale(
                  scale: scale,
                  child: _buildPostPreview(),
                ),
              ),
            ],
          )
        : Column(
            children: [
              Transform.scale(
                scale: scale,
                child: _buildProfilePreview(),
              ),
              const SizedBox(height: 12),
              Transform.scale(
                scale: scale,
                child: _buildPostPreview(),
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

  Widget _buildProfilePreview() {
    return ProfilePreview(
      fondoUrl: previewFondo,
      avatarUrl: previewAvatar,
      marcoUrl: previewMarco,
      nombreUsuario: usuarioActual?.nombreUsuario ?? 'Usuario',
      puntos: usuarioActual?.puntos ?? 0,
    );
  }

  Widget _buildPostPreview() {
    return PostPreview(
      estilo: previewEstiloPost,
      avatarUrl: previewAvatar,
      marcoUrl: previewMarco,
      nombreUsuario: usuarioActual?.nombreUsuario ?? 'Usuario',
    );
  }
}
