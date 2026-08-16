import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(loc.aideContact)),
      body: ListView(
        children: [
          _SectionHeader(title: loc.questionsFrequentes),
          ExpansionTile(
            leading: const Icon(Icons.shopping_cart_outlined),
            title: Text(loc.faqPanier),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(56, 0, 16, 16),
                child: Text(
                  loc.faqPanierRep,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
            ],
          ),
          ExpansionTile(
            leading: const Icon(Icons.favorite_outline),
            title: Text(loc.faqFavori),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(56, 0, 16, 16),
                child: Text(
                  loc.faqFavoriRep,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
            ],
          ),
          ExpansionTile(
            leading: const Icon(Icons.star_outline),
            title: Text(loc.faqNotation),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(56, 0, 16, 16),
                child: Text(
                  loc.faqNotationRep,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
            ],
          ),
          ExpansionTile(
            leading: const Icon(Icons.search),
            title: Text(loc.faqRecherche),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(56, 0, 16, 16),
                child: Text(
                  loc.faqRechercheRep,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
            ],
          ),
          const Divider(),
          _SectionHeader(title: loc.nousContacter),
          _ContactForm(),
        ],
      ),
    );
  }
}

class _ContactForm extends StatefulWidget {
  @override
  State<_ContactForm> createState() => _ContactFormState();
}

class _ContactFormState extends State<_ContactForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  bool _submitted = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    if (_submitted) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.check_circle_outline,
                size: 64, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              loc.messageEnvoye,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              loc.reponseBrefsDelais,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: loc.nom,
                prefixIcon: const Icon(Icons.person_outline),
              ),
              validator: (v) => v == null || v.isEmpty ? loc.saisirNom : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailCtrl,
              decoration: InputDecoration(
                labelText: loc.email,
                prefixIcon: const Icon(Icons.email_outlined),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.isEmpty) return loc.saisirEmail;
                if (!v.contains('@')) return loc.emailInvalide;
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _messageCtrl,
              decoration: InputDecoration(
                labelText: loc.nousContacter,
                prefixIcon: const Icon(Icons.message_outlined),
                alignLabelWithHint: true,
              ),
              maxLines: 4,
              validator: (v) => v == null || v.isEmpty ? loc.saisirMessage : null,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  setState(() => _submitted = true);
                }
              },
              icon: const Icon(Icons.send),
              label: Text(loc.envoyer),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}
