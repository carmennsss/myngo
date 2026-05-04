import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProfilePreview extends StatelessWidget {
  final String? avatarUrl;
  final String? marcoUrl;
  final String? fondoUrl;
  final String? nombreUsuario;
  final int? puntos;
  final String? estado;
  final double size;
  final VoidCallback? onAvatarTap;

  const ProfilePreview({
    super.key,
    this.avatarUrl,
    this.marcoUrl,
    this.fondoUrl,
    this.nombreUsuario,
    this.puntos,
    this.estado,
    this.size = 120,
    this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    // Si hay fondo, mostramos un diseño de "Cabecera de Perfil"
    if (fondoUrl != null && fondoUrl!.isNotEmpty) {
      return Container(
        width: size * 2.5, 
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // 1. BANNER RECTANGULAR
                Container(
                  width: size * 2.5,
                  height: size * 0.8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: CachedNetworkImage(
                      imageUrl: fondoUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(color: Colors.grey[300]),
                      errorWidget: (context, url, error) => const Icon(Icons.image),
                    ),
                  ),
                ),
                
                // 2. AVATAR + MARCO (Posicionado encima)
                Positioned(
                  top: size * 0.3,
                  child: _buildAvatarWithFrame(),
                ),
              ],
            ),
            SizedBox(height: size * 0.6), 
          ],
        ),
      );
    }

    return _buildAvatarWithFrame();
  }

  Widget _buildAvatarWithFrame() {
    // REDUCCIÓN CRÍTICA: El avatar al 50% para que el marco (100%) luzca todos sus detalles por encima
    final double avatarSize = size * 0.50; 
    final double marcoSize = size;

    return Container(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. EL AVATAR (Capa inferior del pequeño stack)
          GestureDetector(
            onTap: onAvatarTap,
            child: Container(
              width: avatarSize,
              height: avatarSize,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: ClipOval(
                child: (avatarUrl != null && avatarUrl!.isNotEmpty)
                    ? CachedNetworkImage(
                        imageUrl: avatarUrl!,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) => const Icon(Icons.person, size: 25),
                      )
                    : const Icon(Icons.person, size: 25, color: Colors.grey),
              ),
            ),
          ),

          // 2. EL MARCO (CAPA SUPERIOR - OVERLAY)
          if (marcoUrl != null && marcoUrl!.isNotEmpty)
            IgnorePointer(
              child: Container(
                width: marcoSize,
                height: marcoSize,
                child: CachedNetworkImage(
                  imageUrl: marcoUrl!,
                  fit: BoxFit.contain, // Para que las alas se vean perfectas
                  placeholder: (context, url) => const SizedBox.shrink(),
                  errorWidget: (context, url, error) => const SizedBox.shrink(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
