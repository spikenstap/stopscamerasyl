import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/scan_history_item.dart';
import '../services/scam_ai_service.dart';
import '../services/analysis_service.dart';
import '../services/call_bridge.dart';
import '../services/phone_reputation_service.dart';
import '../services/number_report_service.dart';
import 'api/backend_client.dart';
import 'storage/local_storage.dart';
import '../features/numbers/number_providers.dart';

final storageProvider = Provider<LocalStorage>(
  (ref) => throw StateError('LocalStorage must be initialized before runApp'),
);
final backendClientProvider = Provider<BackendClient>((ref) => BackendClient());
final backendInitializationProvider = FutureProvider<void>(
  (ref) => ref.watch(backendClientProvider).initialize(),
  retry: (_, _) => null,
);
final numberReportServiceProvider = Provider<NumberReportService>(
  (ref) => NumberReportService(
    ref.watch(numberRepositoryProvider),
    ref.watch(backendClientProvider),
    () => ref.read(preferencesProvider).shareReports,
  ),
);
final aiServiceProvider = Provider<ScamAiService>(
  (ref) => ScamAiService(ref.watch(backendClientProvider)),
);
final callBridgeProvider = Provider<CallBridge>((ref) => const CallBridge());
final reputationProvider = Provider<PhoneReputationService>(
  (ref) => ConfigurablePhoneReputationService(
    ref.watch(storageProvider),
    ref.watch(backendClientProvider),
  ),
);
final analysisServiceProvider = Provider<AnalysisService>(
  (ref) => AnalysisService(
    ref.watch(aiServiceProvider),
    ref.watch(reputationProvider),
    ref.watch(callBridgeProvider),
    numbers: ref.watch(numberRepositoryProvider),
  ),
);

class Preferences {
  const Preferences(
    this.language,
    this.theme,
    this.onboarded, [
    this.shareReports = false,
  ]);
  final String language;
  final ThemeMode theme;
  final bool onboarded;
  final bool shareReports;
}

class PreferencesNotifier extends Notifier<Preferences> {
  @override
  Preferences build() {
    final p = ref.watch(storageProvider).prefs;
    return Preferences(
      p.getString('language') == 'kk' ? 'kk' : 'ru',
      ThemeMode.values.firstWhere(
        (m) => m.name == p.getString('themeMode'),
        orElse: () => ThemeMode.system,
      ),
      p.getBool('onboardingCompleted') ?? false,
      p.getBool('shareReports') ?? false,
    );
  }

  Future<void> language(String value) async {
    await ref.read(storageProvider).setString('language', value);
    state = Preferences(
      value,
      state.theme,
      state.onboarded,
      state.shareReports,
    );
  }

  Future<void> theme(ThemeMode value) async {
    await ref.read(storageProvider).setString('themeMode', value.name);
    state = Preferences(
      state.language,
      value,
      state.onboarded,
      state.shareReports,
    );
  }

  Future<void> shareReports(bool value) async {
    await ref.read(storageProvider).setBool('shareReports', value);
    state = Preferences(state.language, state.theme, state.onboarded, value);
  }

  Future<void> finishOnboarding() async {
    await ref.read(storageProvider).completeOnboarding();
    state = Preferences(state.language, state.theme, true, state.shareReports);
  }
}

final preferencesProvider = NotifierProvider<PreferencesNotifier, Preferences>(
  PreferencesNotifier.new,
);

class HistoryNotifier extends AsyncNotifier<List<ScanHistoryItem>> {
  @override
  Future<List<ScanHistoryItem>> build() async =>
      ref.watch(storageProvider).readHistory();
  // Serialize writes so a delete and an arriving scan cannot overwrite each other.
  Future<void> _tail = Future<void>.value();
  Future<void> _mutate(
    List<ScanHistoryItem> Function(List<ScanHistoryItem>) fn,
  ) {
    final operation = _tail.then((_) async {
      final old = await future;
      final next = fn(old);
      await ref.read(storageProvider).saveHistory(next);
      state = AsyncData(next);
    });
    _tail = operation.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {
        // Caller receives operation's error; the queue stays usable for later writes.
      },
    );
    return operation;
  }

  Future<void> add(ScanHistoryItem item) => _mutate(
    (old) => [item, ...old.where((e) => e.id != item.id)].take(200).toList(),
  );
  Future<void> remove(String id) =>
      _mutate((old) => old.where((e) => e.id != id).toList());
  Future<void> clear() {
    // Also permits clearing unreadable history after explicit user confirmation.
    final operation = _tail.then((_) async {
      await ref.read(storageProvider).saveHistory([]);
      state = const AsyncData([]);
    });
    _tail = operation.then<void>(
      (_) {},
      onError: (Object error, StackTrace stack) {
        debugPrint('History clear failed: ${error.runtimeType}');
      },
    );
    return operation;
  }
}

final historyProvider =
    AsyncNotifierProvider<HistoryNotifier, List<ScanHistoryItem>>(
      HistoryNotifier.new,
      retry: (_, _) => null,
    );
