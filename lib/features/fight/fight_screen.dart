import 'dart:async';

import '../../app/theme/app_theme.dart';
import '../../app/theme/chore_palette.dart';
import '../../app/theme/pixel.dart';

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/app_database.dart';
import '../../data/providers.dart';
import '../../data/repositories/fight_repository.dart';
import '../../data/repositories/shop_repository.dart';
import '../../domain/fight/boss.dart';
import '../../domain/fight/echo_duel.dart';
import '../../domain/fight/shop.dart';
import '../../l10n/app_localizations.dart';
import '../settings/settings_controller.dart';
import '../../domain/screen_time.dart';
import '../screen_time/screen_time_providers.dart';
import 'boss_art.dart';
import 'fight_controller.dart';
import 'fight_sounds.dart';
import 'lane_field.dart';

/// One boss fight. Starting it spends a token (the Overlord needs none);
/// leaving early or putting the app in the background abandons it.
class FightScreen extends ConsumerStatefulWidget {
  const FightScreen({
    super.key,
    required this.family,
    required this.tier,
    this.loadout = Loadout.none,
    this.motifs = const [],
  });

  final BossFamily family;
  final int tier;

  /// The gear owned when the fight starts.
  final Loadout loadout;

  /// For the Overlord: the bosses beaten this week, whose rhythms it plays.
  final List<BossFamily> motifs;

  bool get overlord => family == BossFamily.overlord;

  static bool _opening = false;

