import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/category_model.dart';
import '../../services/app_state.dart';
import '../../utils/app_colors.dart';
import 'add_category_screen.dart';

/// Lists all categories (Income + Expense). When [showSubcategories] is
/// true, tapping a category lets the user attach child subcategories to it
/// (mirrors the "Subcategory" menu entry).
class CategoryManageScreen extends StatefulWidget {
  final bool showSubcategories;
  CategoryManageScreen({super.key, this.showSubcategories = false});

  @override
  State<CategoryManageScreen> createState() => _CategoryManageScreenState();
}

class _CategoryManageScreenState extends State<CategoryManageScreen> {
  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final income = app.categoriesFor(CategoryKind.income);
    final expense = app.categoriesFor(CategoryKind.expense);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          title: Text(widget.showSubcategories ? 'Subcategory' : 'Category'),
          bottom: TabBar(
            indicatorColor: AppColors.accent,
            labelColor: AppColors.accent,
            unselectedLabelColor: AppColors.textSecondary,
            tabs: [Tab(text: 'INCOME'), Tab(text: 'EXPENSE')],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: AppColors.accent,
          onPressed: () async {
            await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        AddCategoryScreen(kind: CategoryKind.expense)));
          },
          child: Icon(Icons.add),
        ),
        body: TabBarView(
          children: [
            _list(income),
            _list(expense),
          ],
        ),
      ),
    );
  }

  Widget _list(List<CategoryModel> items) {
    if (items.isEmpty) {
      return Center(
          child: Text('No categories', style: TextStyle(color: AppColors.textSecondary)));
    }
    return ListView.builder(
      padding: EdgeInsets.all(8),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final c = items[i];
        return ListTile(
          leading: CircleAvatar(
              backgroundColor: c.color.withOpacity(0.2),
              child: Icon(c.icon, color: c.color)),
          title: Text(c.name, style: TextStyle(color: AppColors.textPrimary)),
          subtitle: c.isCustom
              ? Text('Custom', style: TextStyle(color: AppColors.textMuted, fontSize: 11))
              : null,
          trailing: widget.showSubcategories
              ? Icon(Icons.chevron_right, color: AppColors.textMuted)
              : null,
        );
      },
    );
  }
}
