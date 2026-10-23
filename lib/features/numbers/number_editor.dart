import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/utils/phone_utils.dart';
import '../../core/widgets/common.dart';
import '../../models/personal_number.dart';
import '../../services/number_report_service.dart';
import 'number_providers.dart';
import 'number_widgets.dart';

class NumberEditor extends ConsumerStatefulWidget {
  const NumberEditor({super.key, this.phone});
  final String? phone;
  @override
  ConsumerState<NumberEditor> createState() => _EditorState();
}

class _EditorState extends ConsumerState<NumberEditor> {
  final phone = TextEditingController(),
      label = TextEditingController(),
      note = TextEditingController();
  final form = GlobalKey<FormState>();
  NumberRule rule = NumberRule.watch;
  ReportCategory category = ReportCategory.unknown;
  String? original;
  Object? failure;
  bool loading = true, busy = false, roleHeld = false, loadFailed = false;
  @override
  void initState() {
    super.initState();
    phone.text = widget.phone ?? '';
    load();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      loadFailed = false;
    });
    try {
      final repository = ref.read(numberRepositoryProvider),
          bridge = ref.read(callBridgeProvider);
      final entry = widget.phone == null
          ? null
          : await repository.find(widget.phone!);
      Map<dynamic, dynamic> status = {};
      try {
        status = await bridge.status();
      } on Object {
        /* Editing works without role status. */
      }
      if (!mounted) return;
      setState(() {
        original = entry?.phone;
        label.text = entry?.label ?? '';
        note.text = entry?.note ?? '';
        rule = entry?.rule ?? NumberRule.watch;
        category = entry?.category ?? ReportCategory.unknown;
        roleHeld = status['held'] == true;
        loading = false;
        failure = null;
      });
    } on Object catch (e) {
      if (mounted) {
        setState(() {
          loading = false;
          failure = e;
          loadFailed = true;
        });
      }
    }
  }

  @override
  void dispose() {
    phone.dispose();
    label.dispose();
    note.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (busy || !form.currentState!.validate()) return;
    setState(() {
      busy = true;
      failure = null;
    });
    FocusManager.instance.primaryFocus?.unfocus();
    try {
      await ref
          .read(numberRepositoryProvider)
          .save(
            phone: phone.text,
            label: label.text,
            rule: rule,
            category: category,
            note: note.text,
            originalPhone: original,
          );
      if (!mounted) return;
      ref.invalidate(numbersProvider);
      final l = context.l, router = GoRouter.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            rule == NumberRule.blocked && !roleHeld
                ? l.numbersRoleNeeded
                : l.numberSaved,
          ),
          action: rule == NumberRule.blocked && !roleHeld
              ? SnackBarAction(
                  label: l.openSettings,
                  onPressed: () => router.go('/settings'),
                )
              : null,
        ),
      );
      if (context.canPop()) {
        context.pop(PhoneUtils.normalize(phone.text).number);
      } else {
        context.go('/numbers');
      }
    } on Object catch (e) {
      if (mounted) setState(() => failure = e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    return Scaffold(
      appBar: AppBar(
        title: Text(original == null ? l.numberAdd : l.numberEdit),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : PageBody(
              children: [
                if (failure != null) ...[
                  Notice(numberError(l, failure!), warning: true),
                  const SizedBox(height: 12),
                ],
                if (loadFailed)
                  TextButton(onPressed: load, child: Text(l.retry))
                else
                  Form(
                    key: form,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          key: const ValueKey('saved-number-phone'),
                          controller: phone,
                          enabled: !busy,
                          keyboardType: TextInputType.phone,
                          maxLength: 40,
                          decoration: InputDecoration(
                            labelText: l.checkPhone,
                            hintText: l.phoneHint,
                            errorMaxLines: 3,
                          ),
                          validator: (v) {
                            try {
                              PhoneUtils.normalize(v ?? '');
                              return null;
                            } on FormatException {
                              return l.invalidPhone;
                            }
                          },
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: busy
                                ? null
                                : () async {
                                    try {
                                      final value = await Clipboard.getData(
                                        Clipboard.kTextPlain,
                                      );
                                      if (mounted) {
                                        phone.text = value?.text ?? '';
                                      }
                                    } on Object catch (e) {
                                      if (mounted) setState(() => failure = e);
                                    }
                                  },
                            icon: const Icon(Icons.content_paste),
                            label: Text(l.paste),
                          ),
                        ),
                        TextFormField(
                          key: const ValueKey('saved-number-label'),
                          controller: label,
                          enabled: !busy,
                          maxLength: 100,
                          decoration: InputDecoration(labelText: l.numberLabel),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<NumberRule>(
                          key: ValueKey('rule-${rule.name}'),
                          initialValue: rule,
                          isExpanded: true,
                          decoration: InputDecoration(labelText: l.numberRule),
                          items: [
                            for (final value in NumberRule.values)
                              DropdownMenuItem(
                                value: value,
                                child: Text(numberRuleLabel(l, value)),
                              ),
                          ],
                          onChanged: busy
                              ? null
                              : (v) => setState(() => rule = v!),
                        ),
                        const SizedBox(height: 12),
                        Notice(
                          numberRuleBody(l, rule),
                          warning: rule == NumberRule.blocked,
                        ),
                        const SizedBox(height: 18),
                        DropdownButtonFormField<ReportCategory>(
                          key: ValueKey(category),
                          initialValue: category,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: l.numberCategory,
                          ),
                          items: [
                            for (final value in ReportCategory.values)
                              DropdownMenuItem(
                                value: value,
                                child: Text(
                                  numberCategoryLabel(l, value),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                          onChanged: busy
                              ? null
                              : (v) => setState(() => category = v!),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          key: const ValueKey('saved-number-note'),
                          controller: note,
                          enabled: !busy,
                          minLines: 3,
                          maxLines: 6,
                          maxLength: 500,
                          decoration: InputDecoration(labelText: l.numberNote),
                        ),
                        const SizedBox(height: 16),
                        if (busy) const LinearProgressIndicator(),
                        FilledButton.icon(
                          onPressed: busy ? null : save,
                          icon: const Icon(Icons.save_outlined),
                          label: Text(l.numberSave),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l.numbersLocal,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}

class NumberReportEditor extends ConsumerStatefulWidget {
  const NumberReportEditor({super.key, required this.phone});
  final String phone;
  @override
  ConsumerState<NumberReportEditor> createState() => _ReportState();
}

class _ReportState extends ConsumerState<NumberReportEditor> {
  final note = TextEditingController();
  ReportCategory category = ReportCategory.advertising;
  bool busy = false;
  Object? failure;
  @override
  void dispose() {
    note.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (busy) return;
    setState(() {
      busy = true;
      failure = null;
    });
    try {
      final sharing = await ref
          .read(numberReportServiceProvider)
          .save(widget.phone, category, note.text);
      if (!mounted) return;
      ref.invalidate(numbersProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(switch (sharing) {
            ReportSharingResult.shared => context.l.numberReportShared,
            ReportSharingResult.sharingFailed =>
              context.l.numberReportShareFailed,
            ReportSharingResult.localOnly => context.l.numberReportSaved,
          }),
        ),
      );
      context.pop();
    } on Object catch (e) {
      if (mounted) setState(() => failure = e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    return Scaffold(
      appBar: AppBar(title: Text(l.numberReport)),
      body: PageBody(
        children: [
          SelectableText(
            widget.phone,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          Notice(l.numberReportBody),
          const SizedBox(height: 20),
          DropdownButtonFormField<ReportCategory>(
            initialValue: category,
            isExpanded: true,
            decoration: InputDecoration(labelText: l.numberCategory),
            items: [
              for (final c in ReportCategory.values.where(
                (c) => c != ReportCategory.unknown,
              ))
                DropdownMenuItem(
                  value: c,
                  child: Text(
                    numberCategoryLabel(l, c),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: busy ? null : (v) => setState(() => category = v!),
          ),
          const SizedBox(height: 16),
          TextFormField(
            key: const ValueKey('report-note'),
            controller: note,
            enabled: !busy,
            minLines: 4,
            maxLines: 8,
            maxLength: 500,
            decoration: InputDecoration(hintText: l.numberReportNote),
          ),
          if (failure != null) Notice(numberError(l, failure!), warning: true),
          const SizedBox(height: 16),
          if (busy) const LinearProgressIndicator(),
          FilledButton(
            onPressed: busy ? null : save,
            child: Text(l.numberSave),
          ),
        ],
      ),
    );
  }
}
