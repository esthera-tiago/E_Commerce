import 'package:flutter/material.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/l10n/app_strings.dart';

/// FAQ et aide en ligne, construite à partir des questions les plus fréquentes
/// sur l'API DummyJSON.
class HelpScreen extends StatelessWidget {
  const HelpScreen({required this.onOpenAbout, super.key});

  final VoidCallback onOpenAbout;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(strings.help)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          const _Banner(),
          const SizedBox(height: 8),
          _Faq(
            question: strings.helpQuestionConnection,
            answer: strings.helpAnswerConnection,
          ),
          _Faq(
            question: strings.helpQuestionOffline,
            answer: strings.helpAnswerOffline,
          ),
          _Faq(
            question: strings.helpQuestionAccount,
            answer: strings.helpAnswerAccount,
          ),
          _Faq(
            question: strings.helpQuestionOrder,
            answer: strings.helpAnswerOrder,
          ),
          const Divider(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.apiTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                SelectableText(
                  AppConfig.apiBaseUrl,
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: onOpenAbout,
                  icon: const Icon(Icons.info_outline),
                  label: Text(strings.about),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner();

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.support_agent, color: scheme.onPrimaryContainer, size: 30),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              strings.helpIntro,
              style: TextStyle(color: scheme.onPrimaryContainer, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _Faq extends StatelessWidget {
  const _Faq({required this.question, required this.answer});

  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ExpansionTile(
      leading: Icon(Icons.help_outline, color: scheme.primary),
      title: Text(
        question,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
      childrenPadding: const EdgeInsets.fromLTRB(56, 0, 16, 16),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            answer,
            style: TextStyle(color: scheme.onSurfaceVariant, height: 1.45),
          ),
        ),
      ],
    );
  }
}
