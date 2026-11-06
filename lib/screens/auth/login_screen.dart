import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import '../../services/app_state.dart';
import '../../services/backend_service.dart';
import '../../utils/app_colors.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool obscure = true;
  bool isLoggingIn = false;

  @override
  void dispose() { email.dispose(); password.dispose(); super.dispose(); }

  Future<void> _google() async {
    setState(() => isLoggingIn = true);
    try {
      const String clientId = String.fromEnvironment(
        'GOOGLE_CLIENT_ID',
        defaultValue: '1039870198031-studentexpensemanager.apps.googleusercontent.com',
      );

      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: kIsWeb ? clientId : null,
        serverClientId: !kIsWeb ? clientId : null,
        scopes: ['email', 'profile'],
      );

      try {
        await googleSignIn.disconnect();
      } catch (_) {
        await googleSignIn.signOut();
      }

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser != null) {
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final String userEmail = googleUser.email;
        final String userName = googleUser.displayName ?? userEmail.split('@').first;
        final String googleId = googleUser.id;
        final String? idToken = googleAuth.idToken;

        if (!mounted) return;
        final app = context.read<AppState>();

        final ok = await app.loginWithGoogle(userEmail, userName, googleId, idToken);

        if (!mounted) return;
        if (!ok) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(app.syncError ?? 'Backend database error. Check server connection.'),
              backgroundColor: Colors.red.shade700,
            ),
          );
        }
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google Sign-In Error: $error'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isLoggingIn = false);
    }
  }

  Future<void> _login() async {
    final cleanEmail = email.text.trim();
    final cleanPass = password.text;
    if (cleanEmail.isEmpty || cleanPass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email and password.')),
      );
      return;
    }

    setState(() => isLoggingIn = true);
    final app = context.read<AppState>();
    final ok = await app.loginUser(cleanEmail, cleanPass);
    if (!mounted) return;
    setState(() => isLoggingIn = false);

    if (!ok) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text(
              app.syncError ?? 'Login failed. Check your credentials or tap Server below to verify your connection.',
            ),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Configure',
              textColor: Colors.white,
              onPressed: _showServerConfigDialog,
            ),
          ),
        );
    }
  }

  void _showServerConfigDialog() {
    final controller = TextEditingController(text: BackendService.baseUrl);
    String? testStatus;
    bool testing = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.dns, color: AppColors.accent),
              SizedBox(width: 8),
              Text('Database Server URL'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Connect this phone to your MySQL database:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                '• Local Wi-Fi (phone & PC on same Wi-Fi): http://YOUR_PC_IP/student_expense_manager_backend/backend/api.php\n• Free Cloud Host: https://your-domain/backend/api.php',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'API Base URL',
                  hintText: 'http://192.168.1.X/.../api.php',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.link),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: testing
                        ? null
                        : () async {
                            setDlgState(() {
                              testing = true;
                              testStatus = null;
                            });
                            final ok = await BackendService.testConnection(controller.text.trim());
                            setDlgState(() {
                              testing = false;
                              testStatus = ok
                                  ? 'Connected! MySQL Database is reachable.'
                                  : 'Could not reach server. Check IP and Wi-Fi.';
                            });
                          },
                    icon: testing
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.wifi_tethering, size: 16),
                    label: Text(testing ? 'Testing...' : 'Test Connection'),
                  ),
                ],
              ),
              if (testStatus != null) ...[
                const SizedBox(height: 8),
                Text(
                  testStatus!,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: testStatus!.contains('Connected') ? Colors.green.shade700 : Colors.red.shade700,
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                BackendService.setCustomUrl('');
                setState(() {});
                Navigator.pop(ctx);
              },
              child: const Text('Reset Default'),
            ),
            FilledButton(
              onPressed: () {
                BackendService.setCustomUrl(controller.text.trim());
                setState(() {});
                Navigator.pop(ctx);
              },
              child: const Text('Save & Apply'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // Background: Student Income & Expense Management Illustration
          Positioned.fill(
            child: Image.asset(
              'assets/images/student_income_manage.jpg',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: const Color(0xFF0F172A),
              ),
            ),
          ),

          // Gradient scrim overlay for contrast & readability
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

          // Main Login Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
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
                        // App Logo & Student Badges
                        Image.asset('assets/logo/app_logo.png', width: 78, height: 78),
                        const SizedBox(height: 12),
                        const Text(
                          'Student Expense Manager',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Form Fields
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
                          obscureText: obscure,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(obscure ? Icons.visibility : Icons.visibility_off),
                              onPressed: () => setState(() => obscure = !obscure),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ForgotPasswordScreen())),
                            child: const Text('Forgot password?', style: TextStyle(fontSize: 13)),
                          ),
                        ),

                        // Sign In Button
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: FilledButton(
                            onPressed: isLoggingIn ? null : _login,
                            style: FilledButton.styleFrom(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: isLoggingIn
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text('Login', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Google Button
                        OutlinedButton.icon(
                          onPressed: _google,
                          icon: const Icon(Icons.account_circle_outlined),
                          label: const Text('Continue with Google'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(46),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Register Link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "I don't have an account ",
                              style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                            ),
                            TextButton(
                              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RegisterScreen())),
                              child: const Text('Create account', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ],
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

  Widget _featureChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }
}
