import 'transaction_model.dart';

enum RecurrenceType { once, daily, weekly, monthly, yearly }

class ReminderModel {
  final String id;
  final String accountId;
  String categoryId;
  String paymentMethodId;
  double amount;
  TransactionType type;
  RecurrenceType recurrence;
  DateTime nextDate;
  String notes;

  ReminderModel({
    required this.id,
    required this.accountId,
    required this.categoryId,
    required this.paymentMethodId,
    required this.amount,
    required this.type,
    required this.recurrence,
    required this.nextDate,
    this.notes = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'accountId': accountId,
        'categoryId': categoryId,
        'paymentMethodId': paymentMethodId,
        'amount': amount,
        'type': type.index,
        'recurrence': recurrence.index,
        'nextDate': nextDate.toIso8601String(),
        'notes': notes,
      };

  factory ReminderModel.fromJson(Map<String, dynamic> json) => ReminderModel(
        id: json['id']?.toString() ?? '',
        accountId: json['accountId']?.toString() ?? 'default',
        categoryId: json['categoryId']?.toString() ?? '',
        paymentMethodId: json['paymentMethodId']?.toString() ?? '',
        amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
        type: TransactionType.values[(json['type'] as num?)?.toInt() ?? 1],
        recurrence:
            RecurrenceType.values[(json['recurrence'] as num?)?.toInt() ?? 0],
        nextDate: DateTime.tryParse(json['nextDate']?.toString() ?? '') ??
            DateTime.now(),
        notes: json['notes']?.toString() ?? '',
      );
}
