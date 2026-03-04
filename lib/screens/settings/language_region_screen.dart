import 'package:flutter/material.dart';

import '../../services/settings_service.dart';

class LanguageRegionScreen extends StatelessWidget {
  const LanguageRegionScreen({super.key});

  Future<void> _update(AppSettings settings) async {
    await SettingsService.instance.update(settings);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Language & Region')),
      body: ValueListenableBuilder<AppSettings>(
        valueListenable: SettingsService.instance.notifier,
        builder: (context, settings, _) {
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Text(
                'Language',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              _SelectionCard(
                child: DropdownButtonFormField<String>(
                  value: settings.language,
                  decoration: const InputDecoration(labelText: 'App language'),
                  items: const [
                    DropdownMenuItem(value: 'English', child: Text('English')),
                    DropdownMenuItem(value: 'Bangla', child: Text('Bangla')),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    _update(settings.copyWith(language: value));
                  },
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Region',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              _SelectionCard(
                child: DropdownButtonFormField<String>(
                  value: settings.currency,
                  decoration: const InputDecoration(labelText: 'Currency'),
                  items: const [
                    DropdownMenuItem(value: 'BDT', child: Text('Bangladeshi Taka (BDT)')),
                    DropdownMenuItem(value: 'USD', child: Text('US Dollar (USD)')),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    _update(settings.copyWith(currency: value));
                  },
                ),
              ),
              const SizedBox(height: 12),
              _SelectionCard(
                child: DropdownButtonFormField<String>(
                  value: settings.timeFormat,
                  decoration: const InputDecoration(labelText: 'Time format'),
                  items: const [
                    DropdownMenuItem(value: '12h', child: Text('12-hour clock')),
                    DropdownMenuItem(value: '24h', child: Text('24-hour clock')),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    _update(settings.copyWith(timeFormat: value));
                  },
                ),
              ),
              const SizedBox(height: 20),
              _PreviewCard(settings: settings),
            ],
          );
        },
      ),
    );
  }
}

class _SelectionCard extends StatelessWidget {
  const _SelectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: scheme.surface,
      ),
      child: child,
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final timeLabel = settings.timeFormat == '24h'
        ? '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}'
        : _format12h(now);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: scheme.surfaceVariant,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Preview',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text('Language: ${settings.language}'),
          Text('Currency: ${settings.currency}'),
          Text('Time: $timeLabel'),
        ],
      ),
    );
  }

  String _format12h(DateTime value) {
    final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final minute = value.minute.toString().padLeft(2, '0');
    final suffix = value.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $suffix';
  }
}
