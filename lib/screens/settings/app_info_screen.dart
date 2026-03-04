import 'package:flutter/material.dart';

class AppInfoScreen extends StatelessWidget {
  const AppInfoScreen({super.key});

  static const String _version = '1.0.0+1';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('App Info')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Barivara',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            'Building management made simple.',
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          _InfoTile(title: 'Version', value: _version),
          _InfoTile(title: 'Platform', value: Theme.of(context).platform.name),
          _InfoTile(title: 'Release channel', value: 'Stable'),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () {
              showLicensePage(
                context: context,
                applicationName: 'Barivara',
                applicationVersion: _version,
              );
            },
            icon: const Icon(Icons.description_outlined),
            label: const Text('Open source licenses'),
          ),
          const SizedBox(height: 20),
          const Text(
            'Legal',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          const _LegalCard(
            title: 'Terms of Service',
            subtitle:
                'By using Barivara you agree to the platform terms and payment policies.',
          ),
          const _LegalCard(
            title: 'Privacy Policy',
            subtitle:
                'We store the minimum data required to operate building services.',
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: scheme.surface,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Text(value, style: TextStyle(color: scheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _LegalCard extends StatelessWidget {
  const _LegalCard({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: scheme.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(subtitle, style: TextStyle(color: scheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}
