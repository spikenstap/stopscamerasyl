import 'package:flutter_test/flutter_test.dart';
import 'package:stopscam/localization/generated/app_localizations_ru.dart';
import 'package:stopscam/models/analysis_type.dart';
import 'package:stopscam/services/analysis_service.dart';
import 'package:stopscam/services/call_bridge.dart';
import 'package:stopscam/services/phone_reputation_service.dart';
import 'package:stopscam/services/scam_ai_service.dart';

import 'support/backend_fakes.dart';

class _Unknown extends PhoneReputationService {
  @override
  Future<PhoneReputation> checkNumber(String phoneNumber) async =>
      const PhoneReputation();
}

void main() {
  test(
    'Text QR uses text backend contract; URL QR uses qr; history preserves QR',
    () async {
      final adapter = TestAdapter(200, safeResult);
      final service = AnalysisService(
        ScamAiService(adapter.client(), config: {}),
        _Unknown(),
        const CallBridge(),
      );
      for (final c in [
        ('Hello world', 'text'),
        ('https://example.com', 'qr'),
      ]) {
        final result = await service.analyzeQrContent(
          c.$1,
          'ru',
          AppLocalizationsRu(),
        );
        expect(adapter.request!.data['type'], c.$2);
        expect(result.analysisType, AnalysisType.qr);
      }
      final calls = adapter.calls;
      await service.analyzeQrContent(
        'WIFI:T:WPA;S:private;P:secret;;',
        'ru',
        AppLocalizationsRu(),
      );
      expect(adapter.calls, calls);
    },
  );
}
