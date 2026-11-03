/// How hard fights are, chosen per person (game/balance.toml). Stored by
/// name: never rename values.
enum Difficulty { easy, balanced, hard }

/// What a [Difficulty] changes: fights only, never points or loot.
class DifficultyPreset {
  const DifficultyPreset({
    required this.bossHealth,
    required this.timingMs,
    required this.tempo,
  });

  /// Factor on the boss's health.
  final double bossHealth;

  /// Added to both timing windows (story mode keeps its own).
  final int timingMs;

  /// Factor on the boss's tempo.
  final double tempo;
}
