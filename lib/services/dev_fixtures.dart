import '../localization/generated/app_localizations.dart';
import '../models/scam_analysis.dart';

/// Development fixtures only. Never a fallback for a failed network request.
abstract final class DevFixtures {
  static ScamAnalysis forInput(
    String text,
    List<String> signals,
    AppLocalizations l,
  ) {
    final otp = RegExp(
      r'sms|otp|смс|код|құпиясөз',
      caseSensitive: false,
    ).hasMatch(text);
    final money = RegExp(
      r'выиграл|комисси|инвест|ұтыс|төлем|prize|winner',
      caseSensitive: false,
    ).hasMatch(text);
    final urgency = RegExp(
      r'срочно|заблок|шұғыл|urgent|blocked',
      caseSensitive: false,
    ).hasMatch(text);
    final signalText = signals.join(' ');
    final flags = [
      if (otp) l.fixtureOtp,
      if (money) l.fixtureMoney,
      if (urgency) l.fixtureUrgency,
      if (signalText.contains('unencrypted_http') ||
          signalText.contains('keyword:'))
        l.fixtureUrl,
    ];
    final level = flags.length.clamp(0, 4);
    final score = [8, 28, 52, 76, 94][level];
    return ScamAnalysis(
      riskScore: score,
      confidence: .5,
      isScam: score > 60,
      category: score > 60 ? 'phishing' : 'unknown',
      summary: l.fixtureSummary,
      reasons: flags,
      recommendations: [l.tipBody],
      origin: 'mock',
    );
  }
}
