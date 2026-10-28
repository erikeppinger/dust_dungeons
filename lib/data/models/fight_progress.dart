import '../../domain/dates.dart';
import '../../domain/fight/boss.dart';
import '../db/app_database.dart';

/// Tokens, wins and tiers per boss family, derived from history like the
/// point ledger: tokens = completions of the family's chores − fights started.
/// An undo after the token was spent makes the balance negative; the next
/// completion of that family pays the debt back.
class FightProgress {
  factory FightProgress({
    required List<Completion> completions,
    required List<Chore> chores,
    required List<Fight> fights,
  }) {
    final familyOf = {for (final c in chores) c.id: c.family};
    final earned = <BossFamily, int>{};
    for (final c in completions) {
      final family = familyOf[c.choreId] ?? BossFamily.clutter;
      earned[family] = (earned[family] ?? 0) + 1;
    }
    final started = <BossFamily, int>{};
    final wins = <BossFamily, int>{};
    final best = <BossFamily, double>{};
    for (final f in fights) {
      started[f.family] = (started[f.family] ?? 0) + 1;
      if (f.result == FightResult.won) {
        wins[f.family] = (wins[f.family] ?? 0) + 1;
        final total = f.perfect + f.good + f.miss;
        final accuracy = total == 0 ? 0.0 : (f.perfect + f.good * 0.5) / total;
        if (accuracy > (best[f.family] ?? -1)) best[f.family] = accuracy;
      }
    }
    return FightProgress._(
      {
        for (final family in choreFamilies)
          family: (earned[family] ?? 0) - (started[family] ?? 0),
      },
      wins,
      best,
      [
        for (final f in fights)
          if (f.result == FightResult.won) (f.family, f.startedAt),
      ],
      [
        ...completions.map((c) => c.completedAt),
        ...fights.map((f) => f.startedAt),
      ].fold<DateTime?>(
        null,
        (first, d) => first == null || d.isBefore(first) ? d : first,
      ),
    );
  }

  FightProgress._(
    this._balance,
    this._wins,
    this._bestAccuracy,
    this._won,
    this._firstActivity,
  );

  /// The first completion or fight, `null` without any history.
  final DateTime? _firstActivity;

  final Map<BossFamily, int> _balance;
  final Map<BossFamily, int> _wins;
  final Map<BossFamily, double> _bestAccuracy;

  /// Every won fight with its start, oldest first.
  final List<(BossFamily, DateTime)> _won;

  /// Usable tokens (never negative; a debt shows as 0).
  int tokens(BossFamily family) =>
      (_balance[family] ?? 0) < 0 ? 0 : _balance[family]!;

  int get totalTokens => choreFamilies.fold(0, (sum, f) => sum + tokens(f));

  int wins(BossFamily family) => _wins[family] ?? 0;

  int get totalWins => _wins.values.fold(0, (sum, w) => sum + w);

  /// Best accuracy of a won fight, 0..1, or `null` if never won.
  double? bestAccuracy(BossFamily family) => _bestAccuracy[family];

  /// The tier the next fight against [family] has.
  int tier(BossFamily family) => tierForWins(wins(family));

  /// Whether [family] can be fought with a token (the Overlord needs none).
  bool canFight(BossFamily family) => tokens(family) > 0;

  Iterable<BossFamily> _wonInWeekOf(DateTime today) {
    final start = weekStartOf(today);
    final end = addDays(start, 7);
    return _won
        .where((w) => !w.$2.isBefore(start) && w.$2.isBefore(end))
        .map((w) => w.$1);
  }

  /// Wins against chore bosses in the week (Mon–Sun) of [today].
  int weekWins(DateTime today) => weekWinFamilies(today).length;

  /// The chore bosses won against in that week, one entry per win, in order
  /// (the road on the quest map).
  List<BossFamily> weekWinFamilies(DateTime today) =>
      _wonInWeekOf(today).where((f) => f != BossFamily.overlord).toList();

  /// The chore bosses beaten in that week, in the order first beaten: the
  /// Overlord borrows their rhythms.
  List<BossFamily> weekBeaten(DateTime today) =>
      weekWinFamilies(today).toSet().toList();

  /// Whether the Overlord was beaten in the week of [today].
  bool overlordBeaten(DateTime today) =>
      _wonInWeekOf(today).contains(BossFamily.overlord);

  /// The Overlord appears after enough wins and stays until beaten or the
  /// week ends.
  bool overlordReady(DateTime today) =>
      weekWins(today) >= overlordWinsNeeded && !overlordBeaten(today);

  /// Every week from the first activity to [today]'s, oldest first, for the
  /// realm: the chore-boss wins in order and whether the Overlord fell.
  List<WeekRecord> weekHistory(DateTime today) {
    final last = weekStartOf(today);
    final first = _firstActivity == null ? last : weekStartOf(_firstActivity);
    return [
      for (
        var monday = first.isAfter(last) ? last : first;
        !monday.isAfter(last);
        monday = addDays(monday, 7)
      )
        WeekRecord(monday, weekWinFamilies(monday), overlordBeaten(monday)),
    ];
  }
}

/// One week of the realm: its Monday, the chore-boss wins in order and
/// whether the Overlord was beaten.
class WeekRecord {
  const WeekRecord(this.monday, this.wins, this.beaten);

  final DateTime monday;
  final List<BossFamily> wins;
  final bool beaten;
}
