import 'package:flutter_test/flutter_test.dart';
import 'package:homework_and_chores/domain/default_chores.dart';
import 'package:homework_and_chores/domain/points.dart';
import 'package:homework_and_chores/features/chores/chore_icons.dart';
import 'package:homework_and_chores/features/chores/chore_titles.dart';
import 'package:homework_and_chores/l10n/app_localizations.dart';

void main() {
  test('built-in chore keys are unique', () {
    final keys = defaultChores.map((c) => c.key).toList();
    expect(keys.toSet(), hasLength(keys.length));
  });

  test('every built-in chore has a title, an icon and valid points', () {
    for (final seed in defaultChores) {
      expect(seedChoreTitles, contains(seed.key), reason: seed.key);
      expect(choreIcons, contains(seed.iconKey), reason: seed.key);
      expect(
        seed.basePoints,
        inInclusiveRange(minBasePoints, maxBasePoints),
        reason: seed.key,
      );
      expect(seed.basePoints % 5, 0, reason: 'slider step is 5');
    }
    expect(
      seedChoreTitles.keys.toSet(),
      defaultChores.map((c) => c.key).toSet(),
    );
  });

  test('default icon for new chores exists', () {
    expect(choreIcons, contains(defaultIconKey));
  });

  test('built-in titles are translated in every language', () async {
    for (final locale in AppLocalizations.supportedLocales) {
      final l10n = await AppLocalizations.delegate.load(locale);
      final titles = [for (final t in seedChoreTitles.values) t(l10n)];
      expect(titles.where((t) => t.isEmpty), isEmpty, reason: '$locale');
      expect(titles.toSet(), hasLength(titles.length), reason: '$locale');
    }
  });

  test('points are clamped to the allowed range', () {
    expect(pointsForCompletion(basePoints: 15), 15);
    expect(pointsForCompletion(basePoints: 0), minBasePoints);
    expect(pointsForCompletion(basePoints: 1000), maxBasePoints);
  });
}
