import 'package:flutter/material.dart';

import '../../services/settings_service.dart';

class AppAppearanceScreen extends StatelessWidget {
  const AppAppearanceScreen({super.key});

  Future<void> _update(AppSettings settings) async {
    await SettingsService.instance.update(settings);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('App Appearance')),
      body: ValueListenableBuilder<AppSettings>(
        valueListenable: SettingsService.instance.notifier,
        builder: (context, settings, _) {
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Text(
                'Theme',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              _CardGroup(
                children: [
                  _RadioTile(
                    title: 'System default',
                    subtitle: 'Match your device appearance',
                    value: ThemeMode.system,
                    groupValue: settings.themeMode,
                    onChanged: (value) => _update(
                      settings.copyWith(themeMode: value),
                    ),
                  ),
                  _RadioTile(
                    title: 'Light',
                    subtitle: 'Bright background with dark text',
                    value: ThemeMode.light,
                    groupValue: settings.themeMode,
                    onChanged: (value) => _update(
                      settings.copyWith(themeMode: value),
                    ),
                  ),
                  _RadioTile(
                    title: 'Dark',
                    subtitle: 'Dim background for low light',
                    value: ThemeMode.dark,
                    groupValue: settings.themeMode,
                    onChanged: (value) => _update(
                      settings.copyWith(themeMode: value),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Text Size',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              _CardGroup(
                children: [
                  _RadioTile<double>(
                    title: 'Small',
                    subtitle: 'More content on screen',
                    value: 0.9,
                    groupValue: settings.textScale,
                    onChanged: (value) => _update(
                      settings.copyWith(textScale: value),
                    ),
                  ),
                  _RadioTile<double>(
                    title: 'Default',
                    subtitle: 'Recommended size',
                    value: 1.0,
                    groupValue: settings.textScale,
                    onChanged: (value) => _update(
                      settings.copyWith(textScale: value),
                    ),
                  ),
                  _RadioTile<double>(
                    title: 'Large',
                    subtitle: 'Easier to read',
                    value: 1.1,
                    groupValue: settings.textScale,
                    onChanged: (value) => _update(
                      settings.copyWith(textScale: value),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Layout Density',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              _CardGroup(
                children: [
                  _RadioTile<LayoutDensity>(
                    title: 'Comfortable',
                    subtitle: 'More spacing between items',
                    value: LayoutDensity.comfortable,
                    groupValue: settings.density,
                    onChanged: (value) => _update(
                      settings.copyWith(density: value),
                    ),
                  ),
                  _RadioTile<LayoutDensity>(
                    title: 'Compact',
                    subtitle: 'Tighter layout',
                    value: LayoutDensity.compact,
                    groupValue: settings.density,
                    onChanged: (value) => _update(
                      settings.copyWith(density: value),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _PreviewTile(textScale: settings.textScale),
            ],
          );
        },
      ),
    );
  }
}

class _CardGroup extends StatelessWidget {
  const _CardGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: scheme.surface,
      ),
      child: Column(children: children),
    );
  }
}

class _RadioTile<T> extends StatelessWidget {
  const _RadioTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final T value;
  final T groupValue;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return RadioListTile<T>(
      value: value,
      groupValue: groupValue,
      onChanged: (value) {
        if (value == null) return;
        onChanged(value);
      },
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle),
    );
  }
}

class _PreviewTile extends StatelessWidget {
  const _PreviewTile({required this.textScale});

  final double textScale;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: scheme.surfaceContainerHighest,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Preview',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Text size ${textScale.toStringAsFixed(1)}x',
          ),
          const SizedBox(height: 6),
          const Text('Service update: Elevator maintenance scheduled.'),
        ],
      ),
    );
  }
}
