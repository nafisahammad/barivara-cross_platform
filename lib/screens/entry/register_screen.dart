import 'package:flutter/material.dart';
import '../../routes.dart';
import '../../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _loading = false;
  bool _codeSent = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    _nameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    setState(() => _loading = true);
    try {
      final phone = _phoneController.text.trim();
      if (phone.isEmpty) {
        throw StateError('Please enter your phone number.');
      }
      final existing = await AuthService.instance.findUserByPhone(phone);
      if (existing != null) {
        throw StateError('An account already exists for this phone number. Please log in.');
      }
      await AuthService.instance.startPhoneSignIn(phone);
      if (!mounted) return;
      setState(() => _codeSent = true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verifyAndRegister() async {
    setState(() => _loading = true);
    try {
      final phone = _phoneController.text.trim();
      if (phone.isEmpty) {
        throw StateError('Please enter your phone number.');
      }
      final existing = await AuthService.instance.findUserByPhone(phone);
      if (existing != null) {
        throw StateError('An account already exists for this phone number. Please log in.');
      }
      final password = _passwordController.text;
      final confirmPassword = _confirmPasswordController.text;
      if (password.isEmpty || confirmPassword.isEmpty) {
        throw StateError('Please enter and confirm your password.');
      }
      if (password != confirmPassword) {
        throw StateError('Passwords do not match.');
      }
      await AuthService.instance.verifySmsCode(_codeController.text.trim());
      await AuthService.instance.registerProfile(
        name: _nameController.text.trim(),
        phone: phone,
        password: password,
      );
      if (!mounted) return;
      Navigator.of(context).pushNamed(AppRoutes.roleSelection);
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
      appBar: AppBar(title: const Text('Create Account')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text('Let’s set you up', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            const Text('Secure your workspace in two quick steps.'),
            const SizedBox(height: 20),
            _StepHeader(label: 'Step 1', title: 'Verify Phone'),
            const SizedBox(height: 12),
            TextField(controller: _phoneController, decoration: const InputDecoration(labelText: 'Phone Number')),
            if (_codeSent)
              TextField(controller: _codeController, decoration: const InputDecoration(labelText: 'OTP Code')),
            const SizedBox(height: 20),
            if (!_codeSent)
              FilledButton(
                onPressed: _loading ? null : _sendCode,
                child: _loading ? const CircularProgressIndicator() : const Text('Send Code'),
              )
            else ...[
              _StepHeader(label: 'Step 2', title: 'Profile Setup'),
              const SizedBox(height: 12),
              TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Full Name')),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Security Password'),
                obscureText: true,
              ),
              TextField(
                controller: _confirmPasswordController,
                decoration: const InputDecoration(labelText: 'Confirm Password'),
                obscureText: true,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _loading ? null : _verifyAndRegister,
                child: _loading ? const CircularProgressIndicator() : const Text('Continue'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.label, required this.title});

  final String label;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF0A3DFF),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(width: 12),
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      ],
    );
  }
}
