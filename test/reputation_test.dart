import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stopscam/core/storage/local_storage.dart';
import 'package:stopscam/services/phone_reputation_service.dart';

import 'support/backend_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'Server cannot extend cache beyond 24h; expired/corrupt cache is replaced',
    () async {
      for (final cached in [
        'broken',
        jsonEncode({
          'status': 'flagged',
          'confidence': 1,
          'confirmed': true,
          'source': 'stale',
          'expiresAt': 1,
        }),
        jsonEncode({
          'status': 'flagged',
          'confidence': 1,
          'confirmed': true,
          'source': 'overlong',
          'expiresAt': DateTime.now()
              .add(const Duration(days: 3))
              .millisecondsSinceEpoch,
        }),
      ]) {
        SharedPreferences.setMockInitialValues({
          'reputation:https://example.com:+77001234567': cached,
        });
        final adapter = TestAdapter(200, {
          'status': 'unknown',
          'confidence': 0,
          'confirmed': false,
          'source': '',
          'expiresAt': DateTime.now()
              .add(const Duration(days: 3))
              .millisecondsSinceEpoch,
        });
        final service = ConfigurablePhoneReputationService(
          LocalStorage(await SharedPreferences.getInstance()),
          adapter.client(),
        );
        final before = DateTime.now();
        final result = await service.checkNumber('+77001234567');
        expect(result.status, 'unknown');
        expect(
          result.expiresAt!.difference(before).inSeconds,
          lessThanOrEqualTo(86401),
        );
        expect(adapter.calls, 1);
        expect(adapter.request!.uri.path, '/v1/phone/check');
        await service.checkNumber('+77001234567');
        expect(adapter.calls, 1);
      }
    },
  );
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
      final service = ConfigurablePhoneReputationService(
        storage,
        adapter.client(),
      );
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
        final service = ConfigurablePhoneReputationService(
          storage,
          adapter.client(),
        );
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
