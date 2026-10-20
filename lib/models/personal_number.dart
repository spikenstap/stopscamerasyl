import '../core/utils/phone_utils.dart';

enum NumberRule { watch, blocked, trusted }

enum ReportCategory { unknown, advertising, suspectedFraud, harassment, other }

class PersonalNumber {
  const PersonalNumber({
    required this.phone,
    this.label = '',
    this.rule = NumberRule.watch,
    this.category = ReportCategory.unknown,
    this.note = '',
    required this.createdAt,
    required this.updatedAt,
    this.reportCount = 0,
  });
  final String phone, label, note;
  final NumberRule rule;
  final ReportCategory category;
  final DateTime createdAt, updatedAt;
  final int reportCount;
  factory PersonalNumber.fromJson(Map<String, dynamic> j) => PersonalNumber(
    phone: PhoneUtils.normalize(j['phone'] as String).number,
    label: j['label'] as String,
    rule: NumberRule.values.byName(j['rule'] as String),
    category: ReportCategory.values.byName(j['category'] as String),
    note: j['note'] as String,
    createdAt: DateTime.fromMillisecondsSinceEpoch(j['createdAt'] as int),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(j['updatedAt'] as int),
    reportCount: j['reportCount'] as int? ?? 0,
  );
  Map<String, dynamic> toJson() => {
    'phone': phone,
    'label': label,
    'rule': rule.name,
    'category': category.name,
    'note': note,
    'createdAt': createdAt.millisecondsSinceEpoch,
    'updatedAt': updatedAt.millisecondsSinceEpoch,
    'reportCount': reportCount,
  };
}

class NumberReport {
  const NumberReport({
    required this.id,
    required this.phone,
    required this.category,
    required this.note,
    required this.createdAt,
  });
  final int id;
  final String phone, note;
  final ReportCategory category;
  final DateTime createdAt;
  factory NumberReport.fromJson(Map<String, dynamic> j) => NumberReport(
    id: j['id'] as int,
    phone: j['phone'] as String,
    category: ReportCategory.values.byName(j['category'] as String),
    note: j['note'] as String,
    createdAt: DateTime.fromMillisecondsSinceEpoch(j['createdAt'] as int),
  );
}
