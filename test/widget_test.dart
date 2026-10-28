import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homework_and_chores/app/app.dart';
import 'package:homework_and_chores/app/theme/chore_palette.dart';

Future<void> pumpApp(
  WidgetTester tester, {
  Locale locale = const Locale('en'),
}) async {
  tester.platformDispatcher.localesTestValue = [locale];
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  await tester.pumpWidget(const ProviderScope(child: ChoresApp()));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('starts on Today with all navigation destinations', (
    tester,
  ) async {
    await pumpApp(tester);

    for (final label in ['Today', 'Plan', 'World', 'Stats', 'Settings']) {
      expect(find.widgetWithText(NavigationDestination, label), findsOneWidget);
    }
    expect(find.text('Coming in version 0.1.0'), findsOneWidget);
  });

  testWidgets('uses German on a German device', (tester) async {
    await pumpApp(tester, locale: const Locale('de'));

    expect(find.text('Heute'), findsWidgets);
    expect(find.text('Einstellungen'), findsOneWidget);
  });

  testWidgets('settings switch dark mode and colorblind palette', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.dark);

    await tester.tap(find.text('Colorblind-friendly colors'));
    await tester.pumpAndSettle();
    final context = tester.element(find.text('Colorblind-friendly colors'));
    expect(
      Theme.of(context).extension<ChorePalette>()!.isColorblindSafe,
      isTrue,
    );
  });

  testWidgets('language override switches UI to German', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Deutsch'), 200);
    await tester.tap(find.text('Deutsch'));
    await tester.pumpAndSettle();

    expect(find.text('Einstellungen'), findsWidgets);
  });
}
