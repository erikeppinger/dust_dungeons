import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/chore_palette.dart';
import '../../data/db/app_database.dart';
import '../../data/providers.dart';
import '../../l10n/app_localizations.dart';
import '../chores/chore_icons.dart';
import '../chores/chore_titles.dart';
import '../notifications/notification_settings.dart';
import '../settings/settings_controller.dart';
import '../settings/settings_pages.dart';
import '../../app/art/art.dart';
import '../../app/theme/pixel.dart';

/// First start: welcome and language, which chores apply, then colors and
/// reminders. Everything can be changed later in the settings.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  static const _pages = 3;
  final _controller = PageController();
  int _page = 0;

  /// Chores the user unticked; archived when onboarding finishes.
  final _unticked = <int>{};
  bool _finishing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _go(int page) => _controller.animateToPage(
    page,
    duration: MediaQuery.disableAnimationsOf(context)
        ? const Duration(milliseconds: 1)
        : const Duration(milliseconds: 300),
    curve: Curves.easeOut,
  );

  Future<void> _finish({required bool applyChoices}) async {
    if (_finishing) return;
    _finishing = true;
    if (applyChoices) {
      final chores = ref.read(choreRepositoryProvider);
      for (final id in _unticked) {
        await chores.setArchived(id, archived: true);
      }
    }
    ref
        .read(settingsProvider.notifier)
        .update((s) => s.copyWith(onboardingDone: true));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final last = _page == _pages - 1;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (p) => setState(() => _page = p),
                children: [
                  const _WelcomePage(),
                  _ChoresPage(
                    unticked: _unticked,
                    onChanged: (id, on) => setState(
                      () => on ? _unticked.remove(id) : _unticked.add(id),
                    ),
                  ),
                  const _SetupPage(),
                ],
              ),
            ),
            Semantics(
              label: l10n.onboardingStep(_page + 1, _pages),
              child: ExcludeSemantics(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < _pages; i++)
                      Container(
                        width: i == _page ? 20 : 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: i == _page
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.outline,
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              // Side by side when they fit, stacked with large text.
              child: OverflowBar(
                alignment: last
                    ? MainAxisAlignment.end
                    : MainAxisAlignment.spaceBetween,
                overflowAlignment: OverflowBarAlignment.end,
                overflowSpacing: 8,
                children: [
                  if (!last)
                    TextButton(
                      onPressed: () => _finish(applyChoices: false),
                      child: Text(l10n.onboardingSkip),
                    ),
                  FilledButton(
                    onPressed: last
                        ? () => _finish(applyChoices: true)
                        : () => _go(_page + 1),
                    child: Text(
                      last ? l10n.onboardingDone : l10n.onboardingNext,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Page extends StatelessWidget {
  const _Page({required this.title, required this.children, this.icon});

  final Sprite? icon;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
      children: [
        if (icon case final icon?) ...[
          PixelIcon(icon, size: 72, color: theme.colorScheme.primary),
          const SizedBox(height: 16),
        ],
        Semantics(
          header: true,
          child: Text(title, style: theme.textTheme.headlineSmall),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }
}

class _WelcomePage extends ConsumerWidget {
  const _WelcomePage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final locale = ref.watch(settingsProvider).locale?.languageCode;
    final controller = ref.read(settingsProvider.notifier);
    return _Page(
      icon: Sprites.questCleaningServices,
      title: l10n.onboardingWelcomeTitle,
      children: [
        Text(l10n.onboardingWelcomeBody, style: theme.textTheme.bodyLarge),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PixelIcon(Sprites.uiLock, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(child: Text(l10n.onboardingPrivacy)),
          ],
        ),
        const SizedBox(height: 24),
        Text(l10n.settingsLanguage, style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: Text(l10n.languageSystem),
              selected: locale == null,
              onSelected: (_) => controller.setLocale(null),
            ),
            for (final entry in languageNames.entries)
              ChoiceChip(
                label: Text(entry.value),
                selected: locale == entry.key,
                onSelected: (_) => controller.setLocale(Locale(entry.key)),
              ),
          ],
        ),
      ],
    );
  }
}

class _ChoresPage extends ConsumerWidget {
  const _ChoresPage({required this.unticked, required this.onChanged});

  final Set<int> unticked;
  final void Function(int id, bool on) onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final palette = Theme.of(context).extension<ChorePalette>()!;
    final chores = ref.watch(activeChoresProvider).value ?? const <Chore>[];
    return _Page(
      title: l10n.onboardingChoresTitle,
      children: [
        Text(l10n.onboardingChoresBody),
        const SizedBox(height: 8),
        for (final chore in chores)
          CheckboxListTile(
            key: ValueKey('onboarding-chore-${chore.id}'),
            contentPadding: EdgeInsets.zero,
            secondary: CircleAvatar(
              backgroundColor: palette.colorFor(chore.colorKey),
              child: ChoreIcon(
                chore.iconKey,
                color: palette.onColorFor(chore.colorKey),
              ),
            ),
            title: Text(choreTitle(chore, l10n)),
            value: !unticked.contains(chore.id),
            onChanged: (on) => onChanged(chore.id, on ?? false),
          ),
      ],
    );
  }
}

class _SetupPage extends ConsumerWidget {
  const _SetupPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);
    return _Page(
      title: l10n.onboardingSetupTitle,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          secondary: const PixelIcon(Sprites.uiEye),
          title: Text(l10n.settingsColorblind),
          subtitle: Text(l10n.settingsColorblindSubtitle),
          value: settings.colorblindSafe,
          onChanged: controller.setColorblindSafe,
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          secondary: const PixelIcon(Sprites.uiBell),
          title: Text(l10n.onboardingNotifications),
          subtitle: Text(l10n.onboardingNotificationsSubtitle),
          value: settings.notificationsEnabled,
          onChanged: (on) => setNotificationsEnabled(context, ref, on),
        ),
      ],
    );
  }
}
