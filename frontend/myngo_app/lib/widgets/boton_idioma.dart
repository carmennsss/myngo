import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../providers/locale_notifier.dart';
import '../l10n/app_localizations.dart';

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
        final label = AppLocalizations.of(context)!.languageSpanish;

        return GestureDetector(
          onTap: localeNotifier.cycleLocale,
          onLongPress: onLongPress,
          child: Container(
            margin: margin ?? EdgeInsets.zero,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FaIcon(
                  isSpanish ? FontAwesomeIcons.language : FontAwesomeIcons.globe,
                  size: iconSize * 0.8,
                  color: const Color(0xFFC35E34),
                ),
                const SizedBox(width: 4),
                Text(
                  isSpanish ? 'ES' : 'EN',
                  style: TextStyle(
                    fontSize: iconSize * 0.7,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFC35E34),
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

