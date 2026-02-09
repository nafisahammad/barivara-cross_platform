import 'package:flutter/material.dart';
import '../../routes.dart';
import '../../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  bool _loading = false;
  bool _codeSent = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    setState(() => _loading = true);
    try {
      await AuthService.instance.startPhoneSignIn(_phoneController.text.trim());
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

  Future<void> _verifyCode() async {
    setState(() => _loading = true);
    try {
      await AuthService.instance.verifySmsCode(_codeController.text.trim());
      await AuthService.instance.loginProfile(phone: _phoneController.text.trim());
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
      appBar: AppBar(title: const Text('Login')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text('Welcome back', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            const Text('Sign in with your phone number.'),
            const SizedBox(height: 20),
            TextField(controller: _phoneController, decoration: const InputDecoration(labelText: 'Phone Number')),
            const SizedBox(height: 12),
            if (_codeSent)
              TextField(controller: _codeController, decoration: const InputDecoration(labelText: 'OTP Code')),
            const SizedBox(height: 24),
            if (!_codeSent)
              FilledButton(
                onPressed: _loading ? null : _sendCode,
                child: _loading ? const CircularProgressIndicator() : const Text('Send Code'),
              )
            else
              FilledButton(
                onPressed: _loading ? null : _verifyCode,
                child: _loading ? const CircularProgressIndicator() : const Text('Verify & Continue'),
              ),
          ],
        ),
      ),
    );
  }
}
