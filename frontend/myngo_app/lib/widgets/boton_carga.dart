import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myngo_app/utils/tr_helper.dart';

// Botón naranja con gradiente que usamos en los formularios de login y registro.
// Cuando se está procesando algo muestra un spinner en vez del texto, y bloquea el tap.
class BotonCarga extends StatelessWidget {
  // Qué hacer cuando el usuario pulsa
  final VoidCallback alPresionar;

  // Controla si está en modo carga (true = spinner, false = texto)
  final ValueNotifier<bool> notificadorCargando;

  // El texto del botón (por defecto 'CONTINUAR')
  final String? texto;

  const BotonCarga({
    super.key,
    required this.alPresionar,
    required this.notificadorCargando,
    this.texto,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: notificadorCargando,
      builder: (context, estaCargando, hijo) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: 62,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              colors: [Color(0xFFF28B50), Color(0xFFF29C50)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF28B50).withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: estaCargando ? null : alPresionar,
              borderRadius: BorderRadius.circular(28),
              child: Center(
                child: estaCargando
                    ? const SizedBox(
                        height: 28,
                        width: 28,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : Text(
                        texto?.toUpperCase() ?? tr('commonContinue').toUpperCase(),
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
              ),
            ),
          ),
        );
      },
    );
  }
}
