import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProfilePreview extends StatelessWidget {
  final String? fondoUrl;
  final String? avatarUrl;
  final String? marcoUrl;
  final String nombreUsuario;
  final int puntos;

  const ProfilePreview({
    super.key,
    this.fondoUrl,
    this.avatarUrl,
    this.marcoUrl,
    this.nombreUsuario = 'Usuario',
    this.puntos = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: const Color(0xFFC35E34).withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFC35E34).withOpacity(0.08),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Column(
          children: [
            // Cabecera de Perfil (Fondo)
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Container(
                  height: 100,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBE9E0),
                    image: (fondoUrl != null && fondoUrl!.isNotEmpty)
                        ? DecorationImage(
                            image: CachedNetworkImageProvider(fondoUrl!), 
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                ),
                Positioned(
                  bottom: -35,
                  child: SizedBox(
                    width: 90,
                    height: 90,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // 1. Avatar (debajo)
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          child: CircleAvatar(
                            radius: 32,
                            backgroundImage: (avatarUrl != null && avatarUrl!.isNotEmpty) 
                                ? CachedNetworkImageProvider(avatarUrl!) 
                                : null,
                            backgroundColor: const Color(0xFFFBE9E0),
                            child: (avatarUrl == null || avatarUrl!.isEmpty) 
                                ? const Icon(Icons.person, color: Color(0xFFC35E34), size: 28) 
                                : null,
                          ),
                        ),
                        // 2. Marco (encima)
                        if (marcoUrl != null && marcoUrl!.isNotEmpty)
                          Positioned.fill(
                            child: Image.network(marcoUrl!, fit: BoxFit.contain),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 45),
            // Nombre y Puntos
            Text(
              nombreUsuario,
              style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF4A4440)),
            ),
            if (puntos > 0) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.stars_rounded, color: Color(0xFFF29C50), size: 14),
                  const SizedBox(width: 4),
                  Text(
                    '$puntos Puntos',
                    style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFC35E34)),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
