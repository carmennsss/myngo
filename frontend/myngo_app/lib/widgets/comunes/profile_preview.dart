import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/estilo_post_helper.dart';

class ProfilePreview extends StatelessWidget {
  final dynamic avatarUrl; 
  final String? marcoUrl;
  final dynamic fondoUrl;
  final String? nombreUsuario;
  final int? puntos;
  final String? estado;
  final double size;
  final VoidCallback? onAvatarTap;
  final String? colorTema;
  final String? fuentePerfil;

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
    this.colorTema,
    this.fuentePerfil,
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
      final Color themeColor = EstiloPostHelper.parseHex(colorTema) ?? const Color(0xFFC35E34);
      final String fontFamily = fuentePerfil ?? 'Outfit';

      return Column(
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
          SizedBox(height: size * 0.55), 
          // 3. NOMBRE Y PUNTOS
          if (nombreUsuario != null)
            Text(
              nombreUsuario!,
              style: GoogleFonts.getFont(
                fontFamily,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: themeColor,
              ),
            ),
          if (puntos != null)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.pets_rounded, size: 12, color: themeColor.withOpacity(0.7)),
                const SizedBox(width: 4),
                Text(
                  '$puntos puntos',
                  style: GoogleFonts.getFont(
                    fontFamily,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
        ],
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
