/**
 * @author Carmen Tamayo Doña
 * @author Ainhoa Gomez Toro
 * @version 1.0
 * @date 2026-05-14
 */

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:tolgee/tolgee.dart';

import 'providers/post_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/locale_notifier.dart';
import 'providers/notificacion_provider.dart';
import 'services/servicio_notificaciones_locales.dart';
import 'router.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy(); 
  await initializeDateFormatting('es_ES', null);
  
  // Inicializar notificaciones locales
  await ServicioNotificacionesLocales.inicializar();

  // Configurar Tolgee
  // Si no se proporcionan apiKey y apiUrl, Tolgee buscará automáticamente en lib/tolgee/
  final String apiKey = const String.fromEnvironment('TOLGEE_API_KEY');
  final String apiUrl = const String.fromEnvironment('TOLGEE_API_URL', defaultValue: 'https://app.tolgee.io');

  if (!kReleaseMode && apiKey.isNotEmpty) {
    await Tolgee.init(
      apiKey: apiKey,
      apiUrl: apiUrl,
    );
  } else {

    await Tolgee.init();
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PostProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => LocaleNotifier()),
        ChangeNotifierProvider(create: (_) => NotificacionProvider()),
      ],
      child: const TolgeeInContextWrapper(child: MiAplicacion()),
    ),
  );
}

class TolgeeInContextWrapper extends StatelessWidget {
  final Widget child;
  const TolgeeInContextWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (kReleaseMode) return child;
    
    return Listener(
      onPointerDown: (event) {
        final keys = HardwareKeyboard.instance.logicalKeysPressed;
        if (keys.contains(LogicalKeyboardKey.altLeft) || 
            keys.contains(LogicalKeyboardKey.altRight)) {
          try {
            Tolgee.highlightTolgeeWidgets();
          } catch (e) {
            // Si la versión actual del SDK de Flutter no expone este método, lo ignoramos
            debugPrint("Tolgee highlight no disponible: $e");
          }
        }
      },
      child: child,
    );
  }
}

class MiAplicacion extends StatelessWidget {
  const MiAplicacion({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LocaleNotifier>(
      builder: (context, localeNotifier, child) => MaterialApp.router(
        routerConfig: appRouter,
        locale: localeNotifier.locale,
        localizationsDelegates: Tolgee.localizationDelegates,
        supportedLocales: Tolgee.supportedLocales,
        debugShowCheckedModeBanner: false,
        scrollBehavior: const MaterialScrollBehavior().copyWith(
          scrollbars: true,
          dragDevices: {
            PointerDeviceKind.touch,
            PointerDeviceKind.mouse,
            PointerDeviceKind.trackpad,
          },
        ),
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFC35E34)).copyWith(
            primary: const Color(0xFFC35E34),
            secondary: const Color(0xFFF29C50),
            tertiary: const Color(0xFF248EA6),
            surface: Colors.white,
            onSurface: const Color(0xFF4A4440),
            error: const Color(0xFFD95F43),
          ),
          scaffoldBackgroundColor: const Color(0xFFFEF5F1),
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
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: const BorderSide(color: Color(0xFFC35E34), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: const BorderSide(color: Color(0xFFD95F43), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            hintStyle: GoogleFonts.outfit(color: const Color(0xFF4A4440).withOpacity(0.4)),
          ),
        ),
      ),
    );
  }
}
