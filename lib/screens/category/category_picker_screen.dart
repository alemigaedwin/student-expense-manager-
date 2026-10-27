import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/category_model.dart';
import '../../services/app_state.dart';
import '../../utils/app_colors.dart';
import '../../utils/category_icon.dart';
import 'add_category_screen.dart';

Future<CategoryModel?> showCategoryPicker(
  BuildContext context, {
  required CategoryKind kind,
}) {
  final height = MediaQuery.of(context).size.height *
      (kind == CategoryKind.income ? .64 : .72);
  return showModalBottomSheet<CategoryModel>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
    builder: (_) => SizedBox(
      height: height,
      child: CategoryPickerPanel(kind: kind),
    ),
  );
}

class CategoryPickerScreen extends StatefulWidget {
  final CategoryKind kind;
  CategoryPickerScreen({super.key, required this.kind});

  @override
  State<CategoryPickerScreen> createState() => _CategoryPickerScreenState();
}

class _CategoryPickerScreenState extends State<CategoryPickerScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CategoryPickerPanel(
          kind: widget.kind,
          fullScreen: true,
        ),
      ),
    );
  }
}

class CategoryPickerPanel extends StatefulWidget {
  final CategoryKind kind;
  final bool fullScreen;
  CategoryPickerPanel({
    super.key,
    required this.kind,
    this.fullScreen = false,
  });

  @override
  State<CategoryPickerPanel> createState() => _CategoryPickerPanelState();
}

class _CategoryPickerPanelState extends State<CategoryPickerPanel> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final all = app.categoriesFor(widget.kind);
    var recent = app.recentCategoriesFor(widget.kind);
    if (recent.isEmpty && widget.kind == CategoryKind.expense) {
      recent = all
          .where((c) =>
              c.name == 'Fruits and Vegetables' || c.name == 'Mobile')
          .toList();
    }
    final filtered = all.where((c) {
      if (query.isEmpty) return true;
      return c.name.toLowerCase().contains(query.toLowerCase());
    }).toList();

    final recentIds = recent.map((e) => e.id).toSet();
    final regular = filtered.where((c) => !recentIds.contains(c.id)).toList();
    final display = query.isEmpty && recent.isNotEmpty
        ? [...recent, ...regular]
        : filtered;

    return Material(
      color: AppColors.surface,
      child: Column(
        children: [
          Container(
            height: 70,
            padding: EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.border),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.category, color: AppColors.accent, size: 24),
                SizedBox(width: 12),
                Text(
                  'Category',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                Spacer(),
                TextButton(
                  onPressed: () async {
                    final newCat = await Navigator.push<CategoryModel>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddCategoryScreen(kind: widget.kind),
                      ),
                    );
                    if (newCat != null && mounted) {
                      Navigator.pop(context, newCat);
                    }
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
                  child: Text(
                    'Add New',
                    style: TextStyle(fontSize: 17, fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(5, 5, 5, 5),
            child: SizedBox(
              height: 38,
              child: TextField(
                style: TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  prefixIcon: Icon(
                    Icons.search,
                    color: AppColors.accent,
                    size: 25,
                  ),
                  prefixIconConstraints:
                      BoxConstraints(minWidth: 40),
                  contentPadding: EdgeInsets.zero,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5),
                    borderSide:
                        BorderSide(color: AppColors.textPrimary),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5),
                    borderSide:
                        BorderSide(color: AppColors.accent),
                  ),
                ),
                onChanged: (v) => setState(() => query = v),
              ),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.fromLTRB(5, 2, 5, 0),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: .92,
                mainAxisSpacing: 5,
                crossAxisSpacing: 2,
              ),
              itemCount: display.length,
              itemBuilder: (context, i) {
                final c = display[i];
                return InkWell(
                  onTap: () => Navigator.pop(context, c),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CategoryIcon(category: c, size: 44),
                      SizedBox(height: 4),
                      Text(
                        c.name,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Container(
            height: 48,
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: AppColors.border),
              ),
            ),
            alignment: Alignment.centerRight,
            padding: EdgeInsets.only(right: 20),
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 18,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
