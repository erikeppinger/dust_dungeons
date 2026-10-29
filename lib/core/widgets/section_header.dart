import 'package:flutter/material.dart';

import '../../app/theme/pixel.dart';

/// Small pixel-font heading above a group of list tiles, with a square
/// marker like a game menu's cursor.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2, right: 8),
            child: ExcludeSemantics(
              child: SizedBox.square(
                dimension: 6,
                child: ColoredBox(color: theme.colorScheme.secondary),
              ),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.titleSmall?.copyWith(
                fontFamily: pixelFont,
                fontSize: 10,
                height: 1.6,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
