import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stopscam/core/api/backend_client.dart';
import 'package:stopscam/core/storage/local_storage.dart';
import 'package:stopscam/core/utils/phone_utils.dart';
import 'package:stopscam/core/utils/qr_content.dart';
import 'package:stopscam/core/utils/url_utils.dart';
import 'package:stopscam/localization/generated/app_localizations_ru.dart';
import 'package:stopscam/models/analysis_type.dart';
import 'package:stopscam/models/scam_analysis.dart';
import 'package:stopscam/services/analysis_service.dart';
import 'package:stopscam/services/call_bridge.dart';
import 'package:stopscam/services/phone_reputation_service.dart';
import 'package:stopscam/services/scam_ai_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final l = AppLocalizationsRu();
  test(
    'Normalize Kazakh and international numbering without reputation guesses',
    () {
      expect(PhoneUtils.normalize('8 (700) 123-45-67').number, '+77001234567');
      expect(PhoneUtils.normalize('+1 202 555 0123').number, '+12025550123');
      expect(PhoneUtils.normalize('0077001234567').country, 'KZ');
      for (final input in ['12', 'abc', '+9991234567']) {
        expect(() => PhoneUtils.normalize(input), throwsFormatException);
      }
    },
  );
  test('QR decodes supported formats and redacts secrets', () {
    expect(QrContent.decode('https://google.com').type, QrContentType.url);
    expect(QrContent.decode('Обычное сообщение').type, QrContentType.text);
    expect(QrContent.decode('TEL:+77001234567').type, QrContentType.phone);
    expect(
      QrContent.decode('SMSTO:+77001234567:hello').type,
      QrContentType.sms,
    );
    expect(
      QrContent.decode('mailto:hello@example.com').type,
      QrContentType.email,
    );
    final wifi = QrContent.decode('WIFI:T:WPA;S:private;P:secret;;');
    expect(wifi.type, QrContentType.wifi);
    expect(wifi.content, isNot(contains('secret')));
    final contact = QrContent.decode('BEGIN:VCARD\nFN:Private Name\nEND:VCARD');
    expect(contact.content, isNot(contains('Private Name')));
    final payment = QrContent.decode('upi://pay?pa=merchant&am=12.50');
    expect(payment.type, QrContentType.payment);
    expect(payment.fields['amount'], '12.50');
    expect(
      QrContent.decode('000201540512.505903ABC').type,
      QrContentType.payment,
    );
    expect(QrContent.decode('custom:unknown').type, QrContentType.unknown);
  });
  test('URL evidence differs, extracts multiple URLs and avoids automatic verdicts', () {
    expect(UrlRiskSignals.fromUrl('https://google.com').signals, isEmpty);
    expect(
      UrlRiskSignals.fromUrl('http://verify-account-free-prize.example.com')
          .signals,
      containsAll(['unencrypted_http', 'keyword:verify', 'keyword:account']),
    );
    expect(
      UrlUtils.extract(
        'Посмотри https://google.com и http://example.com/login.',
      ).length,
      2,
    );
    expect(
      UrlRiskSignals.fromUrl('http://a123456.xyz:8080').signals,
      containsAll([
        'unusual_port',
        'many_digits_in_host',
        'tld_requires_context',
      ]),
    );
  });
  test('Unknown reputation never becomes a fake numeric or AI result; history roundtrip', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = LocalStorage(await SharedPreferences.getInstance());
    final service = AnalysisService(
      ScamAiService(BackendClient(), config: {}),
      ConfigurablePhoneReputationService(storage, BackendClient(config: {})),
      const CallBridge(),
    );
    final result = await service.analyzePhoneNumber('87001234567', 'ru', l);
    expect(result.riskScore, isNull);
    expect(result.origin, 'local');
    expect(result.analysisType, AnalysisType.phone);
    expect(result.details['reputation']['status'], 'unknown');
    expect(
      ScamAnalysis.fromJson(result.toJson(), stored: true).riskScore,
      isNull,
    );
    final wifi = await service.analyzeQrContent(
      'WIFI:T:WPA;S:private;P:secret;;',
      'ru',
      l,
    );
    expect(wifi.toJson().toString(), isNot(contains('secret')));
  });
  test(
    'Debug fixtures are varied, explicit and never used for API errors',
    () async {
      SharedPreferences.setMockInitialValues({});
      final storage = LocalStorage(await SharedPreferences.getInstance());
      final service = AnalysisService(
        ScamAiService(BackendClient(), config: {'USE_MOCK_AI': 'true'}),
        ConfigurablePhoneReputationService(storage, BackendClient(config: {})),
        const CallBridge(),
      );
      final safe = await service.analyzeText(
        'Привет, ты сегодня придёшь?',
        'ru',
        l,
      );
      final risky = await service.analyzeText(
        'Ваша карта заблокирована. Срочно сообщите SMS-код.',
        'ru',
        l,
      );
      expect(safe.riskScore, lessThan(risky.riskScore!));
      expect(safe.origin, 'mock');
      final qr = await service.analyzeQrContent(
        'http://verify-account-free-prize.example.com',
        'ru',
        l,
      );
      expect(qr.analysisType, AnalysisType.qr);
      expect(qr.riskScore, isNot(safe.riskScore));
    },
  );
  test('Strict confidence, evidence and recommendations validation', () {
    final valid = {
      'riskScore': 90,
      'confidence': .9,
      'riskLevel': 'critical',
      'isScam': true,
      'category': 'phishing',
      'summary': 'Evidence',
      'reasons': ['OTP requested'],
      'recommendations': ['Do not share'],
    };
    for (final confidence in [null, -.1, 1.1, 'high', double.nan]) {
      expect(
        () => ScamAnalysis.fromJson({...valid, 'confidence': confidence}),
        throwsFormatException,
      );
    }
    expect(
      () => ScamAnalysis.fromJson({...valid, 'reasons': []}),
      throwsFormatException,
    );
    expect(
      () => ScamAnalysis.fromJson({...valid, 'recommendations': []}),
      throwsFormatException,
    );
    final legacy = {...valid}..remove('confidence');
    expect(ScamAnalysis.fromJson(legacy, stored: true).confidence, isNull);
  });
}
