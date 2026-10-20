import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../core/utils/phone_utils.dart';
import '../../core/widgets/common.dart';
import '../../localization/generated/app_localizations.dart';
import '../../models/personal_number.dart';
import 'number_providers.dart';

String numberRuleLabel(AppLocalizations l, NumberRule rule) => switch (rule) {
  NumberRule.watch => l.ruleWatch,
  NumberRule.blocked => l.ruleBlocked,
  NumberRule.trusted => l.ruleTrusted,
};
String numberRuleBody(AppLocalizations l, NumberRule rule) => switch (rule) {
  NumberRule.watch => l.ruleWatchBody,
  NumberRule.blocked => l.ruleBlockedBody,
  NumberRule.trusted => l.ruleTrustedBody,
};
String numberCategoryLabel(AppLocalizations l, ReportCategory category) =>
    switch (category) {
      ReportCategory.unknown => l.categoryUnknown,
      ReportCategory.advertising => l.categoryAdvertising,
      ReportCategory.suspectedFraud => l.categorySuspectedFraud,
      ReportCategory.harassment => l.categoryHarassment,
      ReportCategory.other => l.categoryOther,
    };
IconData numberRuleIcon(NumberRule rule) => switch (rule) {
  NumberRule.watch => Icons.visibility_outlined,
  NumberRule.blocked => Icons.block,
  NumberRule.trusted => Icons.check_circle_outline,
};
Color numberRuleColor(NumberRule rule) => switch (rule) {
  NumberRule.watch => AppColors.primary,
  NumberRule.blocked => AppColors.danger,
  NumberRule.trusted => AppColors.success,
};
String numberError(AppLocalizations l, Object error) {
  if (error is FormatException) return l.numberFileError;
  if (error is PlatformException) {
    return switch (error.code) {
      'duplicate' => l.numberDuplicate,
      'missing' => l.numberMissing,
      'limit' => l.numberLimit,
      'invalid' => l.numberInvalid,
      'io' => l.numberFileError,
      _ => l.numberStorageError,
    };
  }
  return l.numberStorageError;
}

String numberRoute(String path, String phone) =>
    Uri(path: path, queryParameters: {'phone': phone}).toString();

class PersonalNumberActions extends ConsumerWidget {
  const PersonalNumberActions({super.key, required this.phone});
  final String phone;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String normalized;
    try {
      normalized = PhoneUtils.normalize(phone).number;
    } on FormatException {
      return const SizedBox.shrink();
    }
    final l = context.l, entry = ref.watch(personalNumberProvider(normalized));
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.personalMark, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          entry.when(
            data: (n) => Text(
              n == null
                  ? l.numberNotSaved
                  : '${numberRuleLabel(l, n.rule)}${n.label.isEmpty ? '' : ' · ${n.label}'}',
            ),
            error: (e, _) => Text(numberError(l, e)),
            loading: () => const LinearProgressIndicator(),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () =>
                context.push(numberRoute('/number-edit', normalized)),
            icon: const Icon(Icons.edit_outlined),
            label: Text(
              entry.asData?.value == null ? l.numberAdd : l.numbersManage,
            ),
          ),
          TextButton.icon(
            onPressed: () =>
                context.push(numberRoute('/number-report', normalized)),
            icon: const Icon(Icons.flag_outlined),
            label: Text(l.numberReport),
          ),
        ],
      ),
    );
  }
}