  /// Opens a fight. A second call while one is opening or open is ignored,
  /// so a double tap cannot start (and pay for) two fights.
  static Future<void> open(
    BuildContext context,
    BossFamily family,
    int tier,
    Loadout loadout, {
    List<BossFamily> motifs = const [],
  }) async {
    if (_opening) return;
    _opening = true;
    try {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => FightScreen(
            family: family,
            tier: tier,
            loadout: loadout,
            motifs: motifs,
          ),
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
  late final ShopRepository _shop;
  late final int _profileId;
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
    _shop = ref.read(shopRepositoryProvider);
    _profileId = ref.read(currentProfileIdProvider);
    _fightId = _repo.start(
      profileId: _profileId,
      family: widget.family,
      tier: widget.tier,
      storyMode: settings.fightStoryMode,
    );
    final base = HeroStats.forLevel(level);
    final hero = HeroStats(
      maxHp: tiredMaxHp(base.maxHp, tired: ref.read(tiredProvider)),
      damage: base.damage,
    );
    final seed = DateTime.now().microsecondsSinceEpoch;
    _controller = FightController(
      duel: widget.overlord
          ? OverlordDuel(
              tier: widget.tier,
              hero: hero,
              motifs: widget.motifs,
              loadout: widget.loadout,
              storyMode: settings.fightStoryMode,
              slowMode: settings.fightSlowMode,
              seed: seed,
            )
          : EchoDuel(
              family: widget.family,
              tier: widget.tier,
              hero: hero,
              loadout: widget.loadout,
              storyMode: settings.fightStoryMode,
              slowMode: settings.fightSlowMode,
              seed: seed,
            ),
      sounds: sounds,
      sound: settings.fightSound,
      haptics: settings.fightHaptics,
      latencyMs: settings.fightLatencyMs,
      // A loss is recorded only when the player moves on: Second Wind can
      // still turn it around.
      onFinished: (outcome) {
        if (outcome == DuelOutcome.won) unawaited(_record(FightResult.won));
      },
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

  bool _reviving = false;

  /// Spends a Second Wind and continues the lost duel. Guarded so a double
  /// tap cannot spend two.
  Future<void> _useSecondWind() async {
    if (_reviving || _controller.duel.outcome != DuelOutcome.lost) return;
    _reviving = true;
    try {
      if (!await _shop.use(_profileId, secondWindItem) || !mounted) return;
      _controller.duel.revive();
      _controller.resume();
    } finally {
      _reviving = false;
    }
  }

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
        content: Text(
          widget.overlord ? l10n.fightLeaveBodyOverlord : l10n.fightLeaveBody,
        ),
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
    if (!_over) {
      _stopAbandoned();
    } else if (!_recorded && _controller.duel.outcome == DuelOutcome.lost) {
      unawaited(_record(FightResult.lost));
    }
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Fights always take place at night, in the app's dungeon colors.
    final dark = buildAppTheme(
      brightness: Brightness.dark,
      colorblindSafe:
          Theme.of(context).extension<ChorePalette>()?.isColorblindSafe ??
          false,
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
                    ? _Abandoned(
                        overlord: widget.overlord,
                        onBack: () => Navigator.of(context).pop(),
                      )
                    : _controller.stage == FightStage.finished
                    ? _Result(
                        family: widget.family,
                        duel: _controller.duel,
                        motifs: widget.motifs,
                        onSecondWind: _useSecondWind,
                      )
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
    final lanes = c.stage == FightStage.lanes;
    final hitNow = lanes
        ? c.lastLaneHit != null && c.lastLaneHit != Hit.miss
        : c.stage == FightStage.judged && c.lastHits.any((h) => h != Hit.miss);
    final status = switch (c.stage) {
      FightStage.intro => l10n.fightGetReady,
      FightStage.call => l10n.fightListen(c.pattern!.beatsMs.length),
      FightStage.echo => l10n.fightYourTurn,
      FightStage.judged => l10n.fightJudged(
        c.lastHits.where((h) => h == Hit.perfect).length,
        c.lastHits.where((h) => h == Hit.good).length,
        c.lastHits.where((h) => h == Hit.miss).length,
      ),
      FightStage.lanes => switch (c.lastLaneHit) {
        null => l10n.fightLanes,
        Hit.perfect => l10n.hitPerfect,
        Hit.good => l10n.hitGood,
        Hit.miss => l10n.hitMiss,
      },
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
                      l10n.fightTierPhase(
                        duel.tier,
                        duel.phase + 1,
                        duel.phaseCount,
                      ),
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
            size: lanes ? 96 : 170,
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
          PixelBar(
            value: cleaned,
            segments: 20,
            height: 16,
            semanticsLabel: l10n.fightCleaned,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            decoration: ShapeDecoration(
              color: c.stage == FightStage.echo || lanes
                  ? scheme.primaryContainer
                  : scheme.surfaceContainerHighest,
              shape: PixelBorder(
                side: BorderSide(
                  color: PixelColors.of(context).frame,
                  width: pixelUnit,
                ),
              ),
            ),
            child: Text(
              status,
              key: const ValueKey('fight-status'),
              style: theme.textTheme.titleSmall,
            ),
          ),
          const SizedBox(height: 12),
          if (lanes)
            Expanded(child: LaneField(controller: c))
          else ...[
            _BeatRow(controller: c),
            Expanded(
              child: Center(
                child: _Pad(enabled: c.stage == FightStage.echo, onTap: c.tap),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Semantics(
                label: l10n.fightHealth(duel.heroHp, duel.hero.maxHp),
                child: ExcludeSemantics(
                  child: Wrap(
                    spacing: 2,
                    children: [
                      for (var i = 0; i < duel.hero.maxHp; i++)
                        PixelHeart(full: i < duel.heroHp),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              if (duel.storyMode)
                Text(l10n.fightSettingStory, style: theme.textTheme.bodySmall)
              else if (duel.shieldReady)
                Text(l10n.fightShieldReady, style: theme.textTheme.bodySmall),
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
  const _Result({
    required this.family,
    required this.duel,
    required this.motifs,
    required this.onSecondWind,
  });

  final BossFamily family;
  final EchoDuel duel;
  final List<BossFamily> motifs;
  final VoidCallback onSecondWind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final won = duel.outcome == DuelOutcome.won;
    final progress = ref.watch(fightProgressProvider).value;
    final wins = progress?.wins(family) ?? 0;
    final tokensLeft = progress?.tokens(family) ?? 0;
    final overlord = family == BossFamily.overlord;
    // The Overlord needs no token: a lost fight can simply be retried.
    final canRetry = overlord ? !won : tokensLeft > 0;
    final secondWinds =
        ref.watch(inventoryProvider).value?[secondWindItem.key] ?? 0;
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
              : (overlord ? l10n.fightLostHintOverlord : l10n.fightLostHint),
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
        if (!won && secondWinds > 0) ...[
          FilledButton.icon(
            onPressed: onSecondWind,
            icon: const Icon(Icons.air),
            label: Text(l10n.fightSecondWind(secondWinds)),
          ),
          const SizedBox(height: 8),
        ],
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.fightBack),
        ),
        if (canRetry && progress != null) ...[
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pushReplacement(
              MaterialPageRoute<void>(
                builder: (_) => FightScreen(
                  family: family,
                  tier: progress.tier(family),
                  loadout: duel.loadout,
                  motifs: motifs,
                ),
              ),
            ),
            child: Text(
              overlord ? l10n.fightRetry : l10n.fightAgain(tokensLeft),
            ),
          ),
        ],
      ],
    );
  }
}

class _Abandoned extends StatelessWidget {
  const _Abandoned({required this.overlord, required this.onBack});

  final bool overlord;
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
              overlord ? l10n.fightAbandonedOverlord : l10n.fightAbandoned,
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
