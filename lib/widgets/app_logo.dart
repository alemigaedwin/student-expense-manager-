import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

/// The Student Expense Manager brand mark: a graduation cap sitting on a
/// coin, representing "student" + "money". Used across the app bar, the
/// nav drawer header, and the launcher/web icons (see assets/logo).
class AppLogo extends StatelessWidget {
  final double size;
  final bool showBackground;

  AppLogo({super.key, this.size = 32, this.showBackground = true});

  @override
  Widget build(BuildContext context) {
    final content = Image.asset(
      'assets/logo/app_logo.png',
      width: size,
      height: size,
      errorBuilder: (context, error, stackTrace) => _FallbackMark(size: size),
    );
    if (!showBackground) return content;
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.28),
      child: content,
    );
  }
}

/// Drawn-in-code fallback in case the image asset can't be loaded, so the
/// brand mark still always renders.
class _FallbackMark extends StatelessWidget {
  final double size;
  _FallbackMark({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Icon(Icons.school, color: Colors.white, size: size * 0.62),
    );
  }
}
