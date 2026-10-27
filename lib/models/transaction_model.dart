enum TransactionType { income, expense, transfer }

class ItemEntry {
  String name;
  double quantity;
  String unit;
  double rate;

  ItemEntry({
    required this.name,
    required this.quantity,
    required this.unit,
    required this.rate,
  });

  double get total => quantity * rate;

  Map<String, dynamic> toJson() => {
        'name': name,
        'quantity': quantity,
        'unit': unit,
        'rate': rate,
      };

  factory ItemEntry.fromJson(Map<String, dynamic> json) => ItemEntry(
        name: json['name']?.toString() ?? '',
        quantity: (json['quantity'] as num?)?.toDouble() ?? 1.0,
        unit: json['unit']?.toString() ?? '',
        rate: (json['rate'] as num?)?.toDouble() ?? 0.0,
      );

  String get summary =>
      '$name ${_fmt(quantity)}${unit.isNotEmpty ? ' $unit' : ''} @ ${_fmt(rate)} = ${_fmt(total)}';

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();
}

class TransactionModel {
  final String id;
  final String accountId;
  TransactionType type;
  double amount;
  String? categoryId; // null for transfers
  String? paymentMethodId; // "from" account for transfers
  String? toPaymentMethodId; // used only for transfers
  String notes;
  List<ItemEntry> items;
  List<String> billPaths; // local file paths / blob urls for attached bills
  DateTime date;
  bool isDeleted;

  TransactionModel({
    required this.id,
    required this.accountId,
    required this.type,
    required this.amount,
    this.categoryId,
    this.paymentMethodId,
    this.toPaymentMethodId,
    this.notes = '',
    List<ItemEntry>? items,
    List<String>? billPaths,
    required this.date,
    this.isDeleted = false,
  })  : items = items ?? [],
        billPaths = billPaths ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'accountId': accountId,
        'type': type.index,
        'amount': amount,
        'categoryId': categoryId,
        'paymentMethodId': paymentMethodId,
        'toPaymentMethodId': toPaymentMethodId,
        'notes': notes,
        'items': items.map((e) => e.toJson()).toList(),
        'billPaths': billPaths,
        'date': date.toIso8601String(),
        'isDeleted': isDeleted,
      };

  factory TransactionModel.fromJson(Map<String, dynamic> json) =>
      TransactionModel(
        id: json['id']?.toString() ?? '',
        accountId: json['accountId']?.toString() ?? 'default',
        type: TransactionType.values[(json['type'] as num?)?.toInt() ?? 1],
        amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
        categoryId: json['categoryId']?.toString(),
        paymentMethodId: json['paymentMethodId']?.toString(),
        toPaymentMethodId: json['toPaymentMethodId']?.toString(),
        notes: json['notes']?.toString() ?? '',
        items: (json['items'] as List? ?? [])
            .whereType<Map>()
            .map((e) => ItemEntry.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        billPaths: (json['billPaths'] as List? ?? [])
            .map((e) => e.toString())
            .toList(),
        date: DateTime.tryParse(json['date']?.toString() ?? '') ??
            DateTime.now(),
        isDeleted: json['isDeleted'] == true || json['isDeleted'] == 1,
      );
}
