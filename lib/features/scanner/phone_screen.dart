import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/phone_utils.dart';
import '../../core/widgets/common.dart';
import '../../models/analysis_type.dart';
import 'scan_controller.dart';

class PhoneScreen extends ConsumerStatefulWidget {
  const PhoneScreen({super.key, this.initialPhone});
  final String? initialPhone;
  @override
  ConsumerState<PhoneScreen> createState() => _PhoneState();
}

class _PhoneState extends ConsumerState<PhoneScreen> {
  final number = TextEditingController(), details = TextEditingController();
  final form = GlobalKey<FormState>();
  @override
  void initState() {
    super.initState();
    number.text = widget.initialPhone ?? '';
  }

  @override
  void dispose() {
    number.dispose();
    details.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!form.currentState!.validate()) return;
    FocusManager.instance.primaryFocus?.unfocus();
    await ref
        .read(scanProvider.notifier)
        .analyze(
          AnalysisInput(AnalysisType.phone, number.text, context: details.text),
          context.l,
        );
    if (!mounted) return;
    final state = ref.read(scanProvider);
    if (state.item != null) {
      if (state.saveFailed) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.l.saveFailed)));
      }
      context.push('/result', extra: state.item);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l, state = ref.watch(scanProvider);
    final busy = state.status == ScanStatus.analyzing;
    return Scaffold(
      appBar: AppBar(title: Text(l.checkPhone)),
      body: PageBody(
        children: [
          Notice(l.phoneDescription),
          TextButton.icon(
            onPressed: () => context.push('/numbers'),
            icon: const Icon(Icons.contact_phone_outlined),
            label: Text(l.numbersOpen),
          ),
          const SizedBox(height: 20),
          Form(
            key: form,
            child: Column(
              children: [
                TextFormField(
                  controller: number,
                  enabled: !busy,
                  maxLength: 40,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
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
                TextButton.icon(
                  onPressed: busy
                      ? null
                      : () async {
                          try {
                            final data = await Clipboard.getData(
                              Clipboard.kTextPlain,
                            );
                            if (mounted) number.text = data?.text ?? '';
                          } on Object {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(l.errorUnknown)),
                              );
                            }
                          }
                        },
                  icon: const Icon(Icons.content_paste),
                  label: Text(l.paste),
                ),
                TextFormField(
                  controller: details,
                  enabled: !busy,
                  minLines: 3,
                  maxLines: 6,
                  maxLength: 6000,
                  decoration: InputDecoration(labelText: l.phoneContext),
                ),
              ],
            ),
          ),
          if (busy) const LinearProgressIndicator(),
          if (state.failure != null)
            Notice(failureText(l, state.failure!), warning: true),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: busy ? null : submit,
            child: Text(busy ? l.analyzing : l.startScan),
          ),
          const SizedBox(height: 16),
          Text(l.privacyNotice),
        ],
      ),
    );
  }
}
