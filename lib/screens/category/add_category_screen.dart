import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/category_model.dart';
import '../../services/app_state.dart';
import '../../services/default_data.dart';
import '../../utils/app_colors.dart';

class AddCategoryScreen extends StatefulWidget {
  final CategoryKind kind;
  AddCategoryScreen({super.key, required this.kind});

  @override
  State<AddCategoryScreen> createState() => _AddCategoryScreenState();
}

class _AddCategoryScreenState extends State<AddCategoryScreen> {
  final _nameController = TextEditingController();
  String? _selectedAsset;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final icons = categoryIconChoices();
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(10, 18, 10, 8),
              child: Row(
                children: [
                  Text(
                    'Name',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _nameController,
                      maxLength: 20,
                      autofocus: false,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontStyle: FontStyle.italic,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: 'Maximum 20 characters',
                        hintStyle: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 20,
                          fontStyle: FontStyle.italic,
                        ),
                        contentPadding: EdgeInsets.only(bottom: 2),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: AppColors.accent),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: AppColors.accent),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.info, color: AppColors.accent, size: 28),
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Enter a name and choose an icon.'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: EdgeInsets.fromLTRB(32, 8, 32, 8),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 24,
                  crossAxisSpacing: 28,
                  childAspectRatio: .9,
                ),
                itemCount: icons.length,
                itemBuilder: (context, i) {
                  final asset = icons[i];
                  final selected = asset == _selectedAsset;
                  return InkWell(
                    borderRadius: BorderRadius.circular(40),
                    onTap: () => setState(() => _selectedAsset = asset),
                    child: Center(
                      child: Container(
                        padding: EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: selected
                              ? Border.all(color: AppColors.accent, width: 3)
                              : null,
                        ),
                        child: Image.asset(
                          asset,
                          width: 58,
                          height: 58,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(22, 0, 22, 18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
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
                  SizedBox(width: 28),
                  FloatingActionButton(
                    mini: false,
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    onPressed: _save,
                    child: Icon(Icons.check, size: 24),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty || _selectedAsset == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a name and choose an icon')),
      );
      return;
    }
    final app = context.read<AppState>();
    final cat = app.addCategory(
      name: name,
      icon: Icons.category,
      color: AppColors.accent,
      iconAsset: _selectedAsset,
      kind: widget.kind,
    );
    Navigator.pop(context, cat);
  }
}
