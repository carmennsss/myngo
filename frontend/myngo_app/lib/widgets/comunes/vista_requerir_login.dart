import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'boton_tactil.dart';

// Pantalla de bloqueo que aparece cuando un usuario no logueado intenta acceder a algo privado.
// Muestra un mensaje amigable y botones para ir al login o al registro.
class VistaRequerirLogin extends StatelessWidget {
  final String titulo;
  final String mensaje;

  const VistaRequerirLogin({
    super.key,
    this.titulo = '¡Miau! Acceso Restringido',
    this.mensaje = 'Para participar en la comunidad, chatear y ver tus notificaciones necesitas iniciar sesión.',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: const Color(0xFFC35E34).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_person_rounded, size: 80, color: Color(0xFFC35E34)),
            ),
            const SizedBox(height: 32),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF4A4440),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 16,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),
            BotonTactil(
              onTap: () => Navigator.pushNamed(context, '/login'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFC35E34),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFFC35E34).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4)),
                  ],
                ),
                child: Text(
                  'INICIAR SESIÓN',
                  style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1.2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/registro'),
              child: Text(
                '¿Aún no eres un michi? Regístrate',
                style: GoogleFonts.outfit(color: const Color(0xFFC35E34), fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
