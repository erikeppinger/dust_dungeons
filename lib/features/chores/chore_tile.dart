import 'package:flutter/material.dart';

import '../../app/theme/pixel.dart';
import '../../app/theme/chore_palette.dart';
import '../../l10n/app_localizations.dart';
import 'chore_icons.dart';

/// Colorful card for one chore. Color is never the only signal: every tile
/// also shows its icon, title, due status and points.
class ChoreTile extends StatelessWidget {
  const ChoreTile({
    super.key,
    required this.title,
    required this.iconKey,
    required this.colorKey,
    required this.points,
    this.bonus = 0,
    this.doneToday = 0,
    this.doneBy,
    this.status,
    this.overdue = false,
    this.liftsCurse = false,
    this.onTap,
    this.onLongPress,
  });

  final String title;
  final String iconKey;
  final int colorKey;

  /// Total [points] including this many bonus points (shown separately).
  final int points;
  final int bonus;
  final int doneToday;

  /// Who did it today, when several people share the phone ("Sam"); the
  /// badge shows the names instead of a count.
  final String? doneBy;

  /// Due status line ("Due today", "2 days overdue"); hidden when `null`.
  final String? status;

  /// Highlights [status] as overdue (with an icon, not only color).
  final bool overdue;

  /// Doing it lifts the curse waiting for the next fight.
  final bool liftsCurse;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// Grid cell height that fits a tile at the device's font size: card
  /// margin, padding and icon are fixed, the four text lines (two for the
  /// title, status and points) grow with the text.
  static double heightFor(BuildContext context) {
    final textFactor = MediaQuery.textScalerOf(context).scale(14) / 14;
    return 96 + 72 * textFactor;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<ChorePalette>()!;
    final color = palette.colorFor(colorKey);
    final l10n = AppLocalizations.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      color: Color.alphaBlend(
        color.withValues(alpha: 0.18),
        theme.colorScheme.surfaceContainerLow,
      ),
      // One TalkBack node per tile: "Dusting, Due today, 17 points".
      child: MergeSemantics(
        child: Semantics(
          onLongPressHint: onLongPress == null ? null : l10n.editChore,
          child: InkWell(
            onTap: onTap,
            onLongPress: onLongPress,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: ShapeDecoration(
                          color: color,
                          shape: PixelBorder(
                            side: BorderSide(
                              color: PixelColors.of(context).frame,
                              width: pixelUnit,
                            ),
                          ),
                        ),
                        child: Icon(
                          choreIcon(iconKey),
                          color: palette.onColorFor(colorKey),
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Names can be long: the badge shrinks, never overflows.
                      Expanded(
                        child: Align(
                          alignment: AlignmentDirectional.topEnd,
                          child: doneToday > 0
                              ? _DoneBadge(count: doneToday, by: doneBy)
                              : liftsCurse
                              ? _CurseBadge(label: l10n.questLiftsCurse)
                              : null,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    title,
                    style: theme.textTheme.titleSmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (status case final status?)
                    Row(
                      children: [
                        if (overdue) ...[
                          Icon(
                            Icons.error_outline,
                            size: 14,
                            color: theme.colorScheme.error,
                          ),
                          const SizedBox(width: 3),
                        ],
                        Expanded(
                          child: Text(
                            status,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: overdue ? theme.colorScheme.error : null,
                              fontWeight: overdue ? FontWeight.bold : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  Text(
                    bonus > 0
                        ? l10n.pointsWithBonus(points, bonus)
                        : l10n.pointsValue(points),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact "✓ 2" badge; the tooltip/semantics carry the full "2× today".
class _DoneBadge extends StatelessWidget {
  const _DoneBadge({required this.count, this.by});

  final int count;
  final String? by;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: by == null
          ? AppLocalizations.of(context).doneTodayCount(count)
          : AppLocalizations.of(context).doneTodayBy(by!),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: ShapeDecoration(
          color: scheme.secondaryContainer,
          shape: PixelBorder(
            side: BorderSide(
              color: PixelColors.of(context).frame,
              width: pixelUnit,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check, size: 16, color: scheme.onSecondaryContainer),
            const SizedBox(width: 2),
            Flexible(
              child: Text(
                by ?? '$count',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: scheme.onSecondaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Lifts curse": an icon with its words as tooltip and label.
class _CurseBadge extends StatelessWidget {
  const _CurseBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Tooltip(
      message: label,
      child: Container(
        key: const ValueKey('lifts-curse'),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: ShapeDecoration(
          color: theme.colorScheme.errorContainer,
          shape: const StadiumBorder(),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_fix_high,
              size: 14,
              color: theme.colorScheme.onErrorContainer,
            ),
            const SizedBox(width: 3),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onErrorContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
