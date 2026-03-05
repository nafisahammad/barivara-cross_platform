import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  Future<void> _copy(BuildContext context, String label, String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label copied to clipboard.')),
    );
  }

  Future<void> _launch(BuildContext context, Uri uri) async {
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      return;
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Unable to open this link.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    const phone = '+8801700000000';
    const email = 'support@barivara.app';

    return Scaffold(
      appBar: AppBar(title: const Text('Support')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Contact',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          _ContactCard(
            title: 'Support Hotline',
            subtitle: phone,
            trailing: Wrap(
              spacing: 8,
              children: [
                IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () => _copy(context, 'Phone', phone),
                ),
                IconButton(
                  icon: const Icon(Icons.phone),
                  onPressed: () => _launch(context, Uri.parse('tel:$phone')),
                ),
              ],
            ),
          ),
          _ContactCard(
            title: 'Email Support',
            subtitle: email,
            trailing: Wrap(
              spacing: 8,
              children: [
                IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () => _copy(context, 'Email', email),
                ),
                IconButton(
                  icon: const Icon(Icons.email_outlined),
                  onPressed: () =>
                      _launch(context, Uri.parse('mailto:$email')),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Help Center',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          _ContactCard(
            title: 'Open Help Articles',
            subtitle: 'Guides for payments, tickets, and account setup',
            trailing: IconButton(
              icon: const Icon(Icons.open_in_new),
              onPressed: () => _launch(
                context,
                Uri.parse('https://barivara.app/help'),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'FAQs',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          const _FaqTile(
            question: 'How do I submit a service ticket?',
            answer:
                'Go to Service, tap New Ticket, and describe the issue with any attachments.',
          ),
          const _FaqTile(
            question: 'When are payment reminders sent?',
            answer:
                'Reminders are sent when a bill is created and 3 days before the due date.',
          ),
          const _FaqTile(
            question: 'How do I change my profile details?',
            answer:
                'Open Settings, then Profile Details to update your name or phone.',
          ),
        ],
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget? trailing;

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(color: scheme.onSurfaceVariant)),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  const _FaqTile({required this.question, required this.answer});

  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: scheme.surface,
      ),
      child: ExpansionTile(
        title: Text(question, style: const TextStyle(fontWeight: FontWeight.w700)),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [Text(answer, style: TextStyle(color: scheme.onSurfaceVariant))],
      ),
    );
  }
}
