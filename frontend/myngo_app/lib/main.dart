import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/login/pantalla_login.dart';
import 'screens/registro/pantalla_registro.dart';
import 'screens/recuperar_contrasena/pantalla_recuperar_contrasena.dart';
import 'screens/inicio/pantalla_inicio.dart';
import 'screens/comunidades/pantalla_comunidades.dart';

import 'package:provider/provider.dart';
import 'providers/post_provider.dart';

void main() {
  usePathUrlStrategy(); 
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PostProvider()),
      ],
      child: const MiAplicacion(),
    ),
  );
}

class MiAplicacion extends StatelessWidget {
  const MiAplicacion({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Myngo App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFF28B50),
          brightness: Brightness.dark,
          surface: const Color(0xFF1E1E1E),
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
        useMaterial3: true,
        textTheme: GoogleFonts.interTextTheme(),
      ),
      initialRoute: '/inicio',
      routes: {
        '/login': (context) => const PantallaLogin(),
        '/registro': (context) => const PantallaRegistro(),
        '/recuperar_contrasena': (context) => const PantallaRecuperarContrasena(),
        '/inicio': (context) => const PantallaInicio(),
        '/comunidades': (context) => const PantallaComunidades(),
      },
    );
  }
}
