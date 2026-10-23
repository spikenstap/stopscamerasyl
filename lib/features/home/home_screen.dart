import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../core/providers.dart';
import '../../core/widgets/common.dart';
import '../history/history_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final theme = Theme.of(context);
    final history = ref.watch(historyProvider);
    final items = history.asData?.value ?? [];
    final realItems = items.where((e) => !e.isMock).toList();
    return PageBody(
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.shield_outlined,
                color: theme.colorScheme.onPrimary,
                size: 26,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l.appName,
                style: theme.textTheme.titleLarge?.copyWith(fontSize: 25),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: Text(
                Localizations.localeOf(context).languageCode == 'kk'
                    ? 'ҚАЗ'
                    : 'РУС',
                style: theme.textTheme.labelMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const _CheckHero(),
        const SizedBox(height: 28),
        _SectionTitle(l.designQuickChecks),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final oneColumn =
                constraints.maxWidth < 300 ||
                MediaQuery.textScalerOf(context).scale(14) > 22;
            final actions = [
              (
                l.designMessage,
                l.designMessageHint,
                Icons.chat_bubble_outline,
                '/scan',
              ),
              (l.linkMode, l.designLinkHint, Icons.link, '/scan?mode=url'),
              (
                l.designPhone,
                l.designPhoneHint,
                Icons.phone_outlined,
                '/phone',
              ),
              (l.designQr, l.designQrHint, Icons.qr_code_scanner, '/qr'),
            ];
            return Column(
              children: [
                for (var i = 0; i < actions.length; i += oneColumn ? 1 : 2)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (
                            var j = i;
                            j < (oneColumn ? i + 1 : i + 2);
                            j++
                          ) ...[
                            if (j > i) const SizedBox(width: 12),
                            Expanded(
                              child: _ActionCard(
                                title: actions[j].$1,
                                subtitle: actions[j].$2,
                                icon: actions[j].$3,
                                onTap: () => actions[j].$4.startsWith('/scan')
                                    ? context.go(actions[j].$4)
                                    : context.push(actions[j].$4),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 8),
        _FeatureCard(
          icon: Icons.hearing_outlined,
          title: l.callListeningTitle,
          subtitle: l.designCallHint,
          onTap: () => context.push('/call-listening'),
        ),
        const SizedBox(height: 12),
        _FeatureCard(
          icon: Icons.contact_phone_outlined,
          title: l.numbersOpen,
          subtitle: l.designNumbersHint,
          onTap: () => context.go('/numbers'),
        ),
        if (ref.watch(aiServiceProvider).isMock) ...[
          const SizedBox(height: 20),
          Notice(l.mockBanner, warning: true),
        ],
        const SizedBox(height: 28),
        AppCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _Stat(l.totalScans, '${realItems.length}')),
              const SizedBox(width: 24),
              Expanded(
                child: _Stat(
                  l.highRisks,
                  '${realItems.where((e) => (e.analysis.riskScore ?? -1) > 60).length}',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(child: _SectionTitle(l.recent)),
            TextButton(
              onPressed: () => context.go('/history'),
              child: Text(l.seeAll),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (history.isLoading)
          const LinearProgressIndicator()
        else if (history.hasError)
          Notice(l.errorStorage, warning: true)
        else if (items.isEmpty)
          const EmptyHistory()
        else
          ...items
              .take(3)
              .map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: HistoryTile(item: item),
                ),
              ),
        const SizedBox(height: 24),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(l.dailyTip, style: theme.textTheme.titleMedium),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                l.tipBody,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CheckHero extends StatelessWidget {
  const _CheckHero();
  @override
  Widget build(BuildContext context) {
    final l = context.l;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.hero,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  l.ready.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.heroMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.3,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              const ExcludeSemantics(child: _ShieldMark()),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            l.heroTitle,
            style: const TextStyle(
              color: AppColors.onHero,
              fontSize: 30,
              fontWeight: FontWeight.w700,
              height: 1.13,
              letterSpacing: -.8,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l.heroBody,
            style: const TextStyle(
              color: AppColors.heroMuted,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              key: const ValueKey('home-start-check'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.hero,
              ),
              onPressed: () => context.go('/scan'),
              child: Row(
                children: [
                  Expanded(child: Text(l.startScan)),
                  const SizedBox(width: 12),
                  const Icon(Icons.arrow_forward, size: 22),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShieldMark extends StatelessWidget {
  const _ShieldMark();
  @override
  Widget build(BuildContext context) => Container(
    width: 54,
    height: 54,
    decoration: BoxDecoration(
      border: Border.all(color: AppColors.heroMuted.withValues(alpha: .35)),
      borderRadius: BorderRadius.circular(18),
    ),
    child: const Icon(Icons.shield_outlined, size: 30, color: AppColors.accent),
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    child: Text(text, style: Theme.of(context).textTheme.titleLarge),
  );
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });
  final String title, subtitle;
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: theme.colorScheme.primary, size: 26),
                const SizedBox(height: 16),
                Text(title, style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(subtitle, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title, subtitle;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      child: Card(
        color: theme.colorScheme.primaryContainer,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(icon, color: theme.colorScheme.onPrimaryContainer),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(subtitle, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.title, this.value);
  final String title, value;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(value, style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 4),
      Text(title, style: Theme.of(context).textTheme.bodySmall),
    ],
  );
}
