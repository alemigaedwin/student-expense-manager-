import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/note_model.dart';
import '../../services/app_state.dart';
import '../../utils/app_colors.dart';
import '../../utils/formatters.dart';
import '../../widgets/summary_card.dart';
import 'add_note_screen.dart';

enum _NoteSort { completed, pending, dateAsc, dateDesc, report }

class NotebookTab extends StatefulWidget {
  NotebookTab({super.key});

  @override
  State<NotebookTab> createState() => _NotebookTabState();
}

class _NotebookTabState extends State<NotebookTab> {
  String _rangeFilter = 'All';
  _NoteSort? _sort;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    List<NoteModel> notes = app.notes;
    final now = DateTime.now();

    if (_rangeFilter == 'Daily') {
      notes = notes
          .where((n) =>
              n.dateTime.year == now.year &&
              n.dateTime.month == now.month &&
              n.dateTime.day == now.day)
          .toList();
    } else if (_rangeFilter == 'Weekly') {
      final weekAgo = now.subtract(Duration(days: 7));
      notes = notes.where((n) => n.dateTime.isAfter(weekAgo)).toList();
    } else if (_rangeFilter == 'Monthly') {
      notes = notes
          .where((n) => n.dateTime.year == now.year && n.dateTime.month == now.month)
          .toList();
    } else if (_rangeFilter == 'Yearly') {
      notes = notes.where((n) => n.dateTime.year == now.year).toList();
    }

    switch (_sort) {
      case _NoteSort.completed:
        notes = notes.where((n) => n.completed).toList();
        break;
      case _NoteSort.pending:
        notes = notes.where((n) => !n.completed).toList();
        break;
      case _NoteSort.dateAsc:
        notes.sort((a, b) => a.dateTime.compareTo(b.dateTime));
        break;
      case _NoteSort.dateDesc:
        notes.sort((a, b) => b.dateTime.compareTo(a.dateTime));
        break;
      case _NoteSort.report:
      case null:
        break;
    }

    final completedCount = app.notes.where((n) => n.completed).length;
    final pendingCount = app.notes.where((n) => !n.completed).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.accent,
        onPressed: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => AddNoteScreen())),
        child: Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: SizedBox(
                      height: 36,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: ['All', 'Daily', 'Weekly', 'Monthly', 'Yearly']
                            .map((f) => Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 4),
                                  child: ChoiceChip(
                                    label: Text(f),
                                    selected: _rangeFilter == f,
                                    selectedColor: AppColors.accent,
                                    backgroundColor: AppColors.surfaceLight,
                                    labelStyle: TextStyle(
                                        color: _rangeFilter == f
                                            ? Colors.white
                                            : AppColors.textSecondary),
                                    onSelected: (_) =>
                                        setState(() => _rangeFilter = f),
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
                  ),
                ),
                PopupMenuButton<_NoteSort>(
                  icon: Icon(Icons.more_vert, color: AppColors.textPrimary),
                  color: AppColors.surface,
                  onSelected: (v) => setState(() => _sort = v),
                  itemBuilder: (context) => [
                    PopupMenuItem(value: _NoteSort.completed, child: Text('Completed', style: TextStyle(color: AppColors.textPrimary))),
                    PopupMenuItem(value: _NoteSort.pending, child: Text('Pending', style: TextStyle(color: AppColors.textPrimary))),
                    PopupMenuItem(value: _NoteSort.dateAsc, child: Text('Date Ascending', style: TextStyle(color: AppColors.textPrimary))),
                    PopupMenuItem(value: _NoteSort.dateDesc, child: Text('Date Descending', style: TextStyle(color: AppColors.textPrimary))),
                    PopupMenuItem(value: _NoteSort.report, child: Text('Report', style: TextStyle(color: AppColors.textPrimary))),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: notes.isEmpty
                ? Center(
                    child: Text('No notes yet. Tap + to add one.',
                        style: TextStyle(color: AppColors.textSecondary)))
                : ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    itemCount: notes.length,
                    itemBuilder: (context, i) {
                      final n = notes[i];
                      return Card(
                        color: AppColors.surface,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: AppColors.border)),
                        child: ListTile(
                          leading: Checkbox(
                            value: n.completed,
                            activeColor: AppColors.income,
                            onChanged: (_) =>
                                app.toggleNoteCompleted(n.id),
                          ),
                          title: Text(n.text,
                              style: TextStyle(
                                  color: AppColors.textPrimary,
                                  decoration: n.completed
                                      ? TextDecoration.lineThrough
                                      : null)),
                          subtitle: Text(
                              '${Formatters.dayDateMonthYear.format(n.dateTime)}  ${Formatters.timeOnly.format(n.dateTime)}',
                              style: TextStyle(
                                  color: AppColors.textMuted, fontSize: 11)),
                          trailing: IconButton(
                            icon: Icon(Icons.delete_outline,
                                color: AppColors.expense),
                            onPressed: () => app.deleteNote(n.id),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Container(
            color: AppColors.surface,
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(children: [
                    Text('Completed',
                        style: TextStyle(color: AppColors.income, fontSize: 12)),
                    Text('$completedCount',
                        style: TextStyle(color: AppColors.income)),
                  ]),
                ),
                Expanded(
                  child: Column(children: [
                    Text('Pending',
                        style: TextStyle(color: AppColors.expense, fontSize: 12)),
                    Text('$pendingCount',
                        style: TextStyle(color: AppColors.expense)),
                  ]),
                ),
                Expanded(
                  child: Column(children: [
                    Text('Total',
                        style: TextStyle(color: AppColors.textPrimary, fontSize: 12)),
                    Text('${app.notes.length}',
                        style: TextStyle(color: AppColors.textPrimary)),
                  ]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
