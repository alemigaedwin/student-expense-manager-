import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/app_state.dart';
import 'services/storage_service.dart';
import 'screens/home/home_shell.dart';
import 'screens/auth/login_screen.dart';
import 'utils/app_colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.init();
  runApp(StudentExpenseManagerApp());
}

class StudentExpenseManagerApp extends StatelessWidget {
  const StudentExpenseManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState()..load(),
      child: Consumer<AppState>(
        builder: (context, app, _) => MaterialApp(
          title: 'Student Expense Manager',
          debugShowCheckedModeBanner: false,
          themeMode: app.themeMode,
          theme: _buildTheme(Brightness.light),
          darkTheme: _buildTheme(Brightness.dark),
          home: app.isAuthenticated ? HomeShell() : LoginScreen(),
        ),
      ),
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final base = ThemeData(useMaterial3: true, brightness: brightness);
    return base.copyWith(
      scaffoldBackgroundColor: dark ? Color(0xFF101827) : Color(0xFFF4F7FC),
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.accent,
        secondary: AppColors.accent,
        surface: dark ? Color(0xFF1B2638) : Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: dark ? Color(0xFF1B2638) : Colors.white,
        foregroundColor: dark ? Color(0xFFF3F6FC) : Color(0xFF17233A),
        elevation: 0,
        centerTitle: false,
      ),
      cardColor: dark ? Color(0xFF1B2638) : Colors.white,
      dividerColor: dark ? Color(0xFF34445D) : Color(0xFFD7E0ED),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark ? Color(0xFF1B2638) : Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      textTheme: base.textTheme.apply(
        bodyColor: dark ? Color(0xFFF3F6FC) : Color(0xFF17233A),
        displayColor: dark ? Color(0xFFF3F6FC) : Color(0xFF17233A),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
      ),
    );
  }
}
