import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/app_state.dart';
import '../../services/local_auth_service.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _email.text.trim().toLowerCase();
    final password = _password.text;
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter your email and password.')));
      return;
    }

    setState(() => _busy = true);
    final app = context.read<AppState>();
    try {
      if (LocalAuthService.verify(email, password)) {
        app.startOfflineMode();
        app.setUserSetting('user_name', LocalAuthService.registeredName ?? email.split('@').first);
        return;
      }

      // Existing server accounts remain supported. Cache only after the server
      // confirms the password, enabling later offline sign-in on this device.
      final online = await app.loginUser(email, password);
      if (online) {
        LocalAuthService.cacheSuccessfulLogin(app.userDisplayName, email, password);
        return;
      }

      if (!mounted) return;
      final localEmail = LocalAuthService.registeredEmail;
      final message = localEmail != null && localEmail.isNotEmpty
          ? 'The password did not match the account saved on this device.'
          : (app.syncError ?? 'Sign-in failed. Check your connection or create an account on this device.');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red.shade700));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Image.asset('assets/logo/app_logo.png', width: 76, height: 76, errorBuilder: (_, __, ___) => const Icon(Icons.account_balance_wallet, size: 72)),
                  const SizedBox(height: 16),
                  Text('Student Expense Manager', textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('Track your income, spending, and student budget—even offline.', textAlign: TextAlign.center),
                  const SizedBox(height: 28),
                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.username],
                    decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _password,
                    obscureText: _obscure,
                    autofillHints: const [AutofillHints.password],
                    onSubmitted: (_) => _busy ? null : _login(),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(onPressed: () => setState(() => _obscure = !_obscure), icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _busy ? null : _login,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: _busy ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Sign in'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())), child: const Text('Create an offline account')),
                  const SizedBox(height: 16),
                  Text('Your local account and records stay on this phone. Server sign-in is optional.', textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
