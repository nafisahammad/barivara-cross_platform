import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/enums.dart';
import '../../models/flat.dart';
import '../../models/issue.dart';
import '../../models/payment.dart';
import '../../services/building_service.dart';
import '../../services/issue_service.dart';
import '../../services/payment_service.dart';
import '../../services/resident_service.dart';

class UnitConsoleScreen extends StatefulWidget {
  const UnitConsoleScreen({super.key, required this.flat});

  final Flat flat;

  @override
  State<UnitConsoleScreen> createState() => _UnitConsoleScreenState();
}

class _UnitConsoleScreenState extends State<UnitConsoleScreen> {
  late Flat _flat;
  int _refreshToken = 0;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _flat = widget.flat;
  }

  Future<FlatResident?> _loadResident() {
    return ResidentService.instance.getApprovedResidentForFlat(_flat.id);
  }

  Future<List<Payment>> _loadLedger() {
    return PaymentService.instance.getPaymentsForFlat(_flat.id);
  }

  Future<void> _openSettingsMenu() async {
    final selected = await showModalBottomSheet<_UnitSettingAction>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Edit unit details'),
                subtitle: const Text('Flat number and monthly rent'),
                onTap: () => Navigator.of(context).pop(_UnitSettingAction.edit),
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Decommission unit'),
                subtitle: const Text('Permanently delete this unit record'),
                onTap: () =>
                    Navigator.of(context).pop(_UnitSettingAction.delete),
              ),
            ],
          ),
        );
      },
    );

    if (selected == _UnitSettingAction.edit) {
      await _editUnitDetails();
      return;
    }
    if (selected == _UnitSettingAction.delete) {
      await _decommissionUnit();
    }
  }

  Future<void> _editUnitDetails() async {
    final numberController = TextEditingController(text: _flat.flatNumber);
    final rentController = TextEditingController(
      text: _flat.rentAmount.toStringAsFixed(0),
    );

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Update unit'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: numberController,
                decoration: const InputDecoration(labelText: 'Flat number'),
              ),
              TextField(
                controller: rentController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Monthly rent'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (shouldSave != true) return;

    final nextNumber = numberController.text.trim();
    final nextRent = double.tryParse(rentController.text.trim());

    if (nextNumber.isEmpty || nextRent == null || nextRent < 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a valid unit number and rent amount.'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await BuildingService.instance.updateFlat(
        flatId: _flat.id,
        flatNumber: nextNumber,
        rentAmount: nextRent,
      );
      if (!mounted) return;
      setState(() {
        _flat = Flat(
          id: _flat.id,
          buildingId: _flat.buildingId,
          flatNumber: nextNumber,
          floor: _flat.floor,
          rentAmount: nextRent,
          status: _flat.status,
        );
        _refreshToken++;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Unit details updated.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _decommissionUnit() async {
    final resident = await _loadResident();
    if (!mounted) return;
    if (resident != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Evict resident before deleting this unit.'),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete unit permanently?'),
          content: Text(
            'This will permanently remove unit ${_flat.flatNumber} from assets.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() => _isSaving = true);
    try {
      await BuildingService.instance.deleteFlat(_flat.id);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _evictAndRelease(FlatResident resident) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Evict resident and release unit?'),
          content: Text(
            '${resident.user.name} will lose access and this unit will be marked Vacant.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Evict'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() => _isSaving = true);
    try {
      await ResidentService.instance.evictAndReleaseUnit(flatId: _flat.id);
      if (!mounted) return;
      setState(() {
        _flat = Flat(
          id: _flat.id,
          buildingId: _flat.buildingId,
          flatNumber: _flat.flatNumber,
          floor: _flat.floor,
          rentAmount: _flat.rentAmount,
          status: FlatStatus.vacant,
        );
        _refreshToken++;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Unit released as vacant.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _callResident(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    final launched = await launchUrl(uri);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open dialer on this device.')),
      );
    }
  }

  Future<void> _nudgeResident(String phone) async {
    final message = Uri.encodeComponent(
      'Hello from building management for unit ${_flat.flatNumber}.',
    );
    final uri = Uri.parse('https://wa.me/$phone?text=$message');
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Unable to open WhatsApp.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Unit ${_flat.flatNumber}'),
          actions: [
            IconButton(
              onPressed: _isSaving ? null : _openSettingsMenu,
              icon: const Icon(Icons.settings_outlined),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Resident'),
              Tab(text: 'Ledger'),
              Tab(text: 'Maintenance'),
            ],
          ),
        ),
        body: Stack(
          children: [
            TabBarView(
              children: [
                _ResidentTab(
                  key: ValueKey('resident_$_refreshToken'),
                  flat: _flat,
                  loadResident: _loadResident,
                  onEvict: _evictAndRelease,
                  onCall: _callResident,
                  onNudge: _nudgeResident,
                ),
                _LedgerTab(
                  key: ValueKey('ledger_$_refreshToken'),
                  loadLedger: _loadLedger,
                ),
                _MaintenanceTab(
                  key: ValueKey('maintenance_$_refreshToken'),
                  flatId: _flat.id,
                  loadResident: _loadResident,
                ),
              ],
            ),
            if (_isSaving)
              const ColoredBox(
                color: Color(0x66000000),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}

class _ResidentTab extends StatelessWidget {
  const _ResidentTab({
    super.key,
    required this.flat,
    required this.loadResident,
    required this.onEvict,
    required this.onCall,
    required this.onNudge,
  });

  final Flat flat;
  final Future<FlatResident?> Function() loadResident;
  final Future<void> Function(FlatResident resident) onEvict;
  final Future<void> Function(String phone) onCall;
  final Future<void> Function(String phone) onNudge;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<FlatResident?>(
      future: loadResident(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final resident = snapshot.data;
        final phone = resident == null
            ? null
            : _extractPhone(resident.user.email);

        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            _DataCard(
              title: 'Unit status',
              subtitle: flat.status == FlatStatus.occupied
                  ? 'Occupied'
                  : 'Vacant',
            ),
            const SizedBox(height: 12),
            if (resident == null)
              const _DataCard(
                title: 'No active resident',
                subtitle: 'This unit is currently vacant.',
              )
            else
              _DataCard(
                title: resident.user.name,
                subtitle: resident.user.email,
              ),
            const SizedBox(height: 16),
            const Text(
              'Quick Actions',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: phone == null ? null : () => onCall(phone),
                    icon: const Icon(Icons.call_outlined),
                    label: const Text('Call'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: phone == null ? null : () => onNudge(phone),
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: const Text('Nudge'),
                  ),
                ),
              ],
            ),
            if (resident != null && phone == null)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Contact number not found in profile.',
                  style: TextStyle(color: Colors.black54),
                ),
              ),
            const SizedBox(height: 20),
            const Text(
              'Offboarding',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: resident == null ? null : () => onEvict(resident),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              icon: const Icon(Icons.logout_outlined),
              label: const Text('Evict & Release Unit'),
            ),
          ],
        );
      },
    );
  }

  String? _extractPhone(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 10) return null;
    return digits;
  }
}

class _LedgerTab extends StatelessWidget {
  const _LedgerTab({super.key, required this.loadLedger});

  final Future<List<Payment>> Function() loadLedger;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Payment>>(
      future: loadLedger(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final entries = snapshot.data ?? const <Payment>[];
        if (entries.isEmpty) {
          return const Center(
            child: Text('No rent or utility entries for this unit yet.'),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(24),
          itemBuilder: (context, index) {
            final item = entries[index];
            final date = item.paidAt ?? item.dueDate;
            final dateLabel = date == null
                ? 'No date'
                : '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _labelFromCategory(item.category),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_currency(item.amount)} | $dateLabel',
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                  _StatusChip(status: item.status),
                ],
              ),
            );
          },
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemCount: entries.length,
        );
      },
    );
  }

  String _labelFromCategory(PaymentCategory category) {
    switch (category) {
      case PaymentCategory.rent:
        return 'Rent';
      case PaymentCategory.electricity:
        return 'Electricity';
      case PaymentCategory.water:
        return 'Water';
      case PaymentCategory.gas:
        return 'Gas';
      case PaymentCategory.other:
        return 'Other';
    }
  }
}

