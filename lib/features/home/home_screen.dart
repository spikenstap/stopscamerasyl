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
    final history = ref.watch(historyProvider);
    final items = history.asData?.value ?? [];
    final realItems = items.where((e) => !e.isMock).toList();
    return PageBody(
      children: [
        Row(
          children: [
            const IconTile(Icons.shield_outlined, color: AppColors.success),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l.appName,
                style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -.6,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(l.tagline),
        OutlinedButton.icon(
          onPressed: () => context.go('/numbers'),
          icon: const Icon(Icons.contact_phone_outlined),
          label: Text(l.numbersOpen),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.green, AppColors.success],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.verified_user_outlined,
                    color: AppColors.surface,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l.ready,
                      style: const TextStyle(
                        color: AppColors.surface,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                l.heroTitle,
                style: const TextStyle(
                  color: AppColors.surface,
                  fontSize: 27,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                  letterSpacing: -.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l.heroBody,
                style: const TextStyle(color: AppColors.surface, height: 1.5),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) => Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final action in [
                (l.checkMessage, Icons.chat_bubble_outline, '/scan'),
                (l.checkLink, Icons.link, '/scan?mode=url'),
                (l.checkPhone, Icons.phone_outlined, '/phone'),
                (l.checkQr, Icons.qr_code_scanner, '/qr'),
              ])
                SizedBox(
                  width: (constraints.maxWidth - 12) / 2,
                  child: OutlinedButton(
                    onPressed: () => action.$3.startsWith('/scan')
                        ? context.go(action.$3)
                        : context.push(action.$3),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Column(
                        children: [
                          Icon(action.$2),
                          const SizedBox(height: 8),
                          Text(action.$1, textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (ref.watch(aiServiceProvider).isMock) ...[
          Notice(l.mockBanner, warning: true),
          const SizedBox(height: 20),
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _Stat(
                l.totalScans,
                '${realItems.length}',
                Icons.fact_check_outlined,
                AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _Stat(
                l.highRisks,
                '${realItems.where((e) => (e.analysis.riskScore ?? -1) > 60).length}',
                Icons.warning_amber,
                AppColors.danger,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: Text(
                l.recent,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () => context.go('/history'),
              child: Text(l.seeAll),
            ),
          ],
        ),
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
                  padding: const EdgeInsets.only(bottom: 10),
                  child: HistoryTile(item: item),
                ),
              ),
        const SizedBox(height: 20),
        Notice('${l.dailyTip}\n${l.tipBody}'),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.title, this.value, this.icon, this.color);
  final String title, value;
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconTile(icon, color: color),
        const SizedBox(height: 16),
        Text(
          value,
          style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(title, style: const TextStyle(fontSize: 13)),
      ],
    ),
  );
}
