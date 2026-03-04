import 'package:flutter/material.dart';

import '../../services/settings_service.dart';

class NotificationPreferencesScreen extends StatelessWidget {
  const NotificationPreferencesScreen({super.key});

  Future<void> _update(AppSettings settings) async {
    await SettingsService.instance.update(settings);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Notification Preferences')),
      body: ValueListenableBuilder<AppSettings>(
        valueListenable: SettingsService.instance.notifier,
        builder: (context, settings, _) {
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Text(
                'Alert Types',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              _PreferenceTile(
                title: 'Tickets & Service',
                subtitle: 'Updates about service requests',
                value: settings.notifyTickets,
                onChanged: (value) => _update(
                  settings.copyWith(notifyTickets: value),
                ),
              ),
              _PreferenceTile(
                title: 'Payment Reminders',
                subtitle: 'Due dates and confirmations',
                value: settings.notifyPayments,
                onChanged: (value) => _update(
                  settings.copyWith(notifyPayments: value),
                ),
              ),
              _PreferenceTile(
                title: 'Community Announcements',
                subtitle: 'Notices and community updates',
                value: settings.notifyAnnouncements,
                onChanged: (value) => _update(
                  settings.copyWith(notifyAnnouncements: value),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Delivery Channels',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              _PreferenceTile(
                title: 'Push Notifications',
                subtitle: 'Instant alerts on your device',
                value: settings.channelPush,
                onChanged: (value) => _update(
                  settings.copyWith(channelPush: value),
                ),
              ),
              _PreferenceTile(
                title: 'Email Summaries',
                subtitle: 'Daily or weekly summaries',
                value: settings.channelEmail,
                onChanged: (value) => _update(
                  settings.copyWith(channelEmail: value),
                ),
              ),
              _PreferenceTile(
                title: 'SMS Alerts',
                subtitle: 'Critical updates by text',
                value: settings.channelSms,
                onChanged: (value) => _update(
                  settings.copyWith(channelSms: value),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Changes are saved automatically.',
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PreferenceTile extends StatelessWidget {
  const _PreferenceTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: scheme.surface,
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
    );
  }
}
