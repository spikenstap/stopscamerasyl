import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../core/widgets/common.dart';
import '../../models/scan_history_item.dart';
import '../scanner/qr_screen.dart';
import '../numbers/number_widgets.dart';
import '../../services/call_bridge.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key, required this.item});
  final ScanHistoryItem item;
  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final a = item.analysis;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.result),
        leading: IconButton(
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/history'),
        ),
      ),
      body: PageBody(
        children: [
          if (a.details['number'] is String)
            PersonalNumberActions(phone: a.details['number'] as String),
          Text(switch (item.type) {
            'url' => l.checkLink,
            'phone' => l.checkPhone,
            'qr' => l.checkQr,
            'incomingCall' => l.incomingCall,
            _ => l.checkMessage,
          }),
          const SizedBox(height: 12),
          if (item.isMock) ...[
            Notice('${l.mockBanner}\n${l.mockDetail}', warning: true),
            const SizedBox(height: 20),
          ],
          AppCard(
            child: Column(
              children: [
                Text(
                  l.riskScore,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 20),
                if (a.riskScore == null)
                  const Padding(
                    padding: EdgeInsets.all(30),
                    child: Icon(Icons.help_outline, size: 70),
                  )
                else
                  Semantics(
                    label:
                        '${l.riskScore}: ${a.riskScore}/100, ${riskLabel(l, a.riskScore)}',
                    child: ExcludeSemantics(
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: a.riskScore!.toDouble()),
                        duration: const Duration(milliseconds: 850),
                        builder: (context, value, _) => SizedBox(
                          width: 176,
                          height: 176,
                          child: CustomPaint(
                            painter: _RiskPainter(
                              value,
                              AppColors.risk(a.riskScore),
                              Theme.of(context).dividerColor,
                            ),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${value.round()}',
                                    style: const TextStyle(
                                      fontSize: 48,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const Text(
                                    '/ 100',
                                    style: TextStyle(fontSize: 15),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                RiskBadge(a.riskScore),
                const SizedBox(height: 14),
                Text(
                  categoryLabel(l, a.category),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  a.summary,
                  textAlign: TextAlign.center,
                  style: const TextStyle(height: 1.6),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            a.origin == 'local'
                ? l.localAssessment
                : a.origin == 'legacy'
                ? l.legacyAssessment
                : item.isMock
                ? l.mockBanner
                : l.aiAssessment,
          ),
          if (a.confidence != null) ...[
            const SizedBox(height: 12),
            Text('${l.confidence}: ${(a.confidence! * 100).round()}%'),
            Text(l.confidenceNote),
            if (a.confidence! < .5) Notice(l.lowConfidence, warning: true),
          ],
          if (a.details['number'] != null) ...[
            const SizedBox(height: 16),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText(a.details['number'] as String),
                  if (a.details['country'] != null)
                    Text('${l.countryCode}: ${a.details['country']}'),
                  if (a.details['reputation'] case final Map rep) ...[
                    Text(switch (rep['status']) {
                      'flagged' => l.repFlagged,
                      'clear' => l.repClear,
                      _ => l.repUnknown,
                    }),
                    if (rep['source'] is String &&
                        (rep['source'] as String).isNotEmpty)
                      Text(rep['source'] as String),
                    if (rep['reason'] == 'not_configured' ||
                        rep['reason'] == 'configuration')
                      Text(l.repNotConfigured),
                    if (rep['reason'] == 'unavailable') Text(l.repUnavailable),
                    Text(
                      '${l.knownSignals}: ${rep['status'] == 'flagged' ? 1 : 0}',
                    ),
                  ],
                ],
              ),
            ),
          ],
          if (a.details['qrType'] case final String qrType) ...[
            const SizedBox(height: 16),
            Text(qrTypeLabel(context, qrType)),
            if (a.details['recipient'] != null)
              Text('${l.recipient}: ${a.details['recipient']}'),
            if (a.details['amount'] != null)
              Text('${l.amount}: ${a.details['amount']}'),
          ],
          const SizedBox(height: 16),
          if (a.details['url'] case final String url) ...[
            OutlinedButton.icon(
              icon: const Icon(Icons.open_in_new),
              label: Text(l.openLink),
              onPressed: () async {
                if ((a.riskScore ?? 100) > 60 || (a.confidence ?? 0) < .5) {
                  final yes = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(l.openLink),
                      content: Text(l.openLinkWarning),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(l.cancel),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: Text(l.openLink),
                        ),
                      ],
                    ),
                  );
                  if (yes != true) return;
                }
                if (!context.mounted) return;
                try {
                  await const CallBridge().invoke<void>('openUrl', {
                    'url': url,
                  });
                } on Object {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text(l.errorUnknown)));
                  }
                }
              },
            ),
            const SizedBox(height: 16),
          ],
          if (item.language !=
              Localizations.localeOf(context).languageCode) ...[
            Notice(l.savedLanguage),
            const SizedBox(height: 16),
          ],
          _Explanation(
            title: l.reasons,
            lines: a.reasons,
            icon: Icons.warning_amber,
            color: AppColors.warning,
          ),
          const SizedBox(height: 16),
          _Explanation(
            title: l.recommendations,
            lines: a.recommendations,
            icon: Icons.check_circle_outline,
            color: AppColors.success,
          ),
          const SizedBox(height: 16),
          Card(
            child: ExpansionTile(
              title: Text(l.sourceText),
              childrenPadding: const EdgeInsets.all(18),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: SelectableText(item.source),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Notice(l.disclaimer),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () => context.go('/scan'),
            child: Text(l.scanAgain),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () async {
              try {
                await Clipboard.setData(
                  ClipboardData(
                    text: [
                      l.appName,
                      if (item.isMock) l.mockBanner,
                      '${a.riskScore == null ? '—' : '${a.riskScore}/100'} — ${riskLabel(l, a.riskScore)}',
                      categoryLabel(l, a.category),
                      a.summary,
                      l.reasons,
                      ...a.reasons,
                      l.recommendations,
                      ...a.recommendations,
                      l.disclaimer,
                    ].join('\n'),
                  ),
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(l.copied)));
                }
              } on Object {
                if (context.mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(l.errorUnknown)));
                }
              }
            },
            icon: const Icon(Icons.copy_outlined),
            label: Text(l.copyResult),
          ),
          TextButton(
            onPressed: () => context.go('/home'),
            child: Text(l.goHome),
          ),
        ],
      ),
    );
  }
}

class _Explanation extends StatelessWidget {
  const _Explanation({
    required this.title,
    required this.lines,
    required this.icon,
    required this.color,
  });
  final String title;
  final List<String> lines;
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        for (final line in lines)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(line, style: const TextStyle(height: 1.5)),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}

class _RiskPainter extends CustomPainter {
  _RiskPainter(this.score, this.color, this.track);
  final double score;
  final Color color, track;
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      rect.deflate(8),
      -math.pi / 2,
      2 * math.pi,
      false,
      paint..color = track,
    );
    canvas.drawArc(
      rect.deflate(8),
      -math.pi / 2,
      2 * math.pi * score / 100,
      false,
      paint..color = color,
    );
  }

  @override
  bool shouldRepaint(_RiskPainter old) =>
      old.score != score || old.color != color || old.track != track;
}
