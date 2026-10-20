import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/widgets/common.dart';
import '../history/history_screen.dart';
import 'call_protection.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final prefs = ref.watch(preferencesProvider);
    final controller = ref.read(preferencesProvider.notifier);
    return PageBody(
      children: [
        PageHeading(l.settings, l.tagline),
        ListTile(
          leading: const Icon(Icons.menu_book_outlined),
          title: Text(l.education),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/education'),
        ),
        const CallProtectionCard(),
        const SizedBox(height: 16),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l.language,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              SegmentedButton<String>(
                segments: [
                  ButtonSegment(value: 'ru', label: Text(l.russian)),
                  ButtonSegment(value: 'kk', label: Text(l.kazakh)),
                ],
                selected: {prefs.language},
                onSelectionChanged: (v) =>
                    guarded(context, () => controller.language(v.first)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l.theme,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              for (final entry in [
                (ThemeMode.system, l.systemTheme, Icons.brightness_auto),
                (ThemeMode.light, l.lightTheme, Icons.light_mode_outlined),
                (ThemeMode.dark, l.darkTheme, Icons.dark_mode_outlined),
              ])
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(entry.$3),
                  title: Text(entry.$2),
                  trailing: prefs.theme == entry.$1
                      ? const Icon(Icons.check_circle_outline)
                      : null,
                  onTap: () =>
                      guarded(context, () => controller.theme(entry.$1)),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: Text(l.about),
                subtitle: Text(l.version),
                onTap: () => showDialog<void>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(l.appName),
                    content: Text(l.aboutBody),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(l.goHome),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: Text(l.privacy),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  builder: (context) => DraggableScrollableSheet(
                    expand: false,
                    initialChildSize: .8,
                    builder: (context, scroll) => ListView(
                      controller: scroll,
                      padding: const EdgeInsets.all(24),
                      children: [
                        Text(
                          l.privacy,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          l.privacyBody,
                          style: const TextStyle(height: 1.7),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: Text(l.clearHistory),
                onTap: () => clearHistory(context, ref),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Notice(l.disclaimer),
      ],
    );
  }
}
