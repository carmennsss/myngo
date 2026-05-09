import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProfilePreview extends StatelessWidget {
  final dynamic avatarUrl; // Puede ser String (URL) o XFile (local)
  final String? marcoUrl;
  final dynamic fondoUrl;
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

  Widget _buildImage(dynamic source, {BoxFit fit = BoxFit.cover, Widget? errorWidget}) {
    if (source == null) return errorWidget ?? const SizedBox.shrink();
    if (source is String && source.isNotEmpty) {
      if (source.startsWith('http')) {
        return CachedNetworkImage(
          imageUrl: source,
          fit: fit,
          placeholder: (context, url) => Container(color: Colors.grey[100]),
          errorWidget: (context, url, error) => errorWidget ?? const Icon(Icons.broken_image),
        );
      }
    }
    
    // Si es XFile o una ruta local
    try {
      if (kIsWeb) {
        // En web, XFile.path es un Blob URL o similar
        final path = source is String ? source : (source as dynamic).path;
        return Image.network(path, fit: fit, errorBuilder: (_, __, ___) => errorWidget ?? const Icon(Icons.broken_image));
      } else {
        final path = source is String ? source : (source as dynamic).path;
        return Image.file(File(path), fit: fit, errorBuilder: (_, __, ___) => errorWidget ?? const Icon(Icons.broken_image));
      }
    } catch (_) {
      return errorWidget ?? const Icon(Icons.broken_image);
    }
  }

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
                    child: _buildImage(fondoUrl, fit: BoxFit.cover),
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

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. EL AVATAR (Capa inferior)
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
                child: _buildImage(avatarUrl, errorWidget: const Icon(Icons.person, size: 25, color: Colors.grey)),
              ),
            ),
          ),

          // 2. EL MARCO (CAPA SUPERIOR - OVERLAY)
          if (marcoUrl != null && marcoUrl!.isNotEmpty)
            Positioned.fill(
              child: IgnorePointer(
                child: CachedNetworkImage(
                  imageUrl: marcoUrl!,
                  fit: BoxFit.contain,
                  alignment: Alignment.center,
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
