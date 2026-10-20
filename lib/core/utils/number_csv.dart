import '../../models/personal_number.dart';
import 'phone_utils.dart';

class NumberImport {
  const NumberImport(this.items, this.invalidLines, this.duplicates);
  final List<PersonalNumber> items;
  final List<int> invalidLines;
  final int duplicates;
}

abstract final class NumberCsv {
  static String encode(List<PersonalNumber> items) {
    String cell(String value) {
      // Spreadsheet formula injection must not execute a label or note on export.
      if (value.startsWith("'") || RegExp(r'^[=+@\-\t\r]').hasMatch(value)) {
        value = "'$value";
      }
      return '"${value.replaceAll('"', '""')}"';
    }

    return '\ufeffphone,label,rule,category,note\r\n${items.map((n) => [n.phone, n.label, n.rule.name, n.category.name, n.note].map(cell).join(',')).join('\r\n')}';
  }

  static NumberImport decode(String value) {
    if (value.length > 8 * 1024 * 1024) {
      throw const FormatException('CSV limit');
    }
    if (value.startsWith('\ufeff')) value = value.substring(1);
    final first = value.split(RegExp(r'[\r\n]')).first;
    final delimiter = first.contains(';')
        ? ';'
        : first.contains('\t')
        ? '\t'
        : ',';
    final rows = _rows(value, delimiter);
    if (rows.length > 5001) throw const FormatException('CSV row limit');
    if (rows.isEmpty) return const NumberImport([], [], 0);
    final header = rows.first.map((c) => c.trim().toLowerCase()).toList();
    final hasHeader = [
      'phone',
      'number',
      'номер',
      'телефон',
    ].contains(header.first);
    String read(List<String> row, String name, {String fallback = ''}) {
      final index = hasHeader
          ? header.indexOf(name)
          : (name == 'phone' ? 0 : -1);
      var text = index >= 0 && index < row.length
          ? row[index].trim()
          : fallback;
      if (text.length > 1 &&
          text.startsWith("'") &&
          (text[1] == "'" ||
              RegExp(r'^[=+@\-\t\r]').hasMatch(text.substring(1)))) {
        text = text.substring(1);
      }
      return text;
    }

    final items = <PersonalNumber>[], invalid = <int>[], seen = <String>{};
    var duplicates = 0;
    for (var at = hasHeader ? 1 : 0; at < rows.length; at++) {
      final row = rows[at];
      if (row.every((c) => c.trim().isEmpty)) continue;
      try {
        final rawPhone = hasHeader && header.first != 'phone'
            ? row.first
            : read(row, 'phone');
        final phone = PhoneUtils.normalize(
          rawPhone.startsWith("'") ? rawPhone.substring(1) : rawPhone,
        ).number;
        final label = read(row, 'label'), note = read(row, 'note');
        if (label.length > 100 ||
            note.length > 500 ||
            label.contains('\u0000') ||
            note.contains('\u0000')) {
          throw const FormatException('CSV field limit');
        }
        final rule = NumberRule.values.firstWhere(
          (e) => e.name == read(row, 'rule'),
          orElse: () => NumberRule.watch,
        );
        final category = ReportCategory.values.firstWhere(
          (e) => e.name == read(row, 'category'),
          orElse: () => ReportCategory.unknown,
        );
        if (!seen.add(phone)) {
          duplicates++;
          continue;
        }
        final now = DateTime.now();
        items.add(
          PersonalNumber(
            phone: phone,
            label: label,
            rule: rule,
            category: category,
            note: note,
            createdAt: now,
            updatedAt: now,
          ),
        );
      } on FormatException {
        invalid.add(at + 1);
      }
    }
    if (items.length > 5000) throw const FormatException('CSV row limit');
    return NumberImport(items, invalid, duplicates);
  }

  static List<List<String>> _rows(String input, String delimiter) {
    final rows = <List<String>>[];
    var row = <String>[], cell = StringBuffer();
    var quoted = false, closed = false;
    void field() {
      row.add(cell.toString());
      cell = StringBuffer();
      closed = false;
    }

    void line() {
      field();
      if (row.any((s) => s.trim().isNotEmpty)) rows.add(row);
      row = [];
      if (rows.length > 5001) throw const FormatException('CSV row limit');
    }

    for (var i = 0; i < input.length; i++) {
      final char = input[i];
      if (quoted) {
        if (char == '"') {
          if (i + 1 < input.length && input[i + 1] == '"') {
            cell.write('"');
            i++;
          } else {
            quoted = false;
            closed = true;
          }
        } else {
          cell.write(char);
        }
        continue;
      }
      if (char == delimiter) {
        field();
      } else if (char == '\r' || char == '\n') {
        line();
        if (char == '\r' && i + 1 < input.length && input[i + 1] == '\n') i++;
      } else if (char == '"' && cell.isEmpty && !closed) {
        quoted = true;
      } else {
        if (closed && char.trim().isNotEmpty) {
          throw const FormatException('Malformed CSV');
        }
        if (!closed) cell.write(char);
      }
    }
    if (quoted) throw const FormatException('Unclosed CSV quote');
    if (cell.isNotEmpty || row.isNotEmpty || closed) line();
    return rows;
  }
}
