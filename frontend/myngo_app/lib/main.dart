import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'screens/login/pantalla_login.dart';
import 'screens/registro/pantalla_registro.dart';
import 'screens/recuperar_contrasena/pantalla_recuperar_contrasena.dart';
import 'screens/inicio/pantalla_inicio.dart';
import 'screens/comunidades/pantalla_comunidades.dart';

import 'package:provider/provider.dart';
import 'providers/post_provider.dart';
import 'router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy(); 
  await initializeDateFormatting('es_ES', null);
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
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        scrollbars: true,
      ),
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFC35E34),
          brightness: Brightness.light,
          primary: const Color(0xFFC35E34),   // Terracotta Orange
          secondary: const Color(0xFFF29C50), // Gold/Mandarina
          tertiary: const Color(0xFF248EA6),  // Teal Contrast
          surface: Colors.white,
          onSurface: const Color(0xFF4A4440), // Warm Dark Grey
          error: const Color(0xFFD95F43),
        ),
        scaffoldBackgroundColor: const Color(0xFFFEF5F1), // Warm Peach Cream
        textTheme: GoogleFonts.outfitTextTheme(ThemeData.light().textTheme).copyWith(
          displayLarge: GoogleFonts.outfit(color: const Color(0xFF4A4440), fontWeight: FontWeight.w900),
          bodyLarge: GoogleFonts.outfit(color: const Color(0xFF4A4440).withOpacity(0.9)),
        ),
        cardTheme: CardThemeData(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          color: Colors.white,
          elevation: 10,
          shadowColor: const Color(0xFF4A4440).withOpacity(0.08),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFC35E34),
            foregroundColor: Colors.white,
            textStyle: GoogleFonts.outfit(fontWeight: FontWeight.w900, letterSpacing: 1.0),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            elevation: 4,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: const Color(0xFFC35E34).withOpacity(0.1), width: 1.5)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: const Color(0xFFC35E34).withOpacity(0.1), width: 1.5)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: Color(0xFFC35E34), width: 2)),
          hintStyle: GoogleFonts.outfit(color: Colors.grey.shade400, fontSize: 13),
          prefixIconColor: const Color(0xFFC35E34).withOpacity(0.5),
          suffixIconColor: const Color(0xFFC35E34).withOpacity(0.5),
          labelStyle: GoogleFonts.outfit(color: const Color(0xFF4A4440).withOpacity(0.7), fontSize: 14),
        ),
        // ── Scrollbar global ─────────────────────────────────────────────
        scrollbarTheme: ScrollbarThemeData(
          // Thumb visible siempre que haya contenido desplazable
          thumbVisibility: WidgetStateProperty.all(true),
          // Track sutil: solo visible al hover/drag para no recargar la UI
          trackVisibility: WidgetStateProperty.resolveWith(
            (states) => states.any({
              WidgetState.hovered,
              WidgetState.dragged,
            }.contains),
          ),
          thickness: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.hovered) ? 8.0 : 5.0,
          ),
          radius: const Radius.circular(10),
          interactive: true,
          crossAxisMargin: 3,
          mainAxisMargin: 4,
          // Thumb: terracotta semitransparente → opaco al interactuar
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.dragged)) {
              return const Color(0xFFC35E34); // Terracotta sólido al arrastrar
            }
            if (states.contains(WidgetState.hovered)) {
              return const Color(0xFFF29C50); // Oro/mandarina al hover
            }
            return const Color(0xFFC35E34).withOpacity(0.45); // Terracotta suave en reposo
          }),
        // Track: muy sutil, combina con el fondo cálido
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.any({WidgetState.hovered, WidgetState.dragged}.contains)) {
            return const Color(0xFFC35E34).withOpacity(0.08);
          }
          return Colors.transparent;
        }),
        trackBorderColor: WidgetStateProperty.all(Colors.transparent),
      ),
    ),
    routerConfig: appRouter,
    );
  }
}
