import '../../data/db/app_database.dart';
import '../../l10n/app_localizations.dart';

/// Localized titles of the built-in chores, by seed key.
/// Every key in `defaultChores` must be listed here (checked by a test).
final seedChoreTitles = <String, String Function(AppLocalizations)>{
  'dusting': (l) => l.choreDusting,
  'sweeping': (l) => l.choreSweeping,
  'vacuuming': (l) => l.choreVacuuming,
  'mopping': (l) => l.choreMopping,
  'dishes': (l) => l.choreDishes,
  'dishwasher': (l) => l.choreDishwasher,
  'laundry': (l) => l.choreLaundry,
  'hang_laundry': (l) => l.choreHangLaundry,
  'fold_laundry': (l) => l.choreFoldLaundry,
  'ironing': (l) => l.choreIroning,
  'clean_bathroom': (l) => l.choreCleanBathroom,
  'clean_toilet': (l) => l.choreCleanToilet,
  'clean_kitchen': (l) => l.choreCleanKitchen,
  'take_out_trash': (l) => l.choreTakeOutTrash,
  'recycling': (l) => l.choreRecycling,
  'change_bed_sheets': (l) => l.choreChangeBedSheets,
  'clean_windows': (l) => l.choreCleanWindows,
  'clean_fridge': (l) => l.choreCleanFridge,
  'groceries': (l) => l.choreGroceries,
  'water_plants': (l) => l.choreWaterPlants,
  'tidy_up': (l) => l.choreTidyUp,
};

/// Localized built-in title of a chore, or `null` for user chores.
String? builtInTitle(Chore chore, AppLocalizations l10n) =>
    seedChoreTitles[chore.seedKey]?.call(l10n);

/// The title shown to the user: a custom title wins over the built-in one.
String choreTitle(Chore chore, AppLocalizations l10n) =>
    chore.customTitle ?? builtInTitle(chore, l10n) ?? chore.seedKey ?? '?';
