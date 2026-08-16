import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Aide & contact')),
      body: ListView(
        children: [
          // FAQ section
          const _SectionHeader(title: 'Questions frequentes'),
          ExpansionTile(
            leading: const Icon(Icons.shopping_cart_outlined),
            title: const Text('Comment ajouter un article au panier ?'),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(56, 0, 16, 16),
                child: Text(
                  'Appuyez sur l\'icone panier sur la carte du produit, '
                  'ou ouvrez la fiche produit et cliquez sur "Ajouter au panier".',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
            ],
          ),
          ExpansionTile(
            leading: const Icon(Icons.favorite_outline),
            title: const Text('Comment ajouter un favori ?'),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(56, 0, 16, 16),
                child: Text(
                  'Appuyez sur l\'icone coeur sur la carte du produit ou '
                  'dans la fiche produit. Vos favoris sont sauvegardes localement.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
            ],
          ),
          ExpansionTile(
            leading: const Icon(Icons.star_outline),
            title: const Text('Comment noter un produit ?'),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(56, 0, 16, 16),
                child: Text(
                  'Ouvrez la fiche du produit et utilisez les etoiles '
                  'dans la section "Votre note". Votre note est sauvegardee.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
            ],
          ),
          ExpansionTile(
            leading: const Icon(Icons.search),
            title: const Text('Comment rechercher un produit ?'),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(56, 0, 16, 16),
                child: Text(
                  'Utilisez la barre de recherche en haut de la page Boutique. '
                  'Vous pouvez aussi filtrer par categorie et trier par prix ou note.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
            ],
          ),
          const Divider(),
          // Contact section
          const _SectionHeader(title: 'Nous contacter'),
          const _ContactForm(),
        ],
      ),
    );
  }
}

class _ContactForm extends StatefulWidget {
  const _ContactForm();

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
    if (_submitted) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.check_circle_outline,
                size: 64, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              'Message envoye !',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Nous vous repondrons dans les plus brefs delais.',
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
              decoration: const InputDecoration(
                labelText: 'Nom',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Veuillez saisir votre nom' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailCtrl,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Veuillez saisir votre email';
                if (!v.contains('@')) return 'Email invalide';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _messageCtrl,
              decoration: const InputDecoration(
                labelText: 'Message',
                prefixIcon: Icon(Icons.message_outlined),
                alignLabelWithHint: true,
              ),
              maxLines: 4,
              validator: (v) => v == null || v.isEmpty
                  ? 'Veuillez saisir votre message'
                  : null,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  setState(() => _submitted = true);
                }
              },
              icon: const Icon(Icons.send),
              label: const Text('Envoyer'),
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
