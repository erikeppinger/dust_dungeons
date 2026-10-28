// On-device smoke test. Run on an emulator before every commit:
//   flutter test integration_test -d emulator-5554
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homework_and_chores/app/app.dart';
import 'package:homework_and_chores/app/theme/chore_palette.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('app starts and every tab and setting works', (tester) async {
    tester.platformDispatcher.localesTestValue = [const Locale('en')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await tester.pumpWidget(const ProviderScope(child: ChoresApp()));
    await tester.pumpAndSettle();

    // Every tab opens.
    for (final tab in ['Plan', 'World', 'Stats', 'Settings', 'Today']) {
      await tester.tap(find.widgetWithText(NavigationDestination, tab));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(AppBar, tab), findsOneWidget);
    }

    await tester.tap(find.widgetWithText(NavigationDestination, 'Settings'));
    await tester.pumpAndSettle();

    // Theme modes.
    for (final (label, mode) in [
      ('Dark', ThemeMode.dark),
      ('Light', ThemeMode.light),
      ('System', ThemeMode.system),
    ]) {
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      expect(
        tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
        mode,
      );
    }

    // Colorblind palette.
    await tester.tap(find.text('Colorblind-friendly colors'));
    await tester.pumpAndSettle();
    final context = tester.element(find.text('Colorblind-friendly colors'));
    expect(
      Theme.of(context).extension<ChorePalette>()!.isColorblindSafe,
      isTrue,
    );

    // Language override to German and back.
    await tester.scrollUntilVisible(find.text('Deutsch'), 200);
    await tester.tap(find.text('Deutsch'));
    await tester.pumpAndSettle();
    expect(find.text('Einstellungen'), findsWidgets);

    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsWidgets);
  });
}
