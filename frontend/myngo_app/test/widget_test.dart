// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:myngo_app/main.dart';
import 'package:myngo_app/providers/chat_provider.dart';
import 'package:myngo_app/providers/post_provider.dart';
import 'package:myngo_app/providers/locale_notifier.dart';
import 'package:provider/provider.dart';
import 'package:tolgee/tolgee.dart';

void main() {
  setUpAll(() async {
    await Tolgee.init();
  });

  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => PostProvider()),
          ChangeNotifierProvider(create: (_) => ChatProvider()),
          ChangeNotifierProvider(create: (_) => LocaleNotifier()),
        ],
        child: const MiAplicacion(),
      ),
    );
    expect(find.byType(MiAplicacion), findsOneWidget);
  });
}
