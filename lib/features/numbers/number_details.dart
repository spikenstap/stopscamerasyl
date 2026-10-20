import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/common.dart';
import 'number_providers.dart';
import 'number_widgets.dart';

class NumberDetailsScreen extends ConsumerWidget {
  const NumberDetailsScreen({super.key, required this.phone});
  final String phone;
  Future<void> remove(
    BuildContext context,
    WidgetRef ref, {
    int? reportId,
  }) async {
    final l = context.l;
    final yes = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(reportId == null ? l.numberDelete : l.numberReportDelete),
        content: reportId == null ? Text(l.numberDeleteBody) : null,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text(l.delete),
          ),
        ],
      ),
    );
    if (yes != true || !context.mounted) return;
    try {
      final repo = ref.read(numberRepositoryProvider);
      if (reportId == null) {
        await repo.delete(phone);
      } else {
        await repo.deleteReport(reportId);
      }
      ref.invalidate(numbersProvider);
      if (context.mounted && reportId == null) {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/numbers');
        }
      }
    } on Object catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(numberError(l, e))));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    return Scaffold(
      appBar: AppBar(title: Text(phone)),
      body: ref
          .watch(personalNumberProvider(phone))
          .when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => PageBody(
              children: [
                Notice(numberError(l, e)),
                TextButton(
                  onPressed: () => ref.invalidate(numbersProvider),
                  child: Text(l.retry),
                ),
              ],
            ),
            data: (n) => n == null
                ? Center(child: Text(l.numberNotSaved))
                : PageBody(
                    children: [
                      Text(
                        n.label.isEmpty ? n.phone : n.label,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      Chip(
                        avatar: Icon(numberRuleIcon(n.rule)),
                        label: Text(numberRuleLabel(l, n.rule)),
                      ),
                      Notice(numberRuleBody(l, n.rule)),
                      Text(numberCategoryLabel(l, n.category)),
                      if (n.note.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: SelectableText(n.note),
                        ),
                      Text(
                        '${l.numberUpdated}: ${MaterialLocalizations.of(context).formatMediumDate(n.updatedAt.toLocal())}',
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () async {
                          final updated = await context.push<String>(
                            numberRoute('/number-edit', phone),
                          );
                          if (context.mounted &&
                              updated != null &&
                              updated != phone) {
                            context.pushReplacement(
                              numberRoute('/number-details', updated),
                            );
                          }
                        },
                        icon: const Icon(Icons.edit_outlined),
                        label: Text(l.numberEdit),
                      ),
                      OutlinedButton(
                        onPressed: () =>
                            context.push(numberRoute('/phone', phone)),
                        child: Text(l.checkPhone),
                      ),
                      OutlinedButton.icon(
                        onPressed: () =>
                            context.push(numberRoute('/number-report', phone)),
                        icon: const Icon(Icons.flag_outlined),
                        label: Text(l.numberReport),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        '${l.numberReports}: ${n.reportCount}',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(l.numberReportBody),
                      if (n.reportCount > 100) Text(l.numberReportsRecent),
                      ref
                          .watch(numberReportsProvider(phone))
                          .when(
                            loading: () => const LinearProgressIndicator(),
                            error: (e, _) => Notice(numberError(l, e)),
                            data: (reports) => Column(
                              children: [
                                if (reports.isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Text(l.numberReportsEmpty),
                                  ),
                                for (final report in reports)
                                  Card(
                                    child: ListTile(
                                      title: Text(
                                        numberCategoryLabel(l, report.category),
                                      ),
                                      subtitle: Text(
                                        '${report.note}\n${MaterialLocalizations.of(context).formatMediumDate(report.createdAt.toLocal())}',
                                      ),
                                      trailing: IconButton(
                                        tooltip: l.numberReportDelete,
                                        icon: const Icon(Icons.delete_outline),
                                        onPressed: () => remove(
                                          context,
                                          ref,
                                          reportId: report.id,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                      const SizedBox(height: 20),
                      TextButton.icon(
                        onPressed: () => remove(context, ref),
                        icon: const Icon(Icons.delete_outline),
                        label: Text(l.numberDelete),
                      ),
                    ],
                  ),
          ),
    );
  }
}
