import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/widgets/common.dart';
import '../../models/analysis_type.dart';
import '../../models/scan_history_item.dart';
import '../../models/scam_analysis.dart';

class CallProtectionCard extends ConsumerStatefulWidget {
  const CallProtectionCard({super.key});
  @override
  ConsumerState<CallProtectionCard> createState() => _ProtectionState();
}

class _ProtectionState extends ConsumerState<CallProtectionCard>
    with WidgetsBindingObserver {
  Map<dynamic, dynamic> status = {};
  bool busy = false, failed = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) refresh();
  }

  Future<void> refresh() async {
    try {
      final value = await ref.read(callBridgeProvider).status();
      if (mounted) setState(() => status = value);
    } on Object {
      if (mounted) setState(() => failed = true);
    }
  }

  Future<void> action(String method, [dynamic args]) async {
    setState(() {
      busy = true;
      failed = false;
    });
    try {
      await ref.read(callBridgeProvider).invoke<dynamic>(method, args);
      await refresh();
    } on Object {
      if (mounted) setState(() => failed = true);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.callsTitle, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Text(l.callsBody),
          Text(l.personalRulesNote),
          const SizedBox(height: 12),
          Text(status['held'] == true ? l.callsEnabled : l.callsDisabled),
          if (status['available'] != true)
            Notice(l.callsUnsupported)
          else
            FilledButton(
              onPressed: busy
                  ? null
                  : () => action(
                      status['held'] == true ? 'defaultApps' : 'requestRole',
                    ),
              child: Text(
                status['held'] == true ? l.openSettings : l.callsEnable,
              ),
            ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l.autoBlock),
            subtitle: Text(l.autoBlockBody),
            value: status['autoBlock'] == true,
            onChanged: busy || status['held'] != true
                ? null
                : (value) => action('autoBlock', {'enabled': value}),
          ),
          TextButton(
            onPressed: busy ? null : () => action('notifications'),
            child: Text(
              status['notifications'] == true
                  ? l.notificationsEnabled
                  : l.notificationsEnable,
            ),
          ),
          if (failed) Notice(l.errorUnknown, warning: true),
        ],
      ),
    );
  }
}

class CallEventSync extends ConsumerStatefulWidget {
  const CallEventSync({super.key, required this.child});
  final Widget child;
  @override
  ConsumerState<CallEventSync> createState() => _SyncState();
}

class _SyncState extends ConsumerState<CallEventSync>
    with WidgetsBindingObserver {
  bool busy = false, failed = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      sync();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) sync();
  }

  Future<void> sync() async {
    if (busy || !mounted) return;
    busy = true;
    try {
      final bridge = ref.read(callBridgeProvider), l = context.l;
      final language = ref.read(preferencesProvider).language;
      await bridge.invoke<void>('language', {'language': language});
      final raw = await bridge.invoke<String>('events');
      if (raw == null) return;
      final events = jsonDecode(raw) as List;
      for (final value in events) {
        final e = Map<String, dynamic>.from(value as Map);
        final input = AnalysisInput(
          AnalysisType.incomingCall,
          e['number'] as String,
        );
        final analysis =
            ScamAnalysis(
              riskScore: null,
              isScam: false,
              category: 'unknown',
              summary: switch (e['decisionSource']) {
                'personal_block' => l.personalBlockedCall,
                'personal_allow' => l.personalAllowedCall,
                _ => e['blocked'] == true ? l.blockedCall : l.allowedCall,
              },
              reasons: const [],
              recommendations: [l.tipBody],
              origin: 'local',
            ).withInput(input, {
              'number': input.content,
              'reputation': e['reputation'],
              'blocked': e['blocked'],
              'decisionSource': e['decisionSource'],
              'personalRule': e['personalRule'],
            });
        await ref
            .read(historyProvider.notifier)
            .add(
              ScanHistoryItem(
                id: 'call:${e['id']}',
                type: 'incomingCall',
                source: input.content,
                date: DateTime.fromMillisecondsSinceEpoch(
                  e['timestamp'] as int,
                ),
                language: language,
                isMock: false,
                analysis: analysis,
              ),
            );
        // Ack only after durable Flutter storage; IDs make retries idempotent.
        await bridge.invoke<void>('ack', {
          'ids': [e['id']],
        });
      }
      if (mounted) setState(() => failed = false);
    } on Object {
      if (mounted) setState(() => failed = true);
    } finally {
      busy = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(preferencesProvider, (old, next) {
      if (old?.language != next.language) sync();
    });
    return Column(
      children: [
        if (failed)
          SafeArea(
            bottom: false,
            child: Material(
              child: ListTile(
                title: Text(context.l.errorStorage),
                trailing: TextButton(
                  onPressed: sync,
                  child: Text(context.l.retry),
                ),
              ),
            ),
          ),
        Expanded(child: widget.child),
      ],
    );
  }
}
