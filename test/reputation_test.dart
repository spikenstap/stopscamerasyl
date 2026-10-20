import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stopscam/core/storage/local_storage.dart';
import 'package:stopscam/services/phone_reputation_service.dart';

import 'api_test.dart' show TestAdapter;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'Configured reputation uses normalized request and caches real evidence',
    () async {
      SharedPreferences.setMockInitialValues({});
      final adapter = TestAdapter(200, {
        'status': 'flagged',
        'confidence': .99,
        'confirmed': true,
        'source': 'test-provider',
      });
      final storage = LocalStorage(await SharedPreferences.getInstance());
      final service = ConfigurablePhoneReputationService(storage, {
        'PHONE_REPUTATION_API_URL': 'https://example.com/reputation',
      }, dio: Dio()..httpClientAdapter = adapter);
      final result = await service.checkNumber('+77001234567');
      expect(result.status, 'flagged');
      expect(result.source, 'test-provider');
      expect(adapter.request!.data, {'phoneNumber': '+77001234567'});
      expect(
        result.expiresAt!.difference(DateTime.now()).inHours,
        lessThanOrEqualTo(24),
      );
      await service.checkNumber('+77001234567');
      expect(adapter.calls, 1);
    },
  );
  test(
    'Expired provider evidence and request errors do not produce reputations',
    () async {
      SharedPreferences.setMockInitialValues({});
      final storage = LocalStorage(await SharedPreferences.getInstance());
      for (final adapter in [
        TestAdapter(200, {
          'status': 'flagged',
          'confidence': 1,
          'confirmed': true,
          'source': 'test',
          'expiresAt': 1,
        }),
        TestAdapter(503, {'error': 'private provider details'}),
      ]) {
        final service = ConfigurablePhoneReputationService(storage, {
          'PHONE_REPUTATION_API_URL': 'https://example.com',
        }, dio: Dio()..httpClientAdapter = adapter);
        final result = await service.checkNumber('+77001234567');
        expect(result.status, 'unknown');
        expect(result.reason, 'unavailable');
        expect(result.confirmed, false);
      }
    },
  );
  test('Reputation rejects invented categories and invalid confidence', () {
    for (final confidence in [-1, 1.1, double.nan, 'high']) {
      expect(
        () => PhoneReputation.fromJson({
          'status': 'flagged',
          'confidence': confidence,
          'confirmed': true,
          'source': 'test',
        }),
        throwsFormatException,
      );
    }
  });
}
