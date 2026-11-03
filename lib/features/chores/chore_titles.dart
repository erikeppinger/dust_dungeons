import '../../data/db/app_database.dart';
import '../../game/game_texts.dart';
import '../../l10n/app_localizations.dart';

/// Localized built-in title of a chore, or `null` for user chores.
String? builtInTitle(Chore chore, AppLocalizations l10n) =>
    switch (chore.seedKey) {
      final key? => gameQuestTitle(l10n, key),
      null => null,
    };

/// The title shown to the user: a custom title wins over the built-in one.
String choreTitle(Chore chore, AppLocalizations l10n) =>
    chore.customTitle ?? builtInTitle(chore, l10n) ?? chore.seedKey ?? '?';
