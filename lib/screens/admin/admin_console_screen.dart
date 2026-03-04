import 'package:flutter/material.dart';

class AdminConsoleScreen extends StatelessWidget {
  const AdminConsoleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Console')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Raw JSON Editor', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: scheme.surfaceVariant,
                ),
                child: TextField(
                  maxLines: null,
                  expands: true,
                  style: TextStyle(color: scheme.onSurface),
                  decoration: InputDecoration(
                    hintText: '{\n  "collection": "users",\n  "id": "..."\n}',
                    hintStyle: TextStyle(color: scheme.onSurfaceVariant),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {},
              child: const Text('Apply Changes'),
            ),
          ],
        ),
      ),
    );
  }
}
