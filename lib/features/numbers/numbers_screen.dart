import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/number_csv.dart';
import '../../core/utils/phone_utils.dart';
import '../../core/widgets/common.dart';
import '../../models/personal_number.dart';
import 'number_providers.dart';
import 'number_widgets.dart';

class NumbersScreen extends ConsumerStatefulWidget {
  const NumbersScreen({super.key});
  @override
  ConsumerState<NumbersScreen> createState() => _NumbersState();
}

class _NumbersState extends ConsumerState<NumbersScreen> {
  final search = TextEditingController();
  NumberRule? filter;
  bool busy = false;
  String query = '';
  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  Future<void> transfer(String action) async {
    if (busy) return;
    setState(() => busy = true);
    final l = context.l, repo = ref.read(numberRepositoryProvider);
    try {
      if (action == 'export') {
        final yes = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l.numbersExport),
            content: Text(l.numbersExportNote),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(l.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(l.numbersExport),
              ),
            ],
          ),
        );
        if (yes != true) return;
        final all = await repo.all();
        final done = await repo.export(NumberCsv.encode(all));
        if (mounted && done) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(l.numbersExportDone)));
        }
      } else {
        final raw = await repo.pickImport();
        if (raw == null || !mounted) return;
        final preview = NumberCsv.decode(raw);
        if (preview.items.isEmpty) {
          throw const FormatException('No valid numbers');
        }
        var restore = false;
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => StatefulBuilder(
            builder: (context, setDialogState) => AlertDialog(
              title: Text(l.numbersImportTitle),
              content: SizedBox(
                width: 400,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(l.numbersImportBody),
                      const SizedBox(height: 12),
                      Text('${l.numbersImportValid}: ${preview.items.length}'),
                      Text(
                        '${l.numbersImportInvalid}: ${preview.invalidLines.length}',
                      ),
                      Text(
                        '${l.numbersImportDuplicates}: ${preview.duplicates}',
                      ),
                      const Divider(),
                      for (final n in preview.items.take(5))
                        Text(
                          '${n.phone}${n.label.isEmpty ? '' : ' · ${n.label}'}',
                        ),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(l.numbersRestoreRules),
                        value: restore,
                        onChanged: (v) =>
                            setDialogState(() => restore = v == true),
                      ),
                      if (restore)
                        Notice(
                          '${l.numbersRestoreWarning}\n${l.ruleBlocked}: ${preview.items.where((n) => n.rule == NumberRule.blocked).length}\n${l.ruleTrusted}: ${preview.items.where((n) => n.rule == NumberRule.trusted).length}',
                          warning: true,
                        ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(l.cancel),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(l.numbersImport),
                ),
              ],
            ),
          ),
        );
        if (confirmed != true || !mounted) return;
        final result = await repo.importNumbers(
          preview.items,
          restoreRules: restore,
        );
        if (!mounted) return;
        ref.invalidate(numbersProvider);
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l.numbersImport),
            content: Text(
              '${l.numbersImportAdded}: ${result['added']}\n${l.numbersImportSkipped}: ${result['skipped']}',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(MaterialLocalizations.of(context).okButtonLabel),
              ),
            ],
          ),
        );
      }
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(numberError(l, error))));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l, data = ref.watch(numbersProvider);
    String? normalizedQuery;
    try {
      normalizedQuery = PhoneUtils.normalize(query).number;
    } on FormatException {
      /* Names and partial numbers are searched below. */
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(l.numbersTitle),
        actions: [
          PopupMenuButton<String>(
            enabled: !busy,
            onSelected: transfer,
            itemBuilder: (_) => [
              PopupMenuItem(value: 'import', child: Text(l.numbersImport)),
              PopupMenuItem(
                value: 'export',
                enabled: data.asData?.value.isNotEmpty == true,
                child: Text(l.numbersExport),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: busy ? null : () => context.push('/number-edit'),
        icon: const Icon(Icons.add),
        label: Text(l.numberAdd),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l.numbersLocal,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: search,
                    onChanged: (v) =>
                        setState(() => query = v.trim().toLowerCase()),
                    decoration: InputDecoration(
                      hintText: l.numbersSearch,
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: query.isEmpty
                          ? null
                          : IconButton(
                              tooltip: l.clear,
                              onPressed: () {
                                search.clear();
                                setState(() => query = '');
                              },
                              icon: const Icon(Icons.close),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final rule in <NumberRule?>[
                          null,
                          ...NumberRule.values,
                        ])
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(
                                rule == null
                                    ? l.numbersAll
                                    : numberRuleLabel(l, rule),
                              ),
                              selected: filter == rule,
                              onSelected: (_) => setState(() => filter = rule),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (data.asData
                      case final AsyncData<List<PersonalNumber>> loaded)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        '${l.numbersAll}: ${loaded.value.length}  ·  ${l.ruleBlocked}: ${loaded.value.where((n) => n.rule == NumberRule.blocked).length}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                ],
              ),
            ),
            if (busy) const LinearProgressIndicator(),
            Expanded(
              child: data.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Notice(numberError(l, e), warning: true),
                      TextButton(
                        onPressed: () => ref.invalidate(numbersProvider),
                        child: Text(l.retry),
                      ),
                    ],
                  ),
                ),
                data: (items) {
                  final visible = items
                      .where(
                        (n) =>
                            (filter == null || n.rule == filter) &&
                            (query.isEmpty ||
                                n.phone == normalizedQuery ||
                                '${n.phone} ${n.label} ${n.note}'
                                    .toLowerCase()
                                    .contains(query) ||
                                n.phone.contains(
                                  query.replaceAll(RegExp(r'[ ()-]'), ''),
                                )),
                      )
                      .toList();
                  if (visible.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(30),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.contact_phone_outlined, size: 52),
                            const SizedBox(height: 16),
                            Text(
                              items.isEmpty ? l.numbersEmpty : l.numbersNoMatch,
                              textAlign: TextAlign.center,
                            ),
                            if (items.isEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                l.numbersEmptyBody,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(numbersProvider);
                      await ref.read(numbersProvider.future);
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                      itemCount: visible.length,
                      itemBuilder: (context, index) {
                        final n = visible[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Card(
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              leading: IconTile(
                                numberRuleIcon(n.rule),
                                color: numberRuleColor(n.rule),
                              ),
                              title: Text(
                                n.label.isEmpty ? n.phone : n.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                '${n.label.isEmpty ? '' : '${n.phone}\n'}${numberRuleLabel(l, n.rule)}${n.reportCount == 0 ? '' : ' · ${l.numberReports}: ${n.reportCount}'}',
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => context.push(
                                numberRoute('/number-details', n.phone),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
