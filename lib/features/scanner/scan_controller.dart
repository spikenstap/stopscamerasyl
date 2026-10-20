import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_exception.dart';
import '../../core/providers.dart';
import '../../models/analysis_type.dart';
import '../../localization/generated/app_localizations.dart';
import '../../models/scan_history_item.dart';

enum ScanStatus { idle, validating, analyzing, success, error }

class ScanState {
  const ScanState({
    this.status = ScanStatus.idle,
    this.item,
    this.failure,
    this.saveFailed = false,
  });
  final ScanStatus status;
  final ScanHistoryItem? item;
  final Failure? failure;
  final bool saveFailed;
}

class ScanController extends Notifier<ScanState> {
  @override
  ScanState build() => const ScanState();
  void reset() {
    if (state.status != ScanStatus.analyzing) state = const ScanState();
  }

  Future<void> scan(String source, bool isUrl, AppLocalizations l) async {
    await analyze(
      AnalysisInput(isUrl ? AnalysisType.url : AnalysisType.text, source),
      l,
    );
  }

  Future<void> analyze(AnalysisInput input, AppLocalizations l) async {
    if (state.status == ScanStatus.analyzing) return;
    state = const ScanState(status: ScanStatus.validating);
    try {
      final text = input.content.trim();
      if (text.isEmpty || text.length > 12000) {
        throw const ApiException(Failure.unknown);
      }
      final lang = ref.read(preferencesProvider).language;
      state = const ScanState(status: ScanStatus.analyzing);
      final result = await ref
          .read(analysisServiceProvider)
          .analyze(input, lang, l);
      final now = DateTime.now();
      final item = ScanHistoryItem(
        id: now.microsecondsSinceEpoch.toString(),
        type: input.type.name,
        source: result.input,
        date: now,
        language: lang,
        isMock: result.origin == 'mock',
        analysis: result,
      );
      var saveFailed = false;
      try {
        await ref.read(historyProvider.notifier).add(item);
      } on Object {
        saveFailed = true;
      }
      state = ScanState(
        status: ScanStatus.success,
        item: item,
        saveFailed: saveFailed,
      );
    } on ApiException catch (e) {
      state = ScanState(status: ScanStatus.error, failure: e.failure);
    } on Object {
      state = const ScanState(
        status: ScanStatus.error,
        failure: Failure.unknown,
      );
    }
  }
}

final scanProvider = NotifierProvider<ScanController, ScanState>(
  ScanController.new,
);
