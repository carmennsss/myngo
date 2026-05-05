import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tolgee/tolgee.dart';

class LocaleNotifier extends ChangeNotifier {
  Locale _locale = const Locale('es');

  Locale get locale => _locale;

  LocaleNotifier() {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString('language_code') ?? 'es';
    _locale = Locale(languageCode);
    // Mapear es → es-ES para que coincida con el tag del proyecto Tolgee
    final tolgeeLocale = languageCode == 'es' ? const Locale('es', 'ES') : const Locale('en');
    await Tolgee.setCurrentLocale(tolgeeLocale);
    notifyListeners();
  }

  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', locale.languageCode);
    // Notificar a Tolgee del cambio de idioma
    final tolgeeLocale = locale.languageCode == 'es' ? const Locale('es', 'ES') : const Locale('en');
    await Tolgee.setCurrentLocale(tolgeeLocale);
    notifyListeners();
  }

  void cycleLocale() {
    final newLocale = _locale.languageCode == 'es' ? const Locale('en') : const Locale('es');
    setLocale(newLocale);
  }
}
