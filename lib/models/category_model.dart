import 'package:flutter/material.dart';

/// Which kind of transaction a category can be used for.
enum CategoryKind { income, expense, both }

class CategoryModel {
  final String id;
  String name;
  final int iconCodePoint;
  final String iconFontFamily;
  final int colorValue;
  final String? iconAsset;
  final CategoryKind kind;
  final bool isCustom;
  String? parentId; // for subcategories

  CategoryModel({
    required this.id,
    required this.name,
    required this.iconCodePoint,
    this.iconFontFamily = 'MaterialIcons',
    required this.colorValue,
    this.iconAsset,
    required this.kind,
    this.isCustom = false,
    this.parentId,
  });

  IconData get icon => IconData(iconCodePoint, fontFamily: iconFontFamily);
  Color get color => Color(colorValue);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'iconCodePoint': iconCodePoint,
        'iconFontFamily': iconFontFamily,
        'colorValue': colorValue,
        'iconAsset': iconAsset,
        'kind': kind.index,
        'isCustom': isCustom,
        'parentId': parentId,
      };

  factory CategoryModel.fromJson(Map<String, dynamic> json) => CategoryModel(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? 'Category',
        iconCodePoint: (json['iconCodePoint'] as num?)?.toInt() ?? 0,
        iconFontFamily: json['iconFontFamily']?.toString() ?? 'MaterialIcons',
        colorValue: (json['colorValue'] as num?)?.toInt() ?? 0xFF9E9E9E,
        iconAsset: json['iconAsset']?.toString(),
        kind: CategoryKind.values[(json['kind'] as num?)?.toInt() ?? 1],
        isCustom: json['isCustom'] == true || json['isCustom'] == 1,
        parentId: json['parentId']?.toString(),
      );
}
