import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../../models/receipt_model.dart';
import '../../services/backend_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/file_export.dart';

/// Downloads a receipt from the database and shows it (image zoom / PDF preview).
class ReceiptViewerScreen extends StatefulWidget {
  final ReceiptInfo receipt;
  const ReceiptViewerScreen({super.key, required this.receipt});

  @override
  State<ReceiptViewerScreen> createState() => _ReceiptViewerScreenState();
}

class _ReceiptViewerScreenState extends State<ReceiptViewerScreen> {
  // Small in-memory cache so reopening a receipt in the same session is instant.
  static final Map<String, Uint8List> _cache = {};
  late Future<Uint8List> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<Uint8List> _load() async {
    final cached = _cache[widget.receipt.id];
    if (cached != null) return cached;
    final bytes = await BackendService.downloadReceipt(widget.receipt.id);
    _cache[widget.receipt.id] = bytes;
    return bytes;
  }

  Future<void> _save(Uint8List bytes) async {
    try {
      await exportFile(bytes, widget.receipt.fileName, widget.receipt.mimeType);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Receipt ready to save or share.')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save the receipt.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.receipt;
    return Scaffold(
      appBar: AppBar(
        title: Text(r.fileName, overflow: TextOverflow.ellipsis),
        actions: [
          FutureBuilder<Uint8List>(
            future: _future,
            builder: (context, snap) => IconButton(
              tooltip: 'Save / share',
              icon: const Icon(Icons.download),
              onPressed: snap.hasData ? () => _save(snap.data!) : null,
            ),
          ),
        ],
      ),
      body: FutureBuilder<Uint8List>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError || snap.data == null) {
            final message =
                snap.error?.toString().replaceFirst('Exception: ', '') ??
                    'Could not load the receipt.';
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.error_outline, size: 40, color: AppColors.expense),
                  const SizedBox(height: 12),
                  Text(message, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => setState(() => _future = _load()),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try again'),
                  ),
                ]),
              ),
            );
          }
          final bytes = snap.data!;
          if (r.isPdf) {
            return PdfPreview(
              build: (_) => bytes,
              canChangePageFormat: false,
              canChangeOrientation: false,
              canDebug: false,
            );
          }
          return InteractiveViewer(
            minScale: 0.8,
            maxScale: 5,
            child: Center(
              child: Image.memory(
                bytes,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) =>
                    const Text('This image could not be displayed.'),
              ),
            ),
          );
        },
      ),
    );
  }
}
