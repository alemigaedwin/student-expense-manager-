import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/app_state.dart';
import '../../utils/app_colors.dart';
import '../../utils/formatters.dart';

class AddNoteScreen extends StatefulWidget {
  AddNoteScreen({super.key});

  @override
  State<AddNoteScreen> createState() => _AddNoteScreenState();
}

class _AddNoteScreenState extends State<AddNoteScreen> {
  final _controller = TextEditingController();
  DateTime _dateTime = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text('Notes'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _dateTime,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() => _dateTime = DateTime(picked.year,
                            picked.month, picked.day, _dateTime.hour, _dateTime.minute));
                      }
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(Formatters.dateOnly.format(_dateTime),
                              style: TextStyle(color: AppColors.textPrimary)),
                          Icon(Icons.calendar_today,
                              color: AppColors.accent, size: 16),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                InkWell(
                  onTap: () async {
                    final picked = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(_dateTime));
                    if (picked != null) {
                      setState(() => _dateTime = DateTime(_dateTime.year,
                          _dateTime.month, _dateTime.day, picked.hour, picked.minute));
                    }
                  },
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Text(Formatters.timeOnly.format(_dateTime),
                            style: TextStyle(color: AppColors.textPrimary)),
                        SizedBox(width: 6),
                        Icon(Icons.access_time,
                            color: AppColors.accent, size: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            TextField(
              controller: _controller,
              maxLines: 8,
              style: TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'Notes',
                labelStyle: TextStyle(color: AppColors.textSecondary),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.accent)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.accent, width: 2)),
              ),
            ),
            Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16)),
                onPressed: () {
                  final text = _controller.text.trim();
                  if (text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Write something first')));
                    return;
                  }
                  context.read<AppState>().addNote(text, _dateTime);
                  Navigator.pop(context);
                },
                child: Text('SAVE'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
