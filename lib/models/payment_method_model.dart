class PaymentMethodModel {
  final String id;
  String name;
  final bool isCustom;

  PaymentMethodModel({
    required this.id,
    required this.name,
    this.isCustom = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'isCustom': isCustom,
      };

  factory PaymentMethodModel.fromJson(Map<String, dynamic> json) =>
      PaymentMethodModel(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? 'Cash',
        isCustom: json['isCustom'] == true || json['isCustom'] == 1,
      );
}
