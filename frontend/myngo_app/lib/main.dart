import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/login/pantalla_login.dart';

/// Punto de entrada principal de la aplicación Myngo.
void main() {
  runApp(const MiAplicacion());
}

/// Widget raíz que configura el tema global y la navegación inicial.
class MiAplicacion extends StatelessWidget {
  const MiAplicacion({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Myngo App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C63FF),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.outfitTextTheme(),
      ),
      home: const PantallaLogin(),
    );
  }
}
