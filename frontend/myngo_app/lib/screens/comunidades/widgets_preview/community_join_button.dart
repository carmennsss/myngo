import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/comunidad.dart';

class CommunityJoinButton extends StatelessWidget {
  final Comunidad comunidad;
  final int? miId;
  final bool estaCargandoPeticion;
  final VoidCallback onLogin;
  final VoidCallback onJoin;
  final bool isPreview;

  const CommunityJoinButton({
    super.key,
    required this.comunidad,
    required this.miId,
    required this.estaCargandoPeticion,
    required this.onLogin,
    required this.onJoin,
    this.isPreview = false,
  });

  @override
  Widget build(BuildContext context) {
    if (miId == null) {
      return Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              comunidad.esPublica
                  ? '¿Ves algo que te gusta? 👀'
                  : 'Esta comunidad es privada 🔒',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: onLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF28B50),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.login_rounded, size: 20),
              label: Text(
                'INICIA SESIÓN 🐾',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(24),
      child: ElevatedButton(
        onPressed: estaCargandoPeticion ? null : onJoin,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF28B50),
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: estaCargandoPeticion
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                comunidad.esPendiente
                    ? 'SOLICITUD PENDIENTE 🐾'
                    : (comunidad.esPublica ? 'UNIRSE AHORA ✨' : 'SOLICITAR ENTRAR 🐾'),
                style: GoogleFonts.inter(fontWeight: FontWeight.bold),
              ),
      ),
    );
  }
}
