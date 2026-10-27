import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

/// The big "Add Income / Add Expense / Transfer / Transactions" tiles
/// on the Home screen.
class HomeActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;
  HomeActionButton({
    super.key,
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          height: 84,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 24),
              SizedBox(height: 6),
              Text(label,
                  style: TextStyle(
                      color: AppColors.textPrimary, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }
}

/// A card section title with a "More ->" link, used on Home.
class SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final VoidCallback? onMore;
  SectionCard(
      {super.key, required this.title, required this.child, this.onMore});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
          SizedBox(height: 8),
          child,
          if (onMore != null) ...[
            SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onMore,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('More', style: TextStyle(color: AppColors.accent)),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward, size: 16, color: AppColors.accent),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
