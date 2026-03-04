import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/enums.dart';
import '../../models/issue.dart';
import '../../models/payment.dart';
import '../../routes.dart';
import '../../services/auth_service.dart';
import '../../services/building_service.dart';
import '../../services/issue_service.dart';
import '../../services/payment_service.dart';
import '../../services/resident_service.dart';

class DataExportScreen extends StatelessWidget {
  const DataExportScreen({super.key});

  Future<_ExportContext?> _loadContext() async {
    final profile = await AuthService.instance.getCurrentProfile();
    if (profile == null) return null;
    if (profile.role == UserRole.host) {
      final building = await BuildingService.instance.getBuildingForHost(
        profile.id,
      );
      return _ExportContext(
        role: profile.role,
        buildingId: building?.id,
        residentId: profile.id,
      );
    }
    final link = await ResidentService.instance.getLinkForUser(profile.id);
    return _ExportContext(
      role: profile.role,
      buildingId: link?.buildingId,
      flatId: link?.flatId,
      residentId: profile.id,
    );
  }

  Future<void> _copyCsv(
    BuildContext context,
    String label,
    String csv,
  ) async {
    await Clipboard.setData(ClipboardData(text: csv));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label copied to clipboard.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Data Export')),
      body: FutureBuilder<_ExportContext?>(
        future: _loadContext(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final exportContext = snapshot.data;
          if (exportContext == null) {
            return const Center(child: Text('Unable to load export data.'));
          }
          if (exportContext.role == UserRole.host &&
              exportContext.buildingId == null) {
            return const Center(child: Text('No building linked yet.'));
          }
          if (exportContext.role == UserRole.resident &&
              exportContext.flatId == null) {
            return const Center(child: Text('No unit linked yet.'));
          }

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _SectionHeader(
                title: exportContext.role == UserRole.host
                    ? 'Building Reports'
                    : 'My Reports',
                subtitle:
                    'Export tickets and payments as CSV for external reports.',
              ),
              const SizedBox(height: 16),
              StreamBuilder<List<Issue>>(
                stream: exportContext.role == UserRole.host
                    ? IssueService.instance.streamIssuesForBuilding(
                        exportContext.buildingId!,
                      )
                    : IssueService.instance.streamIssuesForResident(
                        exportContext.residentId,
                      ),
                builder: (context, issueSnapshot) {
                  final issues = issueSnapshot.data ?? const <Issue>[];
                  return _ExportCard(
                    title: 'Service Tickets',
                    subtitle:
                        '${issues.length} tickets available for export',
                    primaryActionLabel: 'Copy CSV',
                    onPrimaryAction: issues.isEmpty
                        ? null
                        : () => _copyCsv(
                              context,
                              'Ticket export',
                              _issuesToCsv(issues),
                            ),
                  );
                },
              ),
              FutureBuilder<List<Payment>>(
                future: exportContext.role == UserRole.host
                    ? PaymentService.instance.getPaymentsForBuilding(
                        exportContext.buildingId!,
                      )
                    : PaymentService.instance.getPaymentsForFlat(
                        exportContext.flatId!,
                      ),
                builder: (context, paymentSnapshot) {
                  if (paymentSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const _LoadingCard(title: 'Payments');
                  }
                  final payments = paymentSnapshot.data ?? const <Payment>[];
                  return _ExportCard(
                    title: 'Payments',
                    subtitle:
                        '${payments.length} payments available for export',
                    primaryActionLabel: 'Copy CSV',
                    onPrimaryAction: payments.isEmpty
                        ? null
                        : () => _copyCsv(
                              context,
                              'Payment export',
                              _paymentsToCsv(payments),
                            ),
                  );
                },
              ),
              const SizedBox(height: 20),
              _ExportCard(
                title: 'Privacy Notice',
                subtitle:
                    'Exports include personal data. Share them only with authorized staff.',
                primaryActionLabel: 'Review privacy settings',
                onPrimaryAction: () => Navigator.of(context).pushNamed(
                  AppRoutes.privacySecurity,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ExportContext {
  final UserRole role;
  final String? buildingId;
  final String? flatId;
  final String residentId;

  const _ExportContext({
    required this.role,
    required this.buildingId,
    required this.residentId,
    this.flatId,
  });
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        Text(subtitle, style: TextStyle(color: scheme.onSurfaceVariant)),
      ],
    );
  }
}

class _ExportCard extends StatelessWidget {
  const _ExportCard({
    required this.title,
    required this.subtitle,
    required this.primaryActionLabel,
    this.onPrimaryAction,
  });

  final String title;
  final String subtitle;
  final String primaryActionLabel;
  final VoidCallback? onPrimaryAction;

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
          const SizedBox(height: 12),
          FilledButton(
            onPressed: onPrimaryAction,
            child: Text(primaryActionLabel),
          ),
        ],
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard({required this.title});

  final String title;

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
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

String _issuesToCsv(List<Issue> issues) {
  final buffer = StringBuffer();
  buffer.writeln(
    'id,category,status,priority,flatId,residentId,createdAt,updatedAt',
  );
  for (final issue in issues) {
    buffer.writeln(
      [
        issue.id,
        issue.category,
        issue.status.name,
        issue.priority.name,
        issue.flatId,
        issue.residentId,
        _formatDate(issue.createdAt),
        _formatDate(issue.updatedAt),
      ].map(_csvEscape).join(','),
    );
  }
  return buffer.toString();
}

String _paymentsToCsv(List<Payment> payments) {
  final buffer = StringBuffer();
  buffer.writeln(
    'id,category,status,amount,flatId,residentId,dueDate,paidAt',
  );
  for (final payment in payments) {
    buffer.writeln(
      [
        payment.id,
        payment.category.name,
        payment.status.name,
        payment.amount.toStringAsFixed(2),
        payment.flatId,
        payment.residentId,
        _formatDate(payment.dueDate),
        _formatDate(payment.paidAt),
      ].map(_csvEscape).join(','),
    );
  }
  return buffer.toString();
}

String _formatDate(DateTime? value) {
  if (value == null) return '';
  return value.toIso8601String();
}

String _csvEscape(String value) {
  final escaped = value.replaceAll('"', '""');
  if (escaped.contains(',') || escaped.contains('\n')) {
    return '"$escaped"';
  }
  return escaped;
}
