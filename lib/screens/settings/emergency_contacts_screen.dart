import 'package:flutter/material.dart';

import '../../services/settings_service.dart';

class EmergencyContactsScreen extends StatelessWidget {
  const EmergencyContactsScreen({super.key});

  Future<void> _save(AppSettings settings, List<EmergencyContact> contacts) {
    return SettingsService.instance.update(
      settings.copyWith(emergencyContacts: contacts),
    );
  }

  Future<EmergencyContact?> _editContact(
    BuildContext context, {
    EmergencyContact? contact,
  }) async {
    final nameController = TextEditingController(text: contact?.name ?? '');
    final relationshipController = TextEditingController(
      text: contact?.relationship ?? '',
    );
    final phoneController = TextEditingController(text: contact?.phone ?? '');
    final notesController = TextEditingController(text: contact?.notes ?? '');

    return showDialog<EmergencyContact>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(contact == null ? 'Add contact' : 'Edit contact'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: relationshipController,
                  decoration: const InputDecoration(labelText: 'Relationship'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Phone number'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(labelText: 'Notes (optional)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final name = nameController.text.trim();
                final relationship = relationshipController.text.trim();
                final phone = phoneController.text.trim();
                if (name.isEmpty || phone.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Name and phone are required.')),
                  );
                  return;
                }
                Navigator.of(dialogContext).pop(
                  EmergencyContact(
                    name: name,
                    relationship: relationship.isEmpty ? 'Contact' : relationship,
                    phone: phone,
                    notes: notesController.text.trim(),
                  ),
                );
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Emergency Contacts')),
      body: ValueListenableBuilder<AppSettings>(
        valueListenable: SettingsService.instance.notifier,
        builder: (context, settings, _) {
          final contacts = settings.emergencyContacts;
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Text(
                'Emergency Contacts',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              if (contacts.isEmpty)
                const _EmptyState()
              else
                ...contacts.map(
                  (contact) => _ContactCard(
                    contact: contact,
                    onEdit: () async {
                      final updated = await _editContact(
                        context,
                        contact: contact,
                      );
                      if (updated == null) return;
                      final next = contacts
                          .map((item) => item == contact ? updated : item)
                          .toList();
                      await _save(settings, next);
                    },
                    onDelete: () async {
                      final next = contacts
                          .where((item) => item != contact)
                          .toList();
                      await _save(settings, next);
                    },
                  ),
                ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () async {
                  final created = await _editContact(context);
                  if (created == null) return;
                  await _save(settings, [...contacts, created]);
                },
                icon: const Icon(Icons.add),
                label: const Text('Add contact'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: scheme.surfaceVariant,
      ),
      child: Text(
        'Add a contact so emergency services can reach the right person quickly.',
        style: TextStyle(color: scheme.onSurfaceVariant),
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({
    required this.contact,
    required this.onEdit,
    required this.onDelete,
  });

  final EmergencyContact contact;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

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
          Row(
            children: [
              Expanded(
                child: Text(
                  contact.name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: onEdit,
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: onDelete,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(contact.relationship),
          const SizedBox(height: 4),
          Text(contact.phone, style: TextStyle(color: scheme.onSurfaceVariant)),
          if (contact.notes.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(contact.notes, style: TextStyle(color: scheme.onSurfaceVariant)),
          ],
        ],
      ),
    );
  }
}
