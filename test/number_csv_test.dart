import 'package:flutter_test/flutter_test.dart';
import 'package:stopscam/core/utils/number_csv.dart';
import 'package:stopscam/models/personal_number.dart';

void main() {
  test(
    'CSV roundtrip preserves Unicode, quotes, multiline notes and rules',
    () {
      final n = PersonalNumber(
        phone: '+77001234567',
        label: '=Тест, "QA"',
        note: 'Строка 1\nСтрока 2',
        rule: NumberRule.blocked,
        category: ReportCategory.advertising,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final csv = NumberCsv.encode([n]);
      expect(csv, contains("'=Тест"));
      expect(csv, contains("'+77001234567"));
      final parsed = NumberCsv.decode(csv);
      expect(parsed.invalidLines, isEmpty);
      expect(parsed.items.single.phone, n.phone);
      expect(parsed.items.single.label, n.label);
      expect(parsed.items.single.note, n.note);
      expect(parsed.items.single.rule, NumberRule.blocked);
    },
  );
  test('CSV preview normalizes, deduplicates and rejects bad rows', () {
    final parsed = NumberCsv.decode(
      'phone;label;rule\n87001234567;Тест;trusted\n+77001234567;Дубликат;blocked\n123;Ошибка;watch\n+77011234567;Второй;bogus',
    );
    expect(parsed.items.length, 2);
    expect(parsed.duplicates, 1);
    expect(parsed.invalidLines.length, 1);
    expect(parsed.items.last.rule, NumberRule.watch);
  });
  test('Plain numbers, translated header and tab files work', () {
    expect(NumberCsv.decode('87001234567\n+77011234567').items.length, 2);
    expect(
      NumberCsv.decode('номер\n87001234567').items.single.phone,
      '+77001234567',
    );
    expect(
      NumberCsv.decode('phone\tlabel\n87001234567\tТест').items.single.label,
      'Тест',
    );
  });
  test('Broken quotes and oversized files fail before import', () {
    expect(
      () => NumberCsv.decode('phone,label\n"+77001234567'),
      throwsFormatException,
    );
    expect(
      () => NumberCsv.decode('phone,label\n"+77001234567"bad,test'),
      throwsFormatException,
    );
    expect(
      () => NumberCsv.decode('x' * (8 * 1024 * 1024 + 1)),
      throwsFormatException,
    );
  });
}
