import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/login/pantalla_login.dart';
import 'screens/registro/pantalla_registro.dart';

/// Punto de entrada principal de la aplicación Myngo.
void main() {
  usePathUrlStrategy(); // Elimina el # de las URLs en Flutter Web
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
      initialRoute: '/login',
      routes: {
        '/login': (context) => const PantallaLogin(),
        '/registro': (context) => const PantallaRegistro(),
      },
    );
  }
}
