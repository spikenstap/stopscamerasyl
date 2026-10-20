import 'package:flutter/services.dart';

import '../core/utils/phone_utils.dart';
import '../models/personal_number.dart';

/// Device-local SQLite repository shared with Android call screening.
class NumberRepository {
  const NumberRepository();
  static const channel = MethodChannel('kz.stopscam/numbers');
  Future<List<PersonalNumber>> all() async {
    final values = await channel.invokeListMethod<dynamic>('list') ?? [];
    return values
        .map(
          (v) => PersonalNumber.fromJson(Map<String, dynamic>.from(v as Map)),
        )
        .toList();
  }

  Future<PersonalNumber?> find(String phone) async {
    final value = await channel.invokeMapMethod<String, dynamic>('find', {
      'phone': PhoneUtils.normalize(phone).number,
    });
    return value == null ? null : PersonalNumber.fromJson(value);
  }

  Future<void> save({
    required String phone,
    required String label,
    required NumberRule rule,
    required ReportCategory category,
    required String note,
    String? originalPhone,
  }) async {
    await channel.invokeMethod<void>('save', {
      'phone': PhoneUtils.normalize(phone).number,
      'label': label.trim(),
      'rule': rule.name,
      'category': category.name,
      'note': note.trim(),
      'originalPhone': originalPhone,
    });
  }

  Future<void> delete(String phone) =>
      channel.invokeMethod<void>('delete', {'phone': phone});
  Future<void> report(String phone, ReportCategory category, String note) =>
      channel.invokeMethod<void>('report', {
        'phone': PhoneUtils.normalize(phone).number,
        'category': category.name,
        'note': note.trim(),
      });
  Future<List<NumberReport>> reports(String phone) async =>
      (await channel.invokeListMethod<dynamic>('reports', {'phone': phone}) ??
              [])
          .map(
            (e) => NumberReport.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList();
  Future<void> deleteReport(int id) =>
      channel.invokeMethod<void>('deleteReport', {'id': id});
  Future<String?> pickImport() => channel.invokeMethod<String>('pickImport');
  Future<bool> export(String csv) async =>
      await channel.invokeMethod<bool>('export', {'csv': csv}) ?? false;
  Future<Map<String, dynamic>> importNumbers(
    List<PersonalNumber> items, {
    required bool restoreRules,
  }) async =>
      await channel.invokeMapMethod<String, dynamic>('import', {
        'items': items.map((n) => n.toJson()).toList(),
        'restoreRules': restoreRules,
      }) ??
      {};
}
