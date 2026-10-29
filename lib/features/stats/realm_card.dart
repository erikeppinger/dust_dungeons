import 'package:flutter/material.dart';

import '../../app/theme/pixel.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/day_clock.dart';
import '../../data/models/fight_progress.dart';
import '../../data/providers.dart';
import '../../domain/dates.dart';
import '../../domain/fight/boss.dart';
import '../../domain/fight/overworld.dart';
import '../../l10n/app_localizations.dart';
import '../fight/boss_art.dart';
import '../world/quest_map.dart';

/// The realm: every week's quest map since the first chore, joined into one
/// world. Month shows a strip to scroll through; Year shows all weeks small,
/// and tapping one opens it in the strip.
class RealmCard extends ConsumerStatefulWidget {
  const RealmCard({super.key});

  @override
  ConsumerState<RealmCard> createState() => _RealmCardState();
}

class _RealmCardState extends ConsumerState<RealmCard> {
  bool _year = false;
  final _strip = ScrollController();

  /// Joined maps, kept while the weeks stay the same.
  (DateTime, int)? _joinedFor;
  List<WeekMap> _joined = const [];

  @override
  void dispose() {
    _strip.dispose();
    super.dispose();
  }

  List<WeekMap> _maps(List<WeekRecord> weeks) {
    final key = (weeks.first.monday, weeks.length);
    if (_joinedFor != key) {
      _joinedFor = key;
      _joined = joinWeeks([for (final w in weeks) WeekMap.forWeek(w.monday)]);
    }
    return _joined;
  }

  /// Shows week [index] in the month strip (the newest week is at its end).
  void _openWeek(int index, int count, double weekWidth) {
    setState(() => _year = false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_strip.hasClients) return;
      _strip.jumpTo(
        ((count - 1 - index) * weekWidth).clamp(
          0,
          _strip.position.maxScrollExtent,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final progress = ref.watch(fightProgressProvider).value;
    if (progress == null) return const SizedBox.shrink();
    final weeks = progress.weekHistory(ref.watch(todayProvider));
    final maps = _maps(weeks);
    final hero = HeroLook.of(ref.watch(currentProfileProvider));
    final crowns = weeks.where((w) => w.beaten).length;
    final lairs = weeks.fold(
      0,
      (sum, w) => sum + w.wins.length.clamp(0, overlordWinsNeeded),
    );

    Widget stat(String label, int value) => Expanded(
      child: Column(
        children: [
          Text('$value', style: theme.textTheme.titleLarge),
          Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                stat(l10n.realmWeeks, weeks.length),
                stat(l10n.realmCrowns, crowns),
                stat(l10n.realmLairs, lairs),
              ],
            ),
            const SizedBox(height: 12),
            Center(
              child: SegmentedButton<bool>(
                segments: [
                  ButtonSegment(
                    value: false,
                    icon: const Icon(Icons.view_week_outlined),
                    label: Text(l10n.realmMonth),
                  ),
                  ButtonSegment(
                    value: true,
                    icon: const Icon(Icons.grid_view),
                    label: Text(l10n.realmYear),
                  ),
                ],
                selected: {_year},
                onSelectionChanged: (s) => setState(() => _year = s.first),
              ),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, box) {
                final width = box.maxWidth;
                // Month: a week and a half across, so the next one peeks in.
                // Year: four weeks to a row.
                final monthWeek = width / 1.5;
                return PixelFrame(
                  child: _year
                      ? _YearGrid(
                          weeks: weeks,
                          maps: maps,
                          weekWidth: width / 4,
                          onOpen: (i) => _openWeek(i, weeks.length, monthWeek),
                        )
                      : SizedBox(
                          height: monthWeek * mapRows / mapCols,
                          child: ListView.builder(
                            key: const ValueKey('realm-strip'),
                            controller: _strip,
                            scrollDirection: Axis.horizontal,
                            // Opens at the newest week, older ones to the left.
                            reverse: true,
                            itemCount: weeks.length,
                            itemExtent: monthWeek,
                            itemBuilder: (context, i) {
                              final index = weeks.length - 1 - i;
                              return _RealmWeek(
                                week: weeks[index],
                                map: maps[index],
                                previous: index > 0 ? maps[index - 1] : null,
                                next: index < maps.length - 1
                                    ? maps[index + 1]
                                    : null,
                                hero: index == weeks.length - 1 ? hero : null,
                                detailed: true,
                              );
                            },
                          ),
                        ),
                );
              },
            ),
            if (_year) ...[
              const SizedBox(height: 8),
              Text(l10n.realmHint, style: theme.textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }
}

class _YearGrid extends StatelessWidget {
  const _YearGrid({
    required this.weeks,
    required this.maps,
    required this.weekWidth,
    required this.onOpen,
  });

  final List<WeekRecord> weeks;
  final List<WeekMap> maps;
  final double weekWidth;
  final void Function(int index) onOpen;

  @override
  Widget build(BuildContext context) => Column(
    key: const ValueKey('realm-year'),
    children: [
      for (var row = 0; row < weeks.length; row += 4)
        Row(
          children: [
            for (var i = row; i < row + 4 && i < weeks.length; i++)
              SizedBox(
                width: weekWidth,
                height: weekWidth * mapRows / mapCols,
                child: GestureDetector(
                  onTap: () => onOpen(i),
                  child: _RealmWeek(
                    week: weeks[i],
                    map: maps[i],
                    previous: i % 4 > 0 ? maps[i - 1] : null,
                    next: i % 4 < 3 && i < maps.length - 1 ? maps[i + 1] : null,
                    detailed: false,
                  ),
                ),
              ),
          ],
        ),
    ],
  );
}

/// One week of the realm, with its label and (in detail) the beaten bosses.
class _RealmWeek extends StatelessWidget {
  const _RealmWeek({
    required this.week,
    required this.map,
    required this.previous,
    required this.next,
    required this.detailed,
    this.hero,
  });

  final WeekRecord week;
  final WeekMap map;
  final WeekMap? previous, next;
  final HeroLook? hero;
  final bool detailed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (_, number) = isoWeek(week.monday);
    final reached = week.wins.length.clamp(0, overlordWinsNeeded);
    return Semantics(
      container: true,
      button: !detailed,
      label: week.beaten
          ? l10n.realmWeekBeaten(number)
          : l10n.realmWeekProgress(number, reached, overlordWinsNeeded),
      child: ExcludeSemantics(
        child: LayoutBuilder(
          builder: (context, box) {
            final tile = box.maxWidth / mapCols;
            return Stack(
              children: [
                Positioned.fill(
                  child: RepaintBoundary(
                    child: CustomPaint(
                      painter: WeekPainter(
                        map: map,
                        reached: reached,
                        beaten: week.beaten,
                        hero: hero,
                        previous: previous,
                        next: next,
                        detailed: detailed,
                      ),
                    ),
                  ),
                ),
                if (detailed)
                  for (var i = 1; i <= reached; i++)
                    Positioned(
                      left: (map.route[i].x + 0.35) * tile,
                      top: (map.route[i].y - 0.55) * tile,
                      width: tile * 1.1,
                      height: tile * 1.1,
                      child: BossArt(
                        family: week.wins[i - 1],
                        size: tile * 1.1,
                      ),
                    ),
                Positioned(
                  left: 3,
                  top: 3,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 1,
                    ),
                    decoration: const BoxDecoration(color: Color(0xCC1C1A30)),
                    child: Text(
                      l10n.realmWeekLabel(number),
                      style: const TextStyle(
                        color: Color(0xFFF2F0E6),
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
