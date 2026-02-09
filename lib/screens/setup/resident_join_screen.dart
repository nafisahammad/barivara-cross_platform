import 'package:flutter/material.dart';
import '../../routes.dart';
import '../../services/auth_service.dart';
import '../../services/building_service.dart';
import '../../services/resident_service.dart';
import '../../models/building.dart';
import '../../models/flat.dart';

class ResidentJoinScreen extends StatefulWidget {
  const ResidentJoinScreen({super.key});

  @override
  State<ResidentJoinScreen> createState() => _ResidentJoinScreenState();
}

class _ResidentJoinScreenState extends State<ResidentJoinScreen> {
  final _inviteController = TextEditingController();
  Building? _building;
  List<Flat> _flats = [];
  String? _selectedFlatId;
  bool _loading = false;

  @override
  void dispose() {
    _inviteController.dispose();
    super.dispose();
  }

  Future<void> _findBuilding() async {
    setState(() => _loading = true);
    try {
      final building = await BuildingService.instance.findBuildingByInviteCode(
        _inviteController.text.trim().toUpperCase(),
      );
      if (building == null) {
        throw StateError('No building found for that invite code.');
      }
      final flats = await BuildingService.instance.getVacantFlats(building.id);
      setState(() {
        _building = building;
        _flats = flats;
        _selectedFlatId = flats.isNotEmpty ? flats.first.id : null;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _requestAccess() async {
    if (_building == null || _selectedFlatId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a building and unit first.')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final userId = AuthService.instance.currentUserId;
      if (userId == null) {
        throw StateError('Please login or register first.');
      }
      await ResidentService.instance.requestAccess(
        userId: userId,
        buildingId: _building!.id,
        flatId: _selectedFlatId!,
      );
      if (!mounted) return;
      Navigator.of(context).pushNamed(AppRoutes.awaitingAccess);
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
      appBar: AppBar(title: const Text('Join Building')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text('Enter Invite Code', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            const Text('Confirm the building before selecting a unit.'),
            const SizedBox(height: 20),
            TextField(controller: _inviteController, decoration: const InputDecoration(labelText: 'Invite Code')),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _loading ? null : _findBuilding,
              child: _loading ? const CircularProgressIndicator() : const Text('Find Building'),
            ),
            if (_building != null) ...[
              const SizedBox(height: 24),
              Text(_building!.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              const Text('Select a vacant unit', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _flats
                    .map(
                      (flat) => ChoiceChip(
                        label: Text(flat.flatNumber),
                        selected: _selectedFlatId == flat.id,
                        labelStyle: const TextStyle(fontWeight: FontWeight.w700),
                        onSelected: (_) => setState(() => _selectedFlatId = flat.id),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _loading ? null : _requestAccess,
                child: _loading ? const CircularProgressIndicator() : const Text('Request Access'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
