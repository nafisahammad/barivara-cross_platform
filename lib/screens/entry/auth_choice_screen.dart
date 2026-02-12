import 'package:flutter/material.dart';

import '../../models/enums.dart';
import '../../routes.dart';

class AuthChoiceScreen extends StatelessWidget {
  const AuthChoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              const Text(
                'Welcome to Barivara',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              const Text(
                'Choose your portal. Host and Resident access are separate.',
                style: TextStyle(fontSize: 16),
              ),
              const Spacer(),
              _HeroCard(
                title: 'Host Portal',
                subtitle: 'Manage units, revenue, and operations',
                icon: Icons.apartment,
                onTap: () => Navigator.of(
                  context,
                ).pushNamed(AppRoutes.login, arguments: UserRole.host),
              ),
              const SizedBox(height: 16),
              _HeroCard(
                title: 'Resident Portal',
                subtitle: 'Join your building and manage dues',
                icon: Icons.home,
                onTap: () => Navigator.of(
                  context,
                ).pushNamed(AppRoutes.login, arguments: UserRole.resident),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => Navigator.of(
                  context,
                ).pushNamed(AppRoutes.register, arguments: UserRole.host),
                child: const Text('Create Host Account'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => Navigator.of(
                  context,
                ).pushNamed(AppRoutes.register, arguments: UserRole.resident),
                child: const Text('Create Resident Account'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(32),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 18,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: const Color(0xFF0A3DFF),
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: Colors.black54)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}
