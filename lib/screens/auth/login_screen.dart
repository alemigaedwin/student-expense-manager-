import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/app_state.dart';
import '../../utils/app_colors.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  LoginScreen({super.key});
  @override State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool obscure = true;

  @override
  void dispose() { email.dispose(); password.dispose(); super.dispose(); }

  Future<void> _google() async {
    final uri = Uri.parse('https://accounts.google.com/');
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Google login'),
        content: Text('Google account authentication is opened in your browser. Connect the OAuth callback to your backend/Firebase in the production version. For this front-end build, use email/password to create the local demo session.'),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('OK'))],
      ),
    );
  }


  Future<void> _login() async {
    final app = context.read<AppState>();

    final ok = await app.loginUser(
      email.text.trim(),
      password.text,
    );

    if (!mounted) return;

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            app.syncError ??
                'Login failed. Check your email, password and server connection.',
          ),
          duration: const Duration(seconds: 6),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 430),
              child: Column(
                children: [
                  Image.asset('assets/logo/app_logo.png', width: 86, height: 86),
                  SizedBox(height: 16),
                  Text('Student Expense Manager', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800)),
                  SizedBox(height: 6),
                  Text('Manage your student money in one place.', style: TextStyle(color: AppColors.textSecondary)),
                  SizedBox(height: 30),
                  TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined))),
                  SizedBox(height: 14),
                  TextField(controller: password, obscureText: obscure, decoration: InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock_outline), suffixIcon: IconButton(icon: Icon(obscure ? Icons.visibility : Icons.visibility_off), onPressed: () => setState(() => obscure = !obscure)))),
                  Align(alignment: Alignment.centerRight, child: TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ForgotPasswordScreen())), child: Text('Forgot password?'))),
                  SizedBox(width: double.infinity, child: FilledButton(onPressed: _login, child: Padding(padding: EdgeInsets.all(13), child: Text('Login')))),
                  SizedBox(height: 12),
                  OutlinedButton.icon(onPressed: _google, icon: Icon(Icons.account_circle_outlined), label: Text('Continue with Google'), style: OutlinedButton.styleFrom(minimumSize: Size.fromHeight(50))),
                  SizedBox(height: 20),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text('New student?', style: TextStyle(color: AppColors.textSecondary)), TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RegisterScreen())), child: Text('Create account'))]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
