import 'package:flutter/material.dart';
import '../../routes.dart';
import '../../models/enums.dart';
import '../../services/auth_service.dart';
import '../../services/building_service.dart';
import '../../services/resident_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;

    final profile = await AuthService.instance.getCurrentProfile();
    if (!mounted) return;

    if (profile == null) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.authChoice);
      return;
    }

    if (profile.role == UserRole.host) {
      if (profile.buildingId != null && profile.buildingId!.isNotEmpty) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.hostDashboard);
        return;
      }
      final building = await BuildingService.instance.getBuildingForHost(profile.id);
      if (!mounted) return;
      if (building == null) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.hostSetup);
      } else {
        Navigator.of(context).pushReplacementNamed(AppRoutes.hostDashboard);
      }
      return;
    }

    final link = await ResidentService.instance.getLinkForUser(profile.id);
    if (!mounted) return;
    if (link == null) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.residentJoin);
      return;
    }

    if (link.approvalStatus == ApprovalStatus.pending) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.awaitingAccess);
    } else {
      Navigator.of(context).pushReplacementNamed(AppRoutes.residentDashboard);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0A3DFF), Color(0xFF021A8C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.92, end: 1.04).animate(
              CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(48),
              ),
              child: const Text(
                'Barivara',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
