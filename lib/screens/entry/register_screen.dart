import 'package:flutter/material.dart';

import '../../models/enums.dart';
import '../../routes.dart';
import '../../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _loading = false;
  UserRole? _portalRole;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _portalRole ??= ModalRoute.of(context)?.settings.arguments as UserRole?;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    setState(() => _loading = true);
    try {
      final name = _nameController.text.trim();
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      final confirmPassword = _confirmPasswordController.text;

      if (name.isEmpty) {
        throw StateError('Please enter your full name.');
      }
      if (email.isEmpty) {
        throw StateError('Please enter your email.');
      }
      if (password.isEmpty || confirmPassword.isEmpty) {
        throw StateError('Please enter and confirm your password.');
      }
      if (password != confirmPassword) {
        throw StateError('Passwords do not match.');
      }

      final role = _portalRole;
      if (role == null) {
        throw StateError('Please choose Host or Resident portal first.');
      }

      await AuthService.instance.registerProfile(
        name: name,
        email: email,
        password: password,
        role: role,
      );

      if (!mounted) return;
      final destination = role == UserRole.host
          ? AppRoutes.hostSetup
          : AppRoutes.residentJoin;
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(destination, (route) => false);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String get _portalLabel {
    return switch (_portalRole) {
      UserRole.host => 'Host',
      UserRole.resident => 'Resident',
      null => 'Account',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Create $_portalLabel Account')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Set up your $_portalLabel access',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            const Text('Use email and password to create your account.'),
            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Full Name'),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirmPasswordController,
              decoration: const InputDecoration(labelText: 'Confirm Password'),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _loading ? null : _register,
              child: _loading
                  ? const CircularProgressIndicator()
                  : const Text('Create Account'),
            ),
          ],
        ),
      ),
    );
  }
}
