import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../screens/transactions/receipt_viewer_screen.dart';
import '../services/app_state.dart';
import '../utils/app_colors.dart';

/// Shows a transaction's receipts as tappable chips. Tapping opens the file
/// from the database. When [onRemove] is set each chip gets a delete button.
class ReceiptChips extends StatelessWidget {
  final List<String> references;
  final void Function(String reference)? onRemove;
  final bool compact;

  const ReceiptChips({
    super.key,
    required this.references,
    this.onRemove,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (references.isEmpty) return const SizedBox.shrink();
    final app = context.watch<AppState>();
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: references.map((ref) {
        final info = app.receiptForReference(ref);
        final label = info?.fileName ?? 'Old attachment (not stored)';
        return InputChip(
          visualDensity: compact ? VisualDensity.compact : VisualDensity.standard,
          avatar: Icon(
            info == null
                ? Icons.link_off
                : (info.isPdf ? Icons.picture_as_pdf : Icons.image_outlined),
            size: 18,
            color: info == null ? AppColors.textMuted : AppColors.accent,
          ),
          label: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: compact ? 120 : 190),
            child: Text(label, overflow: TextOverflow.ellipsis),
          ),
          tooltip: info == null
              ? 'This bill was saved as a file path on an old device and was never uploaded.'
              : 'View ${info.fileName} (${info.sizeLabel})',
          onPressed: info == null
              ? null
              : () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => ReceiptViewerScreen(receipt: info)),
                  ),
          onDeleted: onRemove == null ? null : () => onRemove!(ref),
        );
      }).toList(),
    );
  }
}
