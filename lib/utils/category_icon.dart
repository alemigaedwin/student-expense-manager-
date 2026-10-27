import 'package:flutter/material.dart';
import '../models/category_model.dart';

/// Renders the illustrated category icons used by the reference screens.
/// Older/custom categories without an asset continue to use their Material icon.
class CategoryIcon extends StatelessWidget {
  final CategoryModel category;
  final double size;
  final bool circleBackground;

  const CategoryIcon({
    super.key,
    required this.category,
    this.size = 42,
    this.circleBackground = true,
  });

  @override
  Widget build(BuildContext context) {
    if (category.iconAsset != null && category.iconAsset!.isNotEmpty) {
      return Image.asset(
        category.iconAsset!,
        width: size,
        height: size,
        fit: BoxFit.contain,
      );
    }
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: circleBackground ? Colors.white : Colors.transparent,
      child: Icon(category.icon, color: category.color, size: size * .52),
    );
  }
}
