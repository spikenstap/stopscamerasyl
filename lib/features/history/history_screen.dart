import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/providers.dart';
import '../../core/widgets/common.dart';
import '../../app/theme/app_colors.dart';
import '../../models/scan_history_item.dart';

Future<void> clearHistory(BuildContext context, WidgetRef ref) async {
  final l = context.l;
  final yes = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l.clearHistory),
      content: Text(l.confirmClear),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(l.delete),
        ),
      ],
    ),
  );
  if (yes == true && context.mounted) {
    await guarded(context, ref.read(historyProvider.notifier).clear);
  }
}

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    return PageBody(
      children: [
        PageHeading(l.historyTitle, l.tagline),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () => clearHistory(context, ref),
            icon: const Icon(Icons.delete_outline),
            label: Text(l.clearHistory),
          ),
        ),
        ref
            .watch(historyProvider)
            .when(
              loading: () => const LinearProgressIndicator(),
              error: (_, _) => Column(
                children: [
                  Notice(l.errorStorage, warning: true),
                  TextButton(
                    onPressed: () => ref.invalidate(historyProvider),
                    child: Text(l.retry),
                  ),
                ],
              ),
              data: (items) => items.isEmpty
                  ? const EmptyHistory()
                  : Column(
                      children: [
                        for (final item in items)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: HistoryTile(
                              item: item,
                              onDelete: () => guarded(
                                context,
                                () => ref
                                    .read(historyProvider.notifier)
                                    .remove(item.id),
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
      ],
    );
  }
}

class EmptyHistory extends StatelessWidget {
  const EmptyHistory({super.key});
  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      children: [
        const IconTile(Icons.history),
        const SizedBox(height: 18),
        Text(
          context.l.emptyHistory,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(context.l.emptyHistoryBody, textAlign: TextAlign.center),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => context.go('/scan'),
          child: Text(context.l.startScan),
        ),
      ],
    ),
  );
}

class HistoryTile extends StatelessWidget {
  const HistoryTile({super.key, required this.item, this.onDelete});
  final ScanHistoryItem item;
  final VoidCallback? onDelete;
  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () => context.push('/result', extra: item),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconTile(switch (item.type) {
                  'url' => Icons.link,
                  'phone' => Icons.phone_outlined,
                  'qr' => Icons.qr_code,
                  'incomingCall' => Icons.call_received,
                  _ => Icons.chat_bubble_outline,
                }, color: AppColors.risk(item.analysis.riskScore)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.analysis.riskScore == null
                            ? '—'
                            : '${item.analysis.riskScore}/100',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        riskLabel(context.l, item.analysis.riskScore),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                if (onDelete != null)
                  IconButton(
                    tooltip: context.l.delete,
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline, size: 20),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(item.source, maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 10),
            Text(
              DateFormat(
                'd MMM y, HH:mm',
                Localizations.localeOf(context).languageCode,
              ).format(item.date),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (item.isMock)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  context.l.mockBanner,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
