import 'package:tolgee/tolgee.dart';
import 'package:intl/message_format.dart';
import 'package:tolgee/src/translations/tolgee_translation_strategy.dart';

String tr(String key, [Map<String, dynamic>? args]) {
  final result = TolgeeTranslationsStrategy.instance.translate(key) ?? key;
  if (args == null) return result;
  final convertedArgs = args.map((k, v) => MapEntry(k, v as Object));
  return MessageFormat(result).format(convertedArgs);
}
