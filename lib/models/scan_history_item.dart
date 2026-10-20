import 'scam_analysis.dart';

class ScanHistoryItem {
  const ScanHistoryItem({
    required this.id,
    required this.type,
    required this.source,
    required this.date,
    required this.language,
    required this.isMock,
    required this.analysis,
  });
  final String id, type, source, language;
  final DateTime date;
  final bool isMock;
  final ScamAnalysis analysis;
  factory ScanHistoryItem.fromJson(Map<String, dynamic> j) => ScanHistoryItem(
    id: j['id'] as String,
    type: j['type'] as String,
    source: j['source'] as String,
    date: DateTime.parse(j['date'] as String),
    language: j['language'] as String,
    isMock: j['isMock'] as bool,
    analysis: ScamAnalysis.fromJson({
      'analysisType': j['type'],
      'input': j['source'],
      'timestamp': j['date'],
      ...j['analysis'] as Map<String, dynamic>,
    }, stored: true),
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'source': source,
    'date': date.toIso8601String(),
    'language': language,
    'isMock': isMock,
    'analysis': analysis.toJson(),
  };
}
