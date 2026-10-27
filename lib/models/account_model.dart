class AccountModel {
  final String id;
  String name;

  AccountModel({required this.id, required this.name});

  Map<String, dynamic> toJson() => {'id': id, 'name': name};

  factory AccountModel.fromJson(Map<String, dynamic> json) =>
      AccountModel(
        id: json['id']?.toString() ?? 'default',
        name: json['name']?.toString() ?? 'Income Expense',
      );
}
