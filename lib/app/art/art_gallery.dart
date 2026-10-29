import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../theme/pixel.dart';
import 'art.dart';

/// Every sprite from `assets/art` in every palette of its group, on the day
/// and night backgrounds, at 1×, 2× and 4×. Debug builds only: for checking
/// new art (see docs/ART_GUIDE.md).
class ArtGallery extends StatelessWidget {
  const ArtGallery({super.key});

  static Future<void> open(BuildContext context) =>
      Navigator.of(context)
          .push(MaterialPageRoute<void>(builder: (_) => const ArtGallery()));

  static const _day = Color(0xFFF3E5C3);
  static const _night = Color(0xFF1C1A30);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entries = Sprites.all.entries.toList();
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context).artGallery)),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: entries.length,
        itemBuilder: (context, i) {
          final MapEntry(key: name, value: (sprites, group)) = entries[i];
          // Masks are tinted by the app: show them in the text colors.
          final palettes = group == 'mask'
              ? {
                  'day': [uiDay.frame],
                  'night': [const Color(0xFFF2F0E6)],
                }
              : paletteGroups[group]!;
          return Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$name  (${sprites.first.width}×${sprites.first.height}, '
                  '$group, ${sprites.length})',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                for (final MapEntry(key: palette, value: colors)
                    in palettes.entries)
                  // A mask's tint only ever appears on its own background.
                  for (final background
                      in group == 'mask'
                          ? [palette == 'day' ? _day : _night]
                          : [_day, _night])
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: ColoredBox(
                        color: background,
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Wrap(
                            spacing: 12,
                            runSpacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.end,
                            children: [
                              Text(
                                palette,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: background == _day
                                      ? uiDay.frame
                                      : const Color(0xFFF2F0E6),
                                ),
                              ),
                              for (final sprite in sprites)
                                for (final scale in const [1.0, 2.0, 4.0])
                                  PixelIcon(
                                    sprite,
                                    size: sprite.width * scale,
                                    palette: colors,
                                  ),
                            ],
                          ),
                        ),
                      ),
                    ),
              ],
            ),
          );
        },
      ),
    );
  }
}
