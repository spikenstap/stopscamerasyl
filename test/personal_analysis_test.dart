import 'package:flutter_test/flutter_test.dart';
import 'package:stopscam/core/api/backend_client.dart';
import 'package:stopscam/localization/generated/app_localizations.dart';
import 'package:stopscam/localization/generated/app_localizations_ru.dart';
import 'package:stopscam/models/personal_number.dart';
import 'package:stopscam/models/scam_analysis.dart';
import 'package:stopscam/services/analysis_service.dart';
import 'package:stopscam/services/call_bridge.dart';
import 'package:stopscam/services/number_repository.dart';
import 'package:stopscam/services/phone_reputation_service.dart';
import 'package:stopscam/services/scam_ai_service.dart';

class PrivateNumbers extends NumberRepository {
  @override
  Future<PersonalNumber?> find(String phone) async => PersonalNumber(
    phone: phone,
    label: 'Private label',
    note: 'Private note',
    rule: NumberRule.blocked,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}

class UnknownReputation extends PhoneReputationService {
  @override
  Future<PhoneReputation> checkNumber(String phoneNumber) async =>
      const PhoneReputation();
}

class RecordingAi extends ScamAiService {
  RecordingAi() : super(BackendClient(), config: {});
  Map<String, dynamic>? received;
  @override
  Future<ScamAnalysis> analyze({
    required String text,
    required String type,
    required String language,
    required AppLocalizations l,
    List<String> signals = const [],
    Map<String, dynamic> localSignals = const {},
  }) async {
    received = localSignals;
    return const ScamAnalysis(
      riskScore: 10,
      isScam: false,
      category: 'unknown',
      summary: 'Test',
      reasons: [],
      recommendations: ['Test'],
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'Personal blocking is not fraud evidence and private notes never reach AI',
    () async {
      final ai = RecordingAi();
      final service = AnalysisService(
        ai,
        UnknownReputation(),
        const CallBridge(),
        numbers: PrivateNumbers(),
      );
      final l = AppLocalizationsRu();
      final local = await service.analyzePhoneNumber('87001234567', 'ru', l);
      expect(local.riskScore, isNull);
      expect(local.isScam, false);
      expect(local.details['personal']['rule'], 'blocked');
      expect(ai.received, isNull);
      await service.analyzePhoneNumber(
        '87001234567',
        'ru',
        l,
        context: 'Пришлите код',
      );
      expect(ai.received, isNotNull);
      expect(ai.received.toString(), isNot(contains('Private')));
      expect(ai.received!.containsKey('personal'), false);
    },
  );
}
