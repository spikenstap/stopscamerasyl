import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/utils/url_utils.dart';
import '../../core/widgets/common.dart';
import 'scan_controller.dart';

class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key, this.isUrl = false});
  final bool isUrl;
  @override
  ConsumerState<ScannerScreen> createState() => _ScannerState();
}

class _ScannerState extends ConsumerState<ScannerScreen> {
  final text = TextEditingController();
  final url = TextEditingController();
  final form = GlobalKey<FormState>();
  late bool isUrl = widget.isUrl;
  @override
  void didUpdateWidget(ScannerScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isUrl != widget.isUrl) isUrl = widget.isUrl;
  }

  @override
  void dispose() {
    text.dispose();
    url.dispose();
    super.dispose();
  }

  TextEditingController get input => isUrl ? url : text;
  Future<void> submit() async {
    if (!form.currentState!.validate()) return;
    FocusManager.instance.primaryFocus?.unfocus();
    HapticFeedback.mediumImpact();
    await ref.read(scanProvider.notifier).scan(input.text, isUrl, context.l);
    if (!mounted) return;
    final result = ref.read(scanProvider);
    if (result.item != null) {
      if (result.saveFailed) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.l.saveFailed)));
      }
      context.push('/result', extra: result.item);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final state = ref.watch(scanProvider);
    final busy = state.status == ScanStatus.analyzing;
    return PageBody(
      children: [
        PageHeading(l.scannerTitle, l.scannerSubtitle),
        if (ref.watch(aiServiceProvider).isMock) ...[
          Notice(l.mockBanner, warning: true),
          const SizedBox(height: 16),
        ],
        SegmentedButton<bool>(
          segments: [
            ButtonSegment(
              value: false,
              label: Text(l.textMode),
              icon: const Icon(Icons.chat_bubble_outline),
            ),
            ButtonSegment(
              value: true,
              label: Text(l.linkMode),
              icon: const Icon(Icons.link),
            ),
          ],
          selected: {isUrl},
          onSelectionChanged: busy
              ? null
              : (values) {
                  setState(() => isUrl = values.first);
                  ref.read(scanProvider.notifier).reset();
                  form.currentState?.reset();
                },
        ),
        const SizedBox(height: 20),
        AppCard(
          child: Form(
            key: form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    IconTile(isUrl ? Icons.link : Icons.chat_bubble_outline),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isUrl ? l.checkLink : l.checkMessage,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    IconButton(
                      tooltip: l.clear,
                      onPressed: busy
                          ? null
                          : () {
                              input.clear();
                              ref.read(scanProvider.notifier).reset();
                            },
                      icon: const Icon(Icons.close, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: ValueKey(isUrl),
                  controller: input,
                  enabled: !busy,
                  minLines: isUrl ? 2 : 7,
                  maxLines: isUrl ? 4 : 12,
                  maxLength: isUrl ? 4096 : 12000,
                  autocorrect: false,
                  enableSuggestions: false,
                  keyboardType: isUrl
                      ? TextInputType.url
                      : TextInputType.multiline,
                  onTapOutside: (_) =>
                      FocusManager.instance.primaryFocus?.unfocus(),
                  decoration: InputDecoration(
                    labelText: isUrl ? l.linkMode : l.textMode,
                    alignLabelWithHint: true,
                    hintText: isUrl ? l.urlHint : l.textHint,
                    errorMaxLines: 3,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return l.emptyInput;
                    }
                    if (value.length > 12000) return l.tooLong;
                    if (isUrl) {
                      try {
                        UrlUtils.inspect(value);
                      } on FormatException {
                        return l.invalidUrl;
                      }
                    }
                    return null;
                  },
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: busy
                        ? null
                        : () async {
                            try {
                              final data = await Clipboard.getData(
                                Clipboard.kTextPlain,
                              );
                              if (mounted && data?.text != null) {
                                input.text = data!.text!;
                              }
                            } on Object {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(l.errorUnknown)),
                                );
                              }
                            }
                          },
                    icon: const Icon(Icons.content_paste, size: 18),
                    label: Text(l.paste),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        if (busy) ...[
          AppCard(
            child: Column(
              children: [
                const LinearProgressIndicator(),
                const SizedBox(height: 20),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    l.analyzing,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 8),
                Text(l.analyzingBody, textAlign: TextAlign.center),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (state.failure != null) ...[
          Notice(failureText(l, state.failure!), warning: true),
          const SizedBox(height: 16),
        ],
        FilledButton.icon(
          onPressed: busy ? null : submit,
          icon: const Icon(Icons.auto_awesome),
          label: Text(
            busy
                ? l.analyzing
                : state.failure != null
                ? l.retry
                : l.startScan,
          ),
        ),
        const SizedBox(height: 18),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.lock_outline,
              size: 18,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l.privacyNotice,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Notice(l.disclaimer, icon: Icons.shield_outlined),
      ],
    );
  }
}
