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
        for (final family in BossFamily.values)
          family: (earned[family] ?? 0) - (started[family] ?? 0),
      },
      wins,
      best,
    );
  }

  FightProgress._(this._balance, this._wins, this._bestAccuracy);

  final Map<BossFamily, int> _balance;
  final Map<BossFamily, int> _wins;
  final Map<BossFamily, double> _bestAccuracy;

  /// Usable tokens (never negative; a debt shows as 0).
  int tokens(BossFamily family) =>
      (_balance[family] ?? 0) < 0 ? 0 : _balance[family]!;

  int get totalTokens => BossFamily.values.fold(0, (sum, f) => sum + tokens(f));

  int wins(BossFamily family) => _wins[family] ?? 0;

  int get totalWins => _wins.values.fold(0, (sum, w) => sum + w);

  /// Best accuracy of a won fight, 0..1, or `null` if never won.
  double? bestAccuracy(BossFamily family) => _bestAccuracy[family];

  /// The tier the next fight against [family] has.
  int tier(BossFamily family) => tierForWins(wins(family));

  bool canFight(BossFamily family) => tokens(family) > 0;
}
