import '../core/utils/phone_utils.dart';
import '../core/utils/qr_content.dart';
import '../core/utils/url_utils.dart';
import '../localization/generated/app_localizations.dart';
import '../models/analysis_type.dart';
import '../models/scam_analysis.dart';
import 'scam_ai_service.dart';
import 'phone_reputation_service.dart';
import 'call_bridge.dart';
import 'number_repository.dart';

class AnalysisService {
  AnalysisService(this.ai, this.reputation, this.calls, {this.numbers});
  final NumberRepository? numbers;
  final ScamAiService ai;
  final PhoneReputationService reputation;
  final CallBridge calls;

  Future<ScamAnalysis> analyze(
    AnalysisInput input,
    String language,
    AppLocalizations l,
  ) => switch (input.type) {
    AnalysisType.text => analyzeText(input.content, language, l),
    AnalysisType.url => analyzeUrl(input.content, language, l),
    AnalysisType.phone => analyzePhoneNumber(
      input.content,
      language,
      l,
      context: input.context,
    ),
    AnalysisType.qr => analyzeQrContent(input.content, language, l),
    AnalysisType.incomingCall => throw const FormatException(
      'Calls use native evidence',
    ),
  };
  Future<ScamAnalysis> _ai(
    AnalysisInput input,
    String language,
    AppLocalizations l,
    Map<String, dynamic> signals,
  ) async {
    final result = await ai.analyze(
      text: input.content,
      type: input.type.name,
      language: language,
      l: l,
      localSignals: signals,
    );
    return result.withInput(input, signals);
  }

  Future<ScamAnalysis> analyzeText(
    String text,
    String language,
    AppLocalizations l,
  ) => _ai(AnalysisInput(AnalysisType.text, text), language, l, {
    'urls': UrlUtils.extract(text).map((u) => u.toJson()).toList(),
  });
  Future<ScamAnalysis> analyzeUrl(
    String url,
    String language,
    AppLocalizations l,
  ) {
    final signals = UrlRiskSignals.fromUrl(url);
    return _ai(
      AnalysisInput(AnalysisType.url, signals.url),
      language,
      l,
      signals.toJson(),
    );
  }

  ScamAnalysis unknown(
    AnalysisInput input,
    AppLocalizations l,
    Map<String, dynamic> details, {
    String? summary,
  }) => ScamAnalysis(
    riskScore: null,
    isScam: false,
    category: 'unknown',
    summary: summary ?? l.noReputation,
    reasons: const [],
    recommendations: [l.tipBody],
    origin: 'local',
  ).withInput(input, details);

  Future<ScamAnalysis> analyzePhoneNumber(
    String number,
    String language,
    AppLocalizations l, {
    String context = '',
  }) async {
    final phone = PhoneUtils.normalize(number);
    final personal = await numbers?.find(phone.number);
    final rep = await reputation.checkNumber(phone.number);
    await calls.cache(phone.number, rep.toJson());
    final input = AnalysisInput(
      AnalysisType.phone,
      phone.number,
      context: context,
    );
    final signals = <String, dynamic>{
      'number': phone.number,
      'country': phone.country,
      'reputation': rep.toJson(),
    };
    if (context.trim().isEmpty) {
      // A reputation category is evidence, not a calibrated numeric risk score.
      return unknown(
        input,
        l,
        {...signals, if (personal != null) 'personal': personal.toJson()},
        summary: personal != null && rep.status == 'unknown'
            ? l.personalSummary
            : rep.status == 'unknown'
            ? l.noReputation
            : l.reputationOnly,
      );
    }
    final result = await _ai(
      AnalysisInput(AnalysisType.phone, context.trim()),
      language,
      l,
      signals,
    );
    return result.withInput(input, {
      ...signals,
      'context': context.trim(),
      if (personal != null) 'personal': personal.toJson(),
    });
  }

  Future<ScamAnalysis> analyzeQrContent(
    String value,
    String language,
    AppLocalizations l,
  ) async {
    final qr = QrContent.decode(value);
    final input = AnalysisInput(AnalysisType.qr, qr.content);
    final metadata = <String, dynamic>{'qrType': qr.type.name, ...qr.fields};
    if ([
      QrContentType.wifi,
      QrContentType.contact,
      QrContentType.unknown,
    ].contains(qr.type)) {
      final safeInput = AnalysisInput(
        AnalysisType.qr,
        qr.type == QrContentType.wifi
            ? l.qrWifi
            : qr.type == QrContentType.contact
            ? l.qrContact
            : qr.content,
      );
      return unknown(safeInput, l, metadata, summary: l.qrInsufficient);
    }
    final ScamAnalysis result;
    if (qr.type == QrContentType.url) {
      result = await _ai(input, language, l, {
        ...metadata,
        ...UrlRiskSignals.fromUrl(qr.content).toJson(),
      });
    } else if (qr.type == QrContentType.phone) {
      result = await analyzePhoneNumber(qr.content, language, l);
    } else {
      result = await _ai(input, language, l, {
        ...metadata,
        'urls': UrlUtils.extract(qr.content).map((u) => u.toJson()).toList(),
      });
    }
    return result.withInput(input, {...result.details, ...metadata});
  }
}
