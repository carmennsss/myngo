# TODO: Fix Flutter Compilation Errors - Tolgee i18n Migration

## Status: 🚀 In Progress

### Breakdown of Approved Plan:

**✅ Step 1: Fix main.dart syntax errors (Priority - blocks everything)**
- [x] Fix Consumer<LocaleNotifier>( missing )
- [x] Fix CardTheme → CardThemeData
- [x] Add Tolgee import and delegates
- [x] Complete ThemeData structure (colorScheme, scrollbar, routerConfig)
- Edit via edit_file on d:/TFG/myngo/frontend/myngo_app/lib/main.dart

**Next:** Step 2 cabecera_pro.dart

**Step 2: cabecera_pro.dart**
- [ ] Ensure TranslationFunction import/definition
- [ ] Minor Tolgee adjustments

**Step 3: sidebar_izquierdo.dart (Major)**
- [ ] Remove all AppLocalizations.of
- [ ] Fix _obtenerRango call with Tolgee.t()
- [ ] Replace l10n.* with tr()

**Step 4: pantalla_inicio.dart**
- [ ] Replace AppLocalizations.of with Tolgee.t()

**Step 5: pantalla_detalle_perfil.dart**
- [ ] Add Tolgee import
- [ ] Define/replace tr() calls

**Step 6: Global verification**
- [ ] Search for remaining AppLocalizations
- [ ] Test: cd frontend/myngo_app && flutter pub get && flutter analyze && flutter run -d chrome

**Step 7: Complete**
- [ ] attempt_completion

**Next Action:** Fix main.dart first (syntax blocker)

