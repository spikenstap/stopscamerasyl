import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stopscam/core/api/api_client.dart';
import 'package:stopscam/core/utils/url_utils.dart';
import 'package:stopscam/localization/generated/app_localizations_ru.dart';
import 'package:stopscam/services/scam_ai_service.dart';

void main() {
  test(
    'Live provider: different real inputs and strict JSON',
    () async {
      final env = DotEnv()
        ..loadFromString(envString: File('.env').readAsStringSync());
      final service = ScamAiService(
        ApiClient(),
        config: {...env.env, 'USE_MOCK_AI': 'false'},
      );
      final cases = [
        ('text', 'Привет, ты сегодня придёшь?'),
        ('text', 'Ваша карта заблокирована. Срочно сообщите SMS-код.'),
        ('url', 'https://google.com'),
        ('url', 'http://verify-account-free-prize.example.com'),
        ('text', 'Поздравляем, вы выиграли 500 000 ₸. Оплатите комиссию.'),
      ];
      final scores = <int>[];
      for (var i = 0; i < cases.length; i++) {
        final c = cases[i];
        final result = await service.analyze(
          text: c.$2,
          type: c.$1,
          language: 'ru',
          l: AppLocalizationsRu(),
          localSignals: c.$1 == 'url'
              ? UrlRiskSignals.fromUrl(c.$2).toJson()
              : {},
        );
        expect(result.confidence, inInclusiveRange(0, 1));
        expect(result.riskScore, inInclusiveRange(0, 100));
        scores.add(result.riskScore!);
        // No prompts, API keys, auth headers or provider error bodies are logged.
        // ignore: avoid_print
        print(
          'LIVE case=${i + 1} risk=${result.riskScore} confidence=${result.confidence}',
        );
      }
      expect(scores[0], lessThan(40));
      expect(scores[1], greaterThan(scores[0]));
      expect(scores[3], greaterThan(scores[2]));
    },
    skip: !const bool.fromEnvironment('STOPSCAM_LIVE_TEST'),
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
