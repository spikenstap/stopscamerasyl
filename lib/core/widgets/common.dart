import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../localization/generated/app_localizations.dart';
import '../api/api_exception.dart';

extension LocalizedContext on BuildContext {
  AppLocalizations get l => AppLocalizations.of(this)!;
}

String failureText(AppLocalizations l, Failure failure) => switch (failure) {
  Failure.network => l.errorNetwork,
  Failure.timeout => l.errorTimeout,
  Failure.auth => l.errorAuth,
  Failure.rate => l.errorRate,
  Failure.server => l.errorServer,
  Failure.json => l.errorJson,
  Failure.config => l.errorConfig,
  Failure.storage => l.errorStorage,
  Failure.unknown => l.errorUnknown,
};
String riskLabel(AppLocalizations l, int? score) => score == null
    ? l.insufficientData
    : score <= 20
    ? l.safe
    : score <= 40
    ? l.low
    : score <= 60
    ? l.medium
    : score <= 80
    ? l.high
    : l.critical;
String categoryLabel(AppLocalizations l, String c) => switch (c) {
  'phishing' => l.phishing,
  'fake_bank' => l.fakeBank,
  'social_engineering' => l.socialEngineering,
  'investment_scam' => l.investmentScam,
  'fake_delivery' => l.fakeDelivery,
  'account_theft' => l.accountTheft,
  'malicious_link' => l.maliciousLink,
  'suspicious_message' => l.suspiciousMessage,
  _ => l.unknown,
};

class PageBody extends StatelessWidget {
  const PageBody({super.key, required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ),
    ),
  );
}

class PageHeading extends StatelessWidget {
  const PageHeading(this.title, this.subtitle, {super.key});
  final String title, subtitle;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
      ],
    ),
  );
}

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });
  final Widget child;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(padding: padding, child: child),
  );
}

class IconTile extends StatelessWidget {
  const IconTile(this.icon, {super.key, this.color = AppColors.primary});
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(11),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Icon(icon, color: color, size: 24),
  );
}

class Notice extends StatelessWidget {
  const Notice(
    this.text, {
    super.key,
    this.icon = Icons.info_outline,
    this.warning = false,
  });
  final String text;
  final IconData icon;
  final bool warning;
  @override
  Widget build(BuildContext context) {
    final color = warning
        ? AppColors.warning
        : Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

class RiskBadge extends StatelessWidget {
  const RiskBadge(this.score, {super.key});
  final int? score;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: AppColors.risk(score).withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      riskLabel(context.l, score),
      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
    ),
  );
}

Future<void> guarded(
  BuildContext context,
  Future<void> Function() action,
) async {
  try {
    await action();
  } on Object {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.l.errorStorage)));
    }
  }
}
