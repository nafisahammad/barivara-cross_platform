import 'package:flutter/material.dart';
import '../../routes.dart';
import '../../services/auth_service.dart';
import '../../services/building_service.dart';

class HostSetupScreen extends StatefulWidget {
  const HostSetupScreen({super.key});

  @override
  State<HostSetupScreen> createState() => _HostSetupScreenState();
}

class _HostSetupScreenState extends State<HostSetupScreen> {
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _floorsController = TextEditingController(text: '1');
  final _unitsController = TextEditingController(text: '1');
  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _floorsController.dispose();
    _unitsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      final userId = AuthService.instance.currentUserId;
      if (userId == null) {
        throw StateError('Please login or register first.');
      }
      final floors = int.tryParse(_floorsController.text) ?? 1;
      final units = int.tryParse(_unitsController.text) ?? 1;
      await BuildingService.instance.createBuilding(
        hostId: userId,
        name: _nameController.text.trim(),
        address: _addressController.text.trim(),
        floors: floors,
        unitsPerFloor: units,
      ).then((building) async {
        await AuthService.instance.setBuildingId(building.id);
      });
      if (!mounted) return;
      Navigator.of(context).pushNamed(AppRoutes.hostDashboard);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Building Setup')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text('Create your building', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            const Text('We will auto-generate units from your structure.'),
            const SizedBox(height: 20),
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Building Name')),
            const SizedBox(height: 12),
            TextField(controller: _addressController, decoration: const InputDecoration(labelText: 'Address')),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: TextField(controller: _floorsController, decoration: const InputDecoration(labelText: 'Floors'))),
                const SizedBox(width: 12),
                Expanded(child: TextField(controller: _unitsController, decoration: const InputDecoration(labelText: 'Units / Floor'))),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _loading ? null : _submit,
              child: _loading ? const CircularProgressIndicator() : const Text('Generate Units'),
            ),
          ],
        ),
      ),
    );
  }
}
