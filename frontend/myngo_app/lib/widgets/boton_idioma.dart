import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BotonIdioma extends StatelessWidget {
  const BotonIdioma({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: PopupMenuButton<String>(
        tooltip: 'Cambiar idioma',
        offset: const Offset(0, 45),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.language_rounded, size: 20, color: Color(0xFFC35E34)),
              const SizedBox(width: 8),
              Text(
                'ES',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF4A4440),
                ),
              ),
              const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Colors.grey),
            ],
          ),
        ),
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'es',
            child: Row(
              children: [
                const Text('🇪🇸', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 12),
                Text('Español', style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
                const Spacer(),
                const Icon(Icons.check_circle_rounded, color: Colors.green, size: 16),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'en',
            child: Row(
              children: [
                const Text('🇺🇸', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 12),
                Text('English', style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
