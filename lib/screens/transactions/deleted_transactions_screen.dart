import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/app_state.dart';
import '../../utils/app_colors.dart';
import '../../widgets/transaction_tile.dart';

class DeletedTransactionsScreen extends StatelessWidget {
  DeletedTransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final list = app.deletedTransactions;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text('Deleted Transactions'),
      ),
      body: list.isEmpty
          ? Center(
              child: Text('No deleted transactions',
                  style: TextStyle(color: AppColors.textSecondary)))
          : ListView.builder(
              itemCount: list.length,
              itemBuilder: (context, i) {
                final t = list[i];
                return Dismissible(
                  key: ValueKey(t.id),
                  background: Container(
                    color: AppColors.income,
                    alignment: Alignment.centerLeft,
                    padding: EdgeInsets.only(left: 20),
                    child: Icon(Icons.restore, color: Colors.white),
                  ),
                  secondaryBackground: Container(
                    color: AppColors.expense,
                    alignment: Alignment.centerRight,
                    padding: EdgeInsets.only(right: 20),
                    child: Icon(Icons.delete_forever, color: Colors.white),
                  ),
                  onDismissed: (direction) async {
                    final restored =
                        direction == DismissDirection.startToEnd;
                    final saved = restored
                        ? await app.restoreTransaction(t.id)
                        : await app.permanentlyDeleteTransaction(t.id);
                    if (!saved && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(restored
                              ? 'Could not restore this transaction. Check the server connection.'
                              : 'Could not permanently delete this transaction. Check the server connection.'),
                        ),
                      );
                    } else if (saved && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(restored
                              ? 'Transaction restored successfully.'
                              : 'Transaction permanently deleted.'),
                        ),
                      );
                    }
                  },
                  child: TransactionTile(t: t),
                );
              },
            ),
    );
  }
}
