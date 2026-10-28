import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// Placeholder body for screens that are planned but not built yet.
class ComingSoon extends StatelessWidget {
  const ComingSoon({
    super.key,
    required this.icon,
    required this.message,
    required this.version,
  });

  final IconData icon;
  final String message;
  final String version;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 72, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              message,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context).comingInVersion(version),
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
