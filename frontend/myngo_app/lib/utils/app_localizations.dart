import 'package:flutter/widgets.dart';
import 'package:tolgee/tolgee.dart';
import 'package:intl/message_format.dart';
import 'package:tolgee/src/translations/tolgee_translation_strategy.dart';
import 'package:myngo_app/utils/tr_helper.dart';

class AppLocalizations {
  static final AppLocalizations _instance = AppLocalizations._();
  
  AppLocalizations._();

  static AppLocalizations of(BuildContext context) {
    return _instance;
  }

  String tr(String key, [Map<String, Object>? args]) {
    final result = TolgeeTranslationsStrategy.instance.translate(key) ?? key;
    if (args == null) return result;
    return MessageFormat(result).format(args);
  }
}
