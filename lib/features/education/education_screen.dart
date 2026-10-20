import 'package:flutter/material.dart';

import '../../core/widgets/common.dart';

class EducationScreen extends StatelessWidget {
  const EducationScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final articles = [
      (l.article1, l.body1, Icons.phishing),
      (l.article2, l.body2, Icons.sms_outlined),
      (l.article3, l.body3, Icons.link),
      (l.article4, l.body4, Icons.account_balance_outlined),
      (l.article5, l.body5, Icons.chat_outlined),
      (l.article6, l.body6, Icons.trending_up),
      (l.article7, l.body7, Icons.lock_outline),
    ];
    return PageBody(
      children: [
        PageHeading(l.educationTitle, l.educationSubtitle),
        Notice('${l.dailyTip}\n${l.tipBody}'),
        const SizedBox(height: 24),
        for (final article in articles)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Card(
              child: ExpansionTile(
                leading: Icon(article.$3),
                title: Text(article.$1),
                expandedCrossAxisAlignment: CrossAxisAlignment.start,
                childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                children: [
                  Text(article.$2, style: const TextStyle(height: 1.65)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
