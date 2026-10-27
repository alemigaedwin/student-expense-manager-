import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/app_state.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final email = TextEditingController();
  final code = TextEditingController();
  final password = TextEditingController();
  final confirm = TextEditingController();
  bool requestingCode = false;
  bool codeRequested = false;
  bool resetting = false;

  @override
  void dispose() {
    email.dispose();
    code.dispose();
    password.dispose();
    confirm.dispose();
    super.dispose();
  }

  Future<void> _reset() async {
    if (password.text != confirm.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match.')),
      );
      return;
    }

    setState(() => resetting = true);
    final ok = await context.read<AppState>().resetPassword(
          email.text,
          code.text,
          password.text,
        );

    if (!mounted) return;
    setState(() => resetting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Password updated. You can now log in.'
              : context.read<AppState>().syncError ??
                  'The reset code is invalid or expired. Request a new code.',
        ),
      ),
    );
    if (ok) Navigator.pop(context);
  }

  Future<void> _requestCode() async {
    if (email.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter your registered email first.')),
      );
      return;
    }
    setState(() => requestingCode = true);
    final ok =
        await context.read<AppState>().requestPasswordResetCode(email.text);
    if (!mounted) return;
    setState(() {
      requestingCode = false;
      codeRequested = ok;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'If that email has an account, a reset code will arrive shortly.'
              : context.read<AppState>().syncError ??
                  'Could not request a reset code.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot password')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Column(
              children: [
                const SizedBox(height: 20),
                const Icon(Icons.lock_reset,
                    size: 60, color: Color(0xFF2196F3)),
                const SizedBox(height: 12),
                const Text(
                  'Reset your password',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Registered email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: requestingCode ? null : _requestCode,
                    icon: requestingCode
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.email_outlined),
                    label: Text(requestingCode
                        ? 'Requesting code...'
                        : codeRequested
                            ? 'Send another code'
                            : 'Send reset code'),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: code,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: const InputDecoration(
                    labelText: 'Six-digit reset code',
                    prefixIcon: Icon(Icons.pin_outlined),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: password,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'New password',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: confirm,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirm new password',
                    prefixIcon: Icon(Icons.lock_reset),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: resetting ? null : _reset,
                    child: Text(resetting ? 'Updating...' : 'Reset password'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
