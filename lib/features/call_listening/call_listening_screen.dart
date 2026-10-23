import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_exception.dart';
import '../../core/providers.dart';
import '../../core/widgets/common.dart';
import '../../models/scam_analysis.dart';
import '../../services/call_listening_bridge.dart';
import '../../services/keyword_dictionary.dart';

class ListeningConsentScreen extends StatelessWidget {
  const ListeningConsentScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final l = context.l;
    return Scaffold(
      appBar: AppBar(title: Text(l.callListeningConsentTitle)),
      body: PageBody(
        children: [
          Text(l.callListeningConsentBody, style: const TextStyle(height: 1.6)),
          const SizedBox(height: 24),
          FilledButton(
            key: const ValueKey('listening-consent'),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l.callListeningAccept),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l.callListeningCancel),
          ),
        ],
      ),
    );
  }
}

class CallListeningScreen extends ConsumerStatefulWidget {
  const CallListeningScreen({super.key});
  @override
  ConsumerState<CallListeningScreen> createState() => _ListeningState();
}

class _ListeningState extends ConsumerState<CallListeningScreen> {
  String language = 'ru';
  KeywordDictionary? dictionary;
  Map<String, dynamic> initial = {};
  bool busy = false, saveTranscript = false, initialized = false;
  String? error, saved;
  ScamAnalysis? analysis;
  final description = TextEditingController();
  bool dangerDismissed = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!initialized) {
      initialized = true;
      language = ref.read(preferencesProvider).language;
      load();
    }
  }

  @override
  void dispose() {
    description.dispose();
    super.dispose();
  }

  Future<void> load() async {
    try {
      final next = await ref.read(keywordDictionaryProvider).load(language);
      final status = await ref.read(callListeningProvider).status();
      if (mounted) {
        setState(() {
          dictionary = next;
          initial = {
            'available': status['available'],
            'active': status['active'],
            'level': status['level'],
          };
        });
      }
    } on Object {
      if (mounted) setState(() => error = context.l.callDictionaryError);
    }
  }

  Future<void> start() async {
    if (busy || dictionary == null || dictionary!.isEmpty) return;
    setState(() {
      busy = true;
      error = null;
      saved = null;
      analysis = null;
    });
    try {
      final storage = ref.read(storageProvider);
      if (storage.prefs.getBool('listeningConsentV1') != true) {
        final accepted = await Navigator.of(context).push<bool>(
          MaterialPageRoute(builder: (_) => const ListeningConsentScreen()),
        );
        if (accepted != true || !mounted) return;
        await storage.setBool('listeningConsentV1', true);
      }
      final bridge = ref.read(callListeningProvider);
      if (!await bridge.permission()) {
        if (mounted) setState(() => error = context.l.callListeningPermission);
        return;
      }
      await bridge.start(dictionary!, saveTranscript);
    } on Object {
      if (mounted) setState(() => error = context.l.callListeningUnavailable);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> stop() async {
    try {
      await ref.read(callListeningProvider).stop();
    } on Object {
      if (mounted) setState(() => error = context.l.callListeningUnavailable);
    }
  }

  Future<void> updateDictionary() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final next = await ref.read(keywordDictionaryProvider).update(language);
      if (mounted) setState(() => dictionary = next);
    } on Object {
      if (mounted) setState(() => error = context.l.callDictionaryError);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> askAi() async {
    final brief = description.text.trim();
    if (brief.isEmpty || brief.length > 1000 || busy) return;
    setState(() {
      busy = true;
      error = null;
      analysis = null;
    });
    try {
      // This field is user-authored. Recognition text is never an input to AI.
      final result = await ref
          .read(aiServiceProvider)
          .analyze(
            text: brief,
            type: 'phone',
            language: ref.read(preferencesProvider).language,
            l: context.l,
          );
      if (mounted) setState(() => analysis = result);
    } on ApiException catch (e) {
      if (mounted) setState(() => error = failureText(context.l, e.failure));
    } on Object {
      if (mounted) setState(() => error = context.l.errorUnknown);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> showSaved() async {
    try {
      final text = await ref.read(callListeningProvider).savedTranscript();
      if (mounted) {
        setState(() => saved = text ?? context.l.callNoSavedTranscript);
      }
    } on Object {
      if (mounted) setState(() => error = context.l.errorStorage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    ref.listen(callListeningEventsProvider, (previous, next) {
      if (previous?.asData?.value['active'] == true &&
          next.asData?.value['active'] != true) {
        setState(() => saveTranscript = false);
      }
    });
    final state =
        ref.watch(callListeningEventsProvider).asData?.value ?? initial;
    final active = state['active'] == true;
    final danger = state['level'] == 'DANGER';
    if (!danger) dangerDismissed = false;
    if (danger && !dangerDismissed) {
      return Scaffold(
        key: const ValueKey('call-danger-fullscreen'),
        backgroundColor: Theme.of(context).colorScheme.errorContainer,
        appBar: AppBar(title: Text(l.callListeningWarning)),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(28),
            children: [
              const Icon(Icons.warning_amber, size: 96),
              const SizedBox(height: 24),
              Text(
                l.callListeningDanger,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 32),
              FilledButton(onPressed: stop, child: Text(l.callListeningStop)),
              TextButton(
                onPressed: () => setState(() => dangerDismissed = true),
                child: Text(l.callListeningBack),
              ),
            ],
          ),
        ),
      );
    }
    final nativeError = state['error'] as String?;
    final String? nativeMessage = switch (nativeError) {
      null => null,
      'no_audio' => l.callListeningNoAudio,
      'language_unavailable' => l.callListeningLanguageMissing,
      'notifications_required' => l.callListeningPermission,
      'storage_error' => l.errorStorage,
      'session_limit' => l.callListeningLimit,
      _ => l.callListeningUnavailable,
    };
    return Scaffold(
      appBar: AppBar(title: Text(l.callListeningTitle)),
      body: PageBody(
        children: [
          Notice(l.callListeningBody),
          const SizedBox(height: 16),
          if (danger)
            Container(
              key: const ValueKey('call-danger'),
              padding: const EdgeInsets.all(20),
              color: Theme.of(context).colorScheme.errorContainer,
              child: Column(
                children: [
                  const Icon(Icons.warning_amber, size: 64),
                  Text(
                    l.callListeningDanger,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: stop,
                    child: Text(l.callListeningStop),
                  ),
                ],
              ),
            ),
          Text(
            active ? l.callListeningActive : l.callListeningStopped,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          if (active)
            Text(
              state['level'] == 'CAUTION'
                  ? l.callListeningCaution
                  : danger
                  ? l.callListeningWarning
                  : l.callListeningNone,
            ),
          if (active && (state['phrases'] as List?)?.isNotEmpty == true)
            Text((state['phrases'] as List).join(' • ')),
          if (active && (state['text'] as String? ?? '').isNotEmpty)
            SelectableText(
              state['text'] as String,
              key: const ValueKey('call-live-text'),
            ),
          if (active)
            FilledButton.icon(
              onPressed: stop,
              icon: const Icon(Icons.stop),
              label: Text(l.callListeningStop),
            )
          else ...[
            DropdownButtonFormField<String>(
              initialValue: language,
              decoration: InputDecoration(labelText: l.callListeningLanguage),
              items: [
                DropdownMenuItem(value: 'ru', child: Text(l.russian)),
                DropdownMenuItem(value: 'kk', child: Text(l.kazakh)),
              ],
              onChanged: busy
                  ? null
                  : (value) {
                      setState(() {
                        language = value!;
                        dictionary = null;
                        error = null;
                      });
                      load();
                    },
            ),
            if (dictionary != null)
              Text('${l.callDictionaryVersion}: ${dictionary!.version}'),
            if (dictionary?.isEmpty == true)
              Notice(l.callDictionaryEmpty, warning: true),
            if (initial['available'] == false)
              Notice(l.callListeningUnavailable, warning: true),
            SwitchListTile(
              key: const ValueKey('save-call-transcript'),
              contentPadding: EdgeInsets.zero,
              title: Text(l.callSaveTranscript),
              subtitle: Text(l.callSaveTranscriptBody),
              value: saveTranscript,
              onChanged: busy
                  ? null
                  : (v) => setState(() => saveTranscript = v),
            ),
            FilledButton.icon(
              key: const ValueKey('start-call-listening'),
              onPressed:
                  busy ||
                      dictionary == null ||
                      dictionary!.isEmpty ||
                      initial['available'] != true
                  ? null
                  : start,
              icon: const Icon(Icons.mic),
              label: Text(l.callListeningStart),
            ),
            TextButton(
              onPressed: busy ? null : updateDictionary,
              child: Text(l.callDictionaryUpdate),
            ),
            TextButton(onPressed: showSaved, child: Text(l.callShowTranscript)),
            if (saved != null) ...[
              SelectableText(saved!),
              TextButton(
                onPressed: () async {
                  try {
                    await ref.read(callListeningProvider).deleteTranscript();
                    if (mounted) setState(() => saved = null);
                  } on Object {
                    if (mounted) setState(() => error = l.errorStorage);
                  }
                },
                child: Text(l.callDeleteTranscript),
              ),
            ],
            const Divider(),
            Text(
              l.callManualTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(l.callManualBody),
            TextField(
              key: const ValueKey('call-ai-description'),
              controller: description,
              minLines: 3,
              maxLines: 6,
              maxLength: 1000,
              decoration: InputDecoration(labelText: l.callManualDescription),
            ),
            FilledButton(
              onPressed: busy ? null : askAi,
              child: Text(l.callManualAi),
            ),
            if (analysis != null) ...[
              if (analysis!.origin == 'mock') Text(l.mockDetail),
              Text(analysis!.summary),
              for (final recommendation in analysis!.recommendations)
                Text('• $recommendation'),
            ],
          ],
          if (nativeMessage != null) Notice(nativeMessage, warning: true),
          if (error != null) Notice(error!, warning: true),
          if (busy) const LinearProgressIndicator(),
        ],
      ),
    );
  }
}
