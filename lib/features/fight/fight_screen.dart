import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/app_database.dart';
import '../../data/providers.dart';
import '../../data/repositories/fight_repository.dart';
import '../../domain/fight/boss.dart';
import '../../domain/fight/echo_duel.dart';
import '../../l10n/app_localizations.dart';
import '../settings/settings_controller.dart';
import 'boss_art.dart';
import 'fight_controller.dart';
import 'fight_sounds.dart';

/// One boss fight. Starting it spends a token; leaving early or putting the
/// app in the background abandons it (the token stays spent).
class FightScreen extends ConsumerStatefulWidget {
  const FightScreen({super.key, required this.family, required this.tier});

  final BossFamily family;
  final int tier;

  static bool _opening = false;

  /// Opens a fight. A second call while one is opening or open is ignored,
  /// so a double tap cannot start (and pay for) two fights.
  static Future<void> open(
    BuildContext context,
    BossFamily family,
    int tier,
  ) async {
    if (_opening) return;
    _opening = true;
    try {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => FightScreen(family: family, tier: tier),
        ),
      );
    } finally {
      _opening = false;
    }
  }

  @override
  ConsumerState<FightScreen> createState() => _FightScreenState();
}

class _FightScreenState extends ConsumerState<FightScreen> {
  late final FightController _controller;
  late final FightRepository _repo;
  late final Future<int> _fightId;
  late final AppLifecycleListener _lifecycle;
  bool _recorded = false;
  bool _abandoned = false;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    final level = ref.read(progressStatsProvider).value?.level ?? 1;
    final sounds = ref.read(fightSoundsProvider);
    if (sounds is PooledFightSounds && settings.fightSound) {
      unawaited(sounds.preload());
    }
    // Kept in a field: recording the result may finish after the screen is
    // gone, when `ref` can no longer be used.
    _repo = ref.read(fightRepositoryProvider);
    _fightId = _repo.start(
      profileId: ref.read(currentProfileIdProvider),
      family: widget.family,
      tier: widget.tier,
      storyMode: settings.fightStoryMode,
    );
    _controller = FightController(
      duel: EchoDuel(
        family: widget.family,
        tier: widget.tier,
        hero: HeroStats.forLevel(level),
        storyMode: settings.fightStoryMode,
        seed: DateTime.now().microsecondsSinceEpoch,
      ),
      sounds: sounds,
      sound: settings.fightSound,
      haptics: settings.fightHaptics,
      onFinished: (outcome) => _record(
        outcome == DuelOutcome.won ? FightResult.won : FightResult.lost,
      ),
    )..start();
    // A rhythm fight cannot continue in the background.
    _lifecycle = AppLifecycleListener(onHide: _abandon);
  }

  Future<void> _record(FightResult result) async {
    if (_recorded) return;
    _recorded = true;
    final duel = _controller.duel;
    await _repo.finish(
      await _fightId,
      result: result,
      perfect: duel.perfect,
      good: duel.good,
      miss: duel.miss,
    );
  }

  bool get _over => _controller.stage == FightStage.finished || _abandoned;

  /// Stops the fight and records it as abandoned (the token stays spent).
  void _stopAbandoned() {
    _controller.stop();
    _abandoned = true;
    unawaited(_record(FightResult.abandoned));
  }

  void _abandon() {
    if (_over) return;
    setState(_stopAbandoned);
  }

  Future<void> _confirmLeave() async {
    if (_over) {
      Navigator.of(context).pop();
      return;
    }
    final l10n = AppLocalizations.of(context);
    _controller.pause();
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.fightLeaveTitle),
        content: Text(l10n.fightLeaveBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.fightStay),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.fightLeave),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (leave == true) {
      _abandon();
      Navigator.of(context).pop();
    } else {
      _controller.resume();
    }
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    if (!_over) _stopAbandoned();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF43A047),
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
    );
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Theme(
        data: dark,
        child: PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) unawaited(_confirmLeave());
          },
          child: Scaffold(
            body: SafeArea(
              child: ListenableBuilder(
                listenable: _controller,
                builder: (context, _) => _abandoned
                    ? _Abandoned(onBack: () => Navigator.of(context).pop())
                    : _controller.stage == FightStage.finished
                    ? _Result(family: widget.family, duel: _controller.duel)
                    : _Duel(controller: _controller, onLeave: _confirmLeave),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Duel extends StatelessWidget {
  const _Duel({required this.controller, required this.onLeave});

  final FightController controller;
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final c = controller;
    final duel = c.duel;
    final cleaned = 1 - duel.bossHp / duel.bossMaxHp;
    final hitNow =
        c.stage == FightStage.judged && c.lastHits.any((h) => h != Hit.miss);
    final status = switch (c.stage) {
      FightStage.intro => l10n.fightGetReady,
      FightStage.call => l10n.fightListen(c.pattern!.beatsMs.length),
      FightStage.echo => l10n.fightYourTurn,
      FightStage.judged => l10n.fightJudged(
        c.lastHits.where((h) => h == Hit.perfect).length,
        c.lastHits.where((h) => h == Hit.good).length,
        c.lastHits.where((h) => h == Hit.miss).length,
      ),
      FightStage.finished => '',
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                tooltip: l10n.fightLeave,
                onPressed: onLeave,
                icon: const Icon(Icons.close),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bossName(l10n, duel.family),
                      style: theme.textTheme.titleMedium,
                    ),
                    Text(
                      l10n.fightTierPhase(duel.tier, duel.phase + 1),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (duel.combo >= 2)
                Chip(label: Text(l10n.fightCombo(duel.combo))),
            ],
          ),
          const SizedBox(height: 8),
          BossArt(
            family: duel.family,
            size: 170,
            mood: hitNow ? BossMood.hit : BossMood.idle,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(l10n.fightCleaned, style: theme.textTheme.bodySmall),
              const Spacer(),
              Text(
                '${(cleaned * 100).round()} %',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: cleaned,
            minHeight: 12,
            borderRadius: BorderRadius.circular(6),
            semanticsLabel: l10n.fightCleaned,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            decoration: BoxDecoration(
              color: c.stage == FightStage.echo
                  ? scheme.primaryContainer
                  : scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              status,
              key: const ValueKey('fight-status'),
              style: theme.textTheme.titleSmall,
            ),
          ),
          const SizedBox(height: 12),
          _BeatRow(controller: c),
          Expanded(
            child: Center(
              child: _Pad(enabled: c.stage == FightStage.echo, onTap: c.tap),
            ),
          ),
          Row(
            children: [
              Semantics(
                label: l10n.fightHealth(duel.heroHp, duel.hero.maxHp),
                child: ExcludeSemantics(
                  child: Wrap(
                    spacing: 2,
                    children: [
                      for (var i = 0; i < duel.hero.maxHp; i++)
                        Icon(
                          i < duel.heroHp
                              ? Icons.favorite
                              : Icons.favorite_border,
                          size: 22,
                          color: i < duel.heroHp
                              ? const Color(0xFFF28B82)
                              : scheme.outline,
                        ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              if (duel.storyMode)
                Text(l10n.fightSettingStory, style: theme.textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}

/// The pattern's beats: lit during the call, filling up during the echo,
/// and showing each judgement (shape + text, not color alone) afterwards.
class _BeatRow extends StatelessWidget {
  const _BeatRow({required this.controller});

  final FightController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final c = controller;
    final count = c.pattern?.beatsMs.length ?? 0;
    if (c.stage == FightStage.judged) {
      return Wrap(
        spacing: 12,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: [
          for (final hit in c.lastHits)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  switch (hit) {
                    Hit.perfect => Icons.check_circle,
                    Hit.good => Icons.adjust,
                    Hit.miss => Icons.cancel,
                  },
                  color: hit == Hit.miss ? scheme.error : scheme.primary,
                  size: 28,
                ),
                Text(switch (hit) {
                  Hit.perfect => l10n.hitPerfect,
                  Hit.good => l10n.hitGood,
                  Hit.miss => l10n.hitMiss,
                }, style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
        ],
      );
    }
    return SizedBox(
      height: 48,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < count; i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 9),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 80),
                width: i == c.litBeat ? 34 : 22,
                height: i == c.litBeat ? 34 : 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: c.stage == FightStage.call
                      ? (i <= c.litBeat ? scheme.onSurface : null)
                      : (i < c.tapCount ? scheme.primary : null),
                  border: Border.all(color: scheme.outline, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Pad extends StatelessWidget {
  const _Pad({required this.enabled, required this.onTap});

  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      enabled: enabled,
      label: enabled ? l10n.fightPad : l10n.fightPadWait,
      child: Listener(
        key: const ValueKey('fight-pad'),
        behavior: HitTestBehavior.opaque,
        // Raw touch-down, no gesture arena: timing is what counts.
        onPointerDown: enabled ? (_) => onTap() : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 220,
          height: 220,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: enabled ? scheme.primary : scheme.surfaceContainer,
            border: Border.all(
              color: enabled ? scheme.primaryContainer : scheme.outlineVariant,
              width: enabled ? 10 : 3,
            ),
          ),
          alignment: Alignment.center,
          child: ExcludeSemantics(
            child: Text(
              enabled ? l10n.fightPad : l10n.fightPadWait,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: enabled ? scheme.onPrimary : scheme.outline,
                fontSize: enabled ? 22 : 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Result extends ConsumerWidget {
  const _Result({required this.family, required this.duel});

  final BossFamily family;
  final EchoDuel duel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final won = duel.outcome == DuelOutcome.won;
    final progress = ref.watch(fightProgressProvider).value;
    final wins = progress?.wins(family) ?? 0;
    final tokensLeft = progress?.tokens(family) ?? 0;
    final boss = bossName(l10n, family);

    Widget stat(String value, String label) => Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            children: [
              Text(value, style: theme.textTheme.headlineSmall),
              Text(label, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      children: [
        Center(
          child: won
              ? Icon(
                  Icons.emoji_events,
                  size: 120,
                  color: const Color(0xFFE6C463),
                  semanticLabel: trophyName(l10n, family),
                )
              : BossArt(family: family, size: 140),
        ),
        const SizedBox(height: 12),
        Text(
          won ? l10n.fightWonTitle(boss) : l10n.fightLostTitle(boss),
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: 6),
        Text(
          won
              ? (wins <= 1
                    ? l10n.fightNewTrophy(trophyName(l10n, family))
                    : l10n.fightTrophyAgain(trophyName(l10n, family), wins))
              : l10n.fightLostHint,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            stat('${duel.perfect}', l10n.hitPerfect),
            stat('${duel.good}', l10n.hitGood),
            stat('${duel.miss}', l10n.hitMiss),
          ],
        ),
        Card(
          child: Column(
            children: [
              ListTile(
                title: Text(l10n.fightAccuracy),
                trailing: Text('${(duel.accuracy * 100).round()} %'),
              ),
              ListTile(
                title: Text(l10n.fightBestCombo),
                trailing: Text('${max(duel.bestCombo, 0)}'),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            l10n.fightNoPoints,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.fightBack),
        ),
        if (tokensLeft > 0) ...[
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pushReplacement(
              MaterialPageRoute<void>(
                builder: (_) =>
                    FightScreen(family: family, tier: progress!.tier(family)),
              ),
            ),
            child: Text(l10n.fightAgain(tokensLeft)),
          ),
        ],
      ],
    );
  }
}

class _Abandoned extends StatelessWidget {
  const _Abandoned({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.fightAbandoned,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onBack, child: Text(l10n.fightBack)),
          ],
        ),
      ),
    );
  }
}
