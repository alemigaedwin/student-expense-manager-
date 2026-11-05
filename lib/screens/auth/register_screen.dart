import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/app_state.dart';
import '../../utils/app_colors.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final name = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final confirm = TextEditingController();
  bool obscurePass = true;
  bool obscureConfirm = true;
  bool isRegistering = false;

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    password.dispose();
    confirm.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final cleanName = name.text.trim();
    final cleanEmail = email.text.trim();
    final pass = password.text;
    final conf = confirm.text;

    if (cleanName.isEmpty || cleanEmail.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields.')),
      );
      return;
    }
    if (pass != conf) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match.')),
      );
      return;
    }
    if (pass.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters.')),
      );
      return;
    }

    setState(() => isRegistering = true);
    final app = context.read<AppState>();
    final success = await app.registerUser(cleanName, cleanEmail, pass);
    if (!mounted) return;
    setState(() => isRegistering = false);

    if (success) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(
            content: Text('Account created successfully! Please log in.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text(app.syncError ?? 'Registration failed. Check database connection and try again.'),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 3),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Create Student Account'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // Background: Student Income & Expense Management Illustration
          Positioned.fill(
            child: Image.asset(
              'assets/images/student_income_manage.jpg',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: const Color(0xFF0F172A)),
            ),
          ),

          // Gradient scrim overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.55),
                    Colors.black.withOpacity(0.85),
                  ],
                ),
              ),
            ),
          ),

          // Register Form Card
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 28),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E293B).withOpacity(0.92)
                          : Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 25,
                          offset: const Offset(0, 10),
                        ),
                      ],
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1.2,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset('assets/logo/app_logo.png', width: 48, height: 48),
                            const SizedBox(width: 12),
                            const Flexible(
                              child: Text(
                                'Student Registration',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        TextField(
                          controller: name,
                          decoration: InputDecoration(
                            labelText: 'Full Name',
                            hintText: 'Alex Morgan',
                            prefixIcon: const Icon(Icons.person_outline),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: email,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Student Email',
                            hintText: 'student@campus.edu',
                            prefixIcon: const Icon(Icons.email_outlined),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: password,
                          obscureText: obscurePass,
                          decoration: InputDecoration(
                            labelText: 'Password (min 6 chars)',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(obscurePass ? Icons.visibility : Icons.visibility_off),
                              onPressed: () => setState(() => obscurePass = !obscurePass),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: confirm,
                          obscureText: obscureConfirm,
                          decoration: InputDecoration(
                            labelText: 'Confirm Password',
                            prefixIcon: const Icon(Icons.lock_reset),
                            suffixIcon: IconButton(
                              icon: Icon(obscureConfirm ? Icons.visibility : Icons.visibility_off),
                              onPressed: () => setState(() => obscureConfirm = !obscureConfirm),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(height: 22),

                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: FilledButton(
                            onPressed: isRegistering ? null : _register,
                            style: FilledButton.styleFrom(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: isRegistering
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text('Create Student Account', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Already registered? Back to Login'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