class _MaintenanceTab extends StatelessWidget {
  const _MaintenanceTab({
    super.key,
    required this.flatId,
    required this.loadResident,
  });

  final String flatId;
  final Future<FlatResident?> Function() loadResident;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<FlatResident?>(
      future: loadResident(),
      builder: (context, residentSnapshot) {
        if (residentSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final residentId = residentSnapshot.data?.user.id;
        if (residentId == null) {
          return const Center(
            child: Text('No active resident in this unit to track tickets.'),
          );
        }

        return StreamBuilder<List<Issue>>(
          stream: IssueService.instance.streamIssuesForFlat(flatId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final issues = (snapshot.data ?? const <Issue>[])
                .where((issue) => issue.residentId == residentId)
                .toList();
            if (issues.isEmpty) {
              return const Center(
                child: Text('No maintenance tickets for this resident.'),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(24),
              itemBuilder: (context, index) {
                final issue = issues[index];
                final date = issue.createdAt;
                final dateLabel = date == null
                    ? 'No date'
                    : '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        issue.category,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      Text(issue.description),
                      const SizedBox(height: 8),
                      Text(
                        'Priority: ${issue.priority.name} | Status: ${issue.status.name} | $dateLabel',
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                );
              },
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemCount: issues.length,
            );
          },
        );
      },
    );
  }
}

class _DataCard extends StatelessWidget {
  const _DataCard({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final PaymentStatus status;

  @override
  Widget build(BuildContext context) {
    late final Color background;
    late final String label;

    switch (status) {
      case PaymentStatus.confirmed:
        background = const Color(0xFFDCFCE7);
        label = 'Confirmed';
        break;
      case PaymentStatus.pendingApproval:
        background = const Color(0xFFE0E7FF);
        label = 'Pending';
        break;
      case PaymentStatus.due:
        background = const Color(0xFFFEE2E2);
        label = 'Due';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label),
    );
  }
}

String _currency(double value) => 'Rs ${value.toStringAsFixed(0)}';

enum _UnitSettingAction { edit, delete }
