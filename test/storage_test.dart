import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stopscam/core/providers.dart';
import 'package:stopscam/core/storage/local_storage.dart';
import 'package:stopscam/models/scan_history_item.dart';
import 'package:stopscam/models/scam_analysis.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  ScanHistoryItem item(String id) => ScanHistoryItem(
    id: id,
    type: 'text',
    source: 'hello',
    date: DateTime(2026),
    language: 'ru',
    isMock: true,
    analysis: const ScamAnalysis(
      riskScore: 10,
      isScam: false,
      category: 'unknown',
      summary: 'test',
      reasons: [],
      recommendations: [],
    ),
  );
  test(
    'Concurrent history mutations preserve their order across reload',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = LocalStorage(prefs);
      final container = ProviderContainer(
        overrides: [storageProvider.overrideWithValue(storage)],
      );
      addTearDown(container.dispose);
      await container.read(historyProvider.future);
      final history = container.read(historyProvider.notifier);
      await Future.wait([
        history.add(item('a')),
        history.add(item('b')),
        history.remove('a'),
      ]);
      expect(storage.readHistory().map((e) => e.id), ['b']);
      await Future.wait([history.clear(), history.add(item('c'))]);
      expect(storage.readHistory().map((e) => e.id), ['c']);
      container.invalidate(historyProvider);
      expect((await container.read(historyProvider.future)).single.id, 'c');
    },
  );
  test(
    'Corrupt history is not silently overwritten and can be cleared',
    () async {
      SharedPreferences.setMockInitialValues({'history': 'broken'});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [storageProvider.overrideWithValue(LocalStorage(prefs))],
      );
      addTearDown(container.dispose);
      await expectLater(
        container.read(historyProvider.future),
        throwsException,
      );
      expect(prefs.getString('history'), 'broken');
      await container.read(historyProvider.notifier).clear();
      expect(await container.read(historyProvider.future), isEmpty);
    },
  );
}
