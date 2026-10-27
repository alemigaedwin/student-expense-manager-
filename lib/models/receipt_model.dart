/// Metadata for a receipt stored in the database (`receipts` table).
/// The file bytes are downloaded on demand with BackendService.downloadReceipt.
class ReceiptInfo {
  final String id;
  final String fileName;
  final String mimeType;
  final int size;

  const ReceiptInfo({
    required this.id,
    required this.fileName,
    required this.mimeType,
    required this.size,
  });

  /// The value stored in TransactionModel.billPaths / transaction_bills.
  String get reference => '$referencePrefix$id';

  bool get isPdf => mimeType == 'application/pdf';
  bool get isImage => mimeType.startsWith('image/');

  static const referencePrefix = 'receipt:';

  /// Returns the receipt id for a billPaths entry, or null for legacy entries
  /// that were saved as device file paths before database receipts existed.
  static String? idFromReference(String reference) =>
      reference.startsWith(referencePrefix)
          ? reference.substring(referencePrefix.length)
          : null;

  String get sizeLabel {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(0)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  factory ReceiptInfo.fromJson(Map<String, dynamic> json) => ReceiptInfo(
        id: json['id'].toString(),
        fileName: (json['fileName'] ?? 'receipt').toString(),
        mimeType: (json['mimeType'] ?? 'application/octet-stream').toString(),
        size: (json['size'] as num?)?.toInt() ?? 0,
      );
}
