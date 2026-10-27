import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../services/app_state.dart';
import '../../utils/app_colors.dart';

class BackupRestoreScreen extends StatelessWidget {
  BackupRestoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text('Backup and Restore'),
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          Text(
            'Export a full backup of your transactions, categories, payment '
            'methods, budgets, notes and reminders as a JSON file you can '
            'keep safe or move to another device.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          SizedBox(height: 20),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 14)),
            icon: Icon(Icons.cloud_upload),
            label: Text('Export Backup'),
            onPressed: () => _exportBackup(context),
          ),
          SizedBox(height: 12),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.border),
                padding: EdgeInsets.symmetric(vertical: 14)),
            icon: Icon(Icons.cloud_download, color: AppColors.accent),
            label: Text('Restore from Backup',
                style: TextStyle(color: AppColors.textPrimary)),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(
                        'Restore: paste your exported JSON via a file manager import (extend this screen with file_picker as needed).'))),
          ),
        ],
      ),
    );
  }

  void _exportBackup(BuildContext context) {
    final data = context.read<AppState>().exportDataJson();
    final jsonStr = JsonEncoder.withIndent('  ').convert(data);
    Share.share(jsonStr, subject: 'Student Expense Manager Backup');
  }
}
