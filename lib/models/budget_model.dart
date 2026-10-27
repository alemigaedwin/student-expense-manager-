enum BudgetPeriod { monthly, weekly, yearly }

class BudgetModel {
  final String id;
  final String accountId;
  String categoryId;
  double amount;
  BudgetPeriod period;
  DateTime periodStart; // first day of the month/week/year this budget applies to

  BudgetModel({
    required this.id,
    required this.accountId,
    required this.categoryId,
    required this.amount,
    required this.period,
    required this.periodStart,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'accountId': accountId,
        'categoryId': categoryId,
        'amount': amount,
        'period': period.index,
        'periodStart': periodStart.toIso8601String(),
      };

  factory BudgetModel.fromJson(Map<String, dynamic> json) => BudgetModel(
        id: json['id']?.toString() ?? '',
        accountId: json['accountId']?.toString() ?? 'default',
        categoryId: json['categoryId']?.toString() ?? '',
        amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
        period: BudgetPeriod.values[(json['period'] as num?)?.toInt() ?? 0],
        periodStart:
            DateTime.tryParse(json['periodStart']?.toString() ?? '') ??
                DateTime.now(),
      );
}

/// Overall (all-category) budget cap for a period, e.g. "Set Monthly Budget".
class OverallBudgetModel {
  final String id;
  final String accountId;
  double amount;
  BudgetPeriod period;
  DateTime periodStart;

  OverallBudgetModel({
    required this.id,
    required this.accountId,
    required this.amount,
    required this.period,
    required this.periodStart,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'accountId': accountId,
        'amount': amount,
        'period': period.index,
        'periodStart': periodStart.toIso8601String(),
      };

  factory OverallBudgetModel.fromJson(Map<String, dynamic> json) =>
      OverallBudgetModel(
        id: json['id']?.toString() ?? '',
        accountId: json['accountId']?.toString() ?? 'default',
        amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
        period: BudgetPeriod.values[(json['period'] as num?)?.toInt() ?? 0],
        periodStart:
            DateTime.tryParse(json['periodStart']?.toString() ?? '') ??
                DateTime.now(),
      );
}
