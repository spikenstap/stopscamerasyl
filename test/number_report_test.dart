import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stopscam/core/providers.dart';
import 'package:stopscam/core/storage/local_storage.dart';
import 'package:stopscam/models/personal_number.dart';
import 'package:stopscam/services/number_report_service.dart';
import 'package:stopscam/services/number_repository.dart';

import 'support/backend_fakes.dart';

class RecordingRepository extends NumberRepository {
  int writes = 0;
  bool fail = false;
  String? savedNote;
  @override
  Future<void> report(
    String phone,
    ReportCategory category,
    String note,
  ) async {
    if (fail) throw StateError('disk full');
    writes++;
    savedNote = note;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'Sharing defaults off, persists and survives other preference changes',
    () async {
      SharedPreferences.setMockInitialValues({});
      final storage = LocalStorage(await SharedPreferences.getInstance());
      ProviderContainer make() => ProviderContainer(
        overrides: [storageProvider.overrideWithValue(storage)],
      );
      final container = make();
      expect(container.read(preferencesProvider).shareReports, false);
      final notifier = container.read(preferencesProvider.notifier);
      await notifier.shareReports(true);
      await notifier.language('kk');
      await notifier.theme(ThemeMode.dark);
      await notifier.finishOnboarding();
      expect(container.read(preferencesProvider).shareReports, true);
      container.dispose();
      final next = make();
      expect(next.read(preferencesProvider).shareReports, true);
      await next.read(preferencesProvider.notifier).shareReports(false);
      expect(storage.prefs.getBool('shareReports'), false);
      next.dispose();
    },
  );
  test('Off sends nothing; on sends only normalized phone/category; disabling stops', () async {
    final adapter = TestAdapter(200, {'accepted': true});
    final repository = RecordingRepository();
    var enabled = false;
    final service = NumberReportService(
      repository,
      adapter.client(),
      () => enabled,
    );
    expect(
      await service.save(
        '87001234567',
        ReportCategory.advertising,
        'private note',
      ),
      ReportSharingResult.localOnly,
    );
    expect(adapter.requests, isEmpty);
    enabled = true;
    expect(
      await service.save(
        '87001234567',
        ReportCategory.suspectedFraud,
        'secret',
      ),
      ReportSharingResult.shared,
    );
    expect(adapter.request!.uri.path, '/v1/phone/report');
    expect(adapter.request!.data, {
      'phoneNumber': '+77001234567',
      'category': 'suspectedFraud',
    });
    expect(repository.savedNote, 'secret');
    enabled = false;
    await service.save('87001234567', ReportCategory.other, 'offline');
    expect(adapter.calls, 1);
    expect(repository.writes, 3);
  });
  test(
    'Failed local save never sends; failed remote send preserves local report',
    () async {
      final adapter = TestAdapter(503, {});
      final repository = RecordingRepository()..fail = true;
      final service = NumberReportService(
        repository,
        adapter.client(),
        () => true,
      );
      await expectLater(
        service.save('87001234567', ReportCategory.other, 'private'),
        throwsStateError,
      );
      expect(adapter.requests, isEmpty);
      repository.fail = false;
      expect(
        await service.save('87001234567', ReportCategory.other, 'private'),
        ReportSharingResult.sharingFailed,
      );
      expect(repository.writes, 1);
      expect(repository.savedNote, 'private');
      expect(adapter.calls, 1);
    },
  );
  test('Unknown category stays local even with sharing enabled', () async {
    final adapter = TestAdapter(200, {'accepted': true});
    await NumberReportService(
      RecordingRepository(),
      adapter.client(),
      () => true,
    ).save('87001234567', ReportCategory.unknown, '');
    expect(adapter.requests, isEmpty);
  });
}
