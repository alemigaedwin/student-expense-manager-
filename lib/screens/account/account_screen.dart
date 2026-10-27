import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/app_state.dart';
import '../../utils/app_colors.dart';

class AccountScreen extends StatefulWidget {
  AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  String query = '';
  bool editing = false;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final all = app.accounts;
    final filtered = query.isEmpty
        ? all
        : all.where((a) => a.name.toLowerCase().contains(query.toLowerCase())).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: Icon(Icons.storefront, color: AppColors.accent),
        title: Text('Account'),
        actions: [
          TextButton(
            onPressed: () => setState(() => editing = !editing),
            child: Text(editing ? 'Done' : 'Edit',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(12),
            child: TextField(
              style: TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.search, color: AppColors.accent),
                hintText: 'Search',
                hintStyle: TextStyle(color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              ),
              onChanged: (v) => setState(() => query = v),
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: filtered.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: AppColors.border),
              itemBuilder: (context, i) {
                final acc = filtered[i];
                final selected = acc.id == app.currentAccountId();
                return ListTile(
                  leading: Icon(
                      selected ? Icons.radio_button_checked : Icons.radio_button_off,
                      color: AppColors.accent),
                  title: editing
                      ? TextFormField(
                          initialValue: acc.name,
                          style: TextStyle(color: AppColors.textPrimary),
                          onFieldSubmitted: (v) => app.renameAccount(acc.id, v),
                        )
                      : Text(acc.name, style: TextStyle(color: AppColors.textPrimary)),
                  onTap: () {
                    app.switchAccount(acc.id);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 14)),
                onPressed: () => _addAccountDialog(context, app),
                child: Text('Add Account'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _addAccountDialog(BuildContext context, AppState app) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Add Account', style: TextStyle(color: AppColors.textPrimary)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(hintText: 'e.g. School Fees Book'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel')),
          TextButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) app.addAccount(name);
              Navigator.pop(ctx);
            },
            child: Text('Add'),
          ),
        ],
      ),
    );
  }
}
