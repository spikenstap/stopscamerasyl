import 'dart:convert';

import 'analysis_type.dart';

class ScamAnalysis {
  const ScamAnalysis({
    required this.riskScore,
    required this.isScam,
    required this.category,
    required this.summary,
    required this.reasons,
    required this.recommendations,
    this.confidence,
    this.analysisType = AnalysisType.text,
    this.input = '',
    this.timestamp,
    this.origin = 'ai',
    this.details = const {},
  });
  final int? riskScore;
  final double? confidence;
  final AnalysisType analysisType;
  final String input, origin;
  final DateTime? timestamp;
  final Map<String, dynamic> details;
  final bool isScam;
  final String category;
  final String summary;
  final List<String> reasons;
  final List<String> recommendations;

  static const categories = [
    'phishing',
    'fake_bank',
    'social_engineering',
    'investment_scam',
    'fake_delivery',
    'account_theft',
    'malicious_link',
    'suspicious_message',
    'unknown',
  ];
  String get riskLevel => riskScore == null ? 'unknown' : levelFor(riskScore!);
  static String levelFor(int score) => score <= 20
      ? 'safe'
      : score <= 40
      ? 'low'
      : score <= 60
      ? 'medium'
      : score <= 80
      ? 'high'
      : 'critical';

  factory ScamAnalysis.fromJson(
    Map<String, dynamic> json, {
    bool stored = false,
  }) {
    final score = json['riskScore'];
    final confidence = json['confidence'];
    final localUnknown = stored && json['origin'] == 'local' && score == null;
    if ((!localUnknown && (score is! int || score < 0 || score > 100)) ||
        (!stored &&
            (confidence is! num ||
                !confidence.isFinite ||
                confidence < 0 ||
                confidence > 1)) ||
        (stored &&
            confidence != null &&
            (confidence is! num ||
                !confidence.isFinite ||
                confidence < 0 ||
                confidence > 1)) ||
        json['isScam'] is! bool ||
        ![
          'safe',
          'low',
          'medium',
          'high',
          'critical',
          if (localUnknown) 'unknown',
        ].contains(json['riskLevel']) ||
        !categories.contains(json['category'])) {
      throw const FormatException('Invalid analysis fields');
    }
    String string(String key) {
      final value = json[key];
      if (value is! String || value.trim().isEmpty || value.length > 5000) {
        throw FormatException('Invalid $key');
      }
      return value.trim();
    }

    List<String> strings(String key) {
      final value = json[key];
      if (value is! List ||
          value.length > 20 ||
          value.any(
            (v) => v is! String || v.trim().isEmpty || v.length > 3000,
          )) {
        throw FormatException('Invalid $key');
      }
      return List<String>.unmodifiable(value.cast<String>());
    }

    final reasons = strings('reasons');
    final recommendations = strings('recommendations');
    if (!stored &&
        ((score as int) > 20 && reasons.isEmpty || recommendations.isEmpty)) {
      throw const FormatException('Missing evidence or recommendations');
    }
    return ScamAnalysis(
      riskScore: score,
      confidence: (confidence as num?)?.toDouble(),
      analysisType: AnalysisType.values.firstWhere(
        (v) => v.name == json['analysisType'],
        orElse: () => AnalysisType.text,
      ),
      input: json['input'] as String? ?? '',
      timestamp: json['timestamp'] == null
          ? null
          : DateTime.parse(json['timestamp'] as String),
      origin: json['origin'] as String? ?? (stored ? 'legacy' : 'ai'),
      details: (json['details'] as Map?)?.cast<String, dynamic>() ?? const {},
      isScam: json['isScam'] as bool,
      category: string('category'),
      summary: string('summary'),
      reasons: reasons,
      recommendations: recommendations,
    );
  }

  /// Accept fenced JSON and prose wrappers, but never evaluate generated code.
  static ScamAnalysis parse(String raw) {
    final start = raw.indexOf('{');
    final end = raw.lastIndexOf('}');
    if (raw.length > 100000 || start < 0 || end < start) {
      throw const FormatException('Missing JSON object');
    }
    final value = jsonDecode(raw.substring(start, end + 1));
    if (value is! Map<String, dynamic>) {
      throw const FormatException('Expected object');
    }
    return ScamAnalysis.fromJson(value);
  }

  Map<String, dynamic> toJson() => {
    'confidence': confidence,
    'analysisType': analysisType.name,
    'input': input,
    'timestamp': timestamp?.toIso8601String(),
    'origin': origin,
    'details': details,
    'riskScore': riskScore,
    'riskLevel': riskLevel,
    'isScam': isScam,
    'category': category,
    'summary': summary,
    'reasons': reasons,
    'recommendations': recommendations,
  };

  ScamAnalysis withInput(
    AnalysisInput value,
    Map<String, dynamic> metadata, {
    String? source,
  }) => ScamAnalysis(
    riskScore: riskScore,
    confidence: confidence,
    isScam: isScam,
    category: category,
    summary: summary,
    reasons: reasons,
    recommendations: recommendations,
    analysisType: value.type,
    input: value.content,
    timestamp: DateTime.now(),
    origin: source ?? origin,
    details: metadata,
  );
}
