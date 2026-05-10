import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../utils/estilo_post_helper.dart';

// Preview de un post con el estilo visual del usuario (fuente, colores, fondo).
// Lo usamos en la pantalla de personalizar perfil para que el usuario vea cómo quedará su muro en tiempo real.
class PostPreview extends StatelessWidget {
  final Map<String, dynamic>? estilo;
  final dynamic avatarUrl;
  final String? marcoUrl;
  final String nombreUsuario;

  const PostPreview({
    super.key,
    this.estilo,
    this.avatarUrl,
    this.marcoUrl,
    this.nombreUsuario = 'Usuario',
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
    
    try {
      if (kIsWeb) {
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
    final esFondoClaro = EstiloPostHelper.esFondoClaro(estilo);
    final colorTexto = esFondoClaro ? const Color(0xFF2E2A27) : Colors.white;
    final colorSubtexto = esFondoClaro ? Colors.grey.shade600 : Colors.white70;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: EstiloPostHelper.buildDecoracion(
        estilo,
        borderRadius: BorderRadius.circular(20),
        shadows: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              SizedBox(
                width: 40,
                height: 40,
                child: Stack(
                  alignment: Alignment.center,
                  children: [

                    Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      child: ClipOval(
                        child: _buildImage(avatarUrl, errorWidget: Center(child: Text(nombreUsuario.isNotEmpty ? nombreUsuario[0].toUpperCase() : '?', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)))),
                      ),
                    ),
                    // Marco
                    if (marcoUrl != null && marcoUrl!.isNotEmpty)
                      Positioned.fill(
                        child: Image.network(marcoUrl!, fit: BoxFit.contain),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mi nuevo estilo ✨',
                    style: GoogleFonts.getFont(
                      EstiloPostHelper.getFontFamily(estilo),
                      fontWeight: FontWeight.bold, 
                      color: colorTexto, 
                      fontSize: 14
                    ),
                  ),
                  Text(
                    '@$nombreUsuario',
                    style: GoogleFonts.getFont(
                      EstiloPostHelper.getFontFamily(estilo),
                      color: colorSubtexto, 
                      fontSize: 12
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '¡Mira cómo queda mi perfil con estas mejoras! ¿Te gusta el nuevo diseño? 🐾',
            style: GoogleFonts.getFont(
              EstiloPostHelper.getFontFamily(estilo),
              color: colorTexto, 
              fontSize: 13, 
              height: 1.4
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.favorite_border_rounded, size: 18, color: colorSubtexto),
              const SizedBox(width: 16),
              Icon(Icons.chat_bubble_outline_rounded, size: 18, color: colorSubtexto),
              const Spacer(),
              Icon(Icons.bookmark_border_rounded, size: 18, color: colorSubtexto),
            ],
          ),
        ],
      ),
    );
  }
}
