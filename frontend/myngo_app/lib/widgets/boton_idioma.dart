import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/locale_notifier.dart';
import 'package:tolgee/tolgee.dart';

class BotonIdioma extends StatelessWidget {
  final double iconSize;
  final EdgeInsets? margin;
  final VoidCallback? onLongPress;

  const BotonIdioma({
    super.key,
    this.iconSize = 20.0,
    this.margin,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<LocaleNotifier>(
      builder: (context, localeNotifier, child) {
        final locale = localeNotifier.locale;
        final isSpanish = locale.languageCode == 'es';

        return GestureDetector(
          onTap: localeNotifier.cycleLocale,
          onLongPress: onLongPress ?? () {
            Tolgee.highlightTolgeeWidgets();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: margin ?? EdgeInsets.zero,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFC35E34).withOpacity(0.1), width: 1),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFC35E34).withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFC35E34).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isSpanish ? Icons.translate_rounded : Icons.g_translate_rounded,
                    size: iconSize * 0.75,
                    color: const Color(0xFFC35E34),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  isSpanish ? 'ES' : 'EN',
                  style: GoogleFonts.outfit(
                    fontSize: iconSize * 0.7,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFFC35E34),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

