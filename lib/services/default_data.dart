import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/category_model.dart';
import '../models/payment_method_model.dart';

const _uuid = Uuid();

/// Default income categories (mirrors: Allowance, Bonus, Business,
/// Investment Income, Other Income, Pension, Salary).
List<CategoryModel> defaultIncomeCategories() {
  final defs = <List<dynamic>>[
    ['Allowance', Icons.volunteer_activism, 0xFFFFC107, 'assets/category_icons/allowance.png'],
    ['Bonus', Icons.card_giftcard, 0xFF4CAF50, 'assets/category_icons/bonus.png'],
    ['Business', Icons.business_center, 0xFF3F51B5, 'assets/category_icons/business.png'],
    ['Investment Income', Icons.trending_up, 0xFF2E7D32, 'assets/category_icons/investment_income.png'],
    ['Other Income', Icons.info, 0xFF2196F3, 'assets/category_icons/other_income.png'],
    ['Pension', Icons.account_balance, 0xFF9C27B0, 'assets/category_icons/pension.png'],
    ['Salary', Icons.payments, 0xFFFF9800, 'assets/category_icons/salary.png'],
    ['Scholarship', Icons.school, 0xFF00BCD4, null],
    ['Pocket Money', Icons.savings, 0xFFE91E63, null],
    ['Freelance', Icons.laptop_mac, 0xFF009688, null],
  ];
  return defs
      .map((d) => CategoryModel(
            id: _uuid.v4(),
            name: d[0],
            iconCodePoint: (d[1] as IconData).codePoint,
            colorValue: d[2],
            iconAsset: d[3],
            kind: CategoryKind.income,
          ))
      .toList();
}

/// Default expense categories (mirrors the large icon grid in the screenshots:
/// Air Tickets, Auto Rickshaw, Bike, Bills, Cable TV, Car, Car Insurance,
/// Card Fee, Cigarette, Clothes, Drinks, Driver, plus student-relevant extras).
List<CategoryModel> defaultExpenseCategories() {
  final defs = <List<dynamic>>[
    ['Air Tickets', Icons.flight, 0xFF03A9F4, 'assets/category_icons/air_tickets.png'],
    ['Food', Icons.restaurant, 0xFFFF7043, null],
    ['Fruits and Vegetables', Icons.eco, 0xFF8BC34A, null],
    ['Mobile', Icons.smartphone, 0xFF2196F3, null],
    ['Auto Rickshaw', Icons.airport_shuttle, 0xFFFF5722, 'assets/category_icons/auto_rickshaw.png'],
    ['Bike', Icons.two_wheeler, 0xFFF44336, 'assets/category_icons/bike.png'],
    ['Bills', Icons.receipt_long, 0xFF607D8B, 'assets/category_icons/bills.png'],
    ['Cable TV', Icons.tv, 0xFF3F51B5, 'assets/category_icons/cable_tv.png'],
    ['Car', Icons.directions_car, 0xFFFFC107, 'assets/category_icons/car.png'],
    ['Car Insurance', Icons.shield, 0xFF00BCD4, 'assets/category_icons/car_insurance.png'],
    ['Card Fee', Icons.credit_card, 0xFFFF9800, 'assets/category_icons/card_fee.png'],
    ['Cigarette', Icons.smoking_rooms, 0xFF795548, 'assets/category_icons/cigarette.png'],
    ['Clothes', Icons.checkroom, 0xFF3F51B5, 'assets/category_icons/clothes.png'],
    ['Drinks', Icons.local_bar, 0xFFE91E63, 'assets/category_icons/drinks.png'],
    ['Driver', Icons.airline_seat_recline_normal, 0xFF009688, 'assets/category_icons/driver.png'],
    ['Education', Icons.school, 0xFF3F51B5, null],
    ['Tuition Fees', Icons.menu_book, 0xFF9C27B0, null],
    ['Books & Supplies', Icons.book, 0xFFFF9800, null],
    ['Hostel / Rent', Icons.home, 0xFF9C27B0, null],
    ['Electricity', Icons.bolt, 0xFFFFEB3B, null],
    ['Water', Icons.water_drop, 0xFF2196F3, null],
    ['Internet', Icons.wifi, 0xFF00BCD4, null],
    ['Entertainment', Icons.movie, 0xFFE91E63, null],
    ['Health', Icons.local_hospital, 0xFFF44336, null],
    ['Transport', Icons.directions_bus, 0xFFFF5722, null],
    ['Groceries', Icons.local_grocery_store, 0xFF4CAF50, null],
    ['Laundry', Icons.local_laundry_service, 0xFF03A9F4, null],
    ['Gifts', Icons.card_giftcard, 0xFFE91E63, null],
    ['Savings', Icons.savings, 0xFF4CAF50, null],
    ['Other', Icons.category, 0xFF9E9E9E, null],
  ];
  return defs
      .map((d) => CategoryModel(
            id: _uuid.v4(),
            name: d[0],
            iconCodePoint: (d[1] as IconData).codePoint,
            colorValue: d[2],
            iconAsset: d[3],
            kind: CategoryKind.expense,
          ))
      .toList();
}

/// Default payment methods: Bank, Card, Cash, Others.
List<PaymentMethodModel> defaultPaymentMethods() {
  return ['Bank', 'Card', 'Cash', 'Others']
      .map((n) => PaymentMethodModel(id: _uuid.v4(), name: n))
      .toList();
}

/// Asset icons shown in the screenshot's custom-category picker.
List<String> categoryIconChoices() => const [
      'assets/category_icons/custom_01.png',
      'assets/category_icons/custom_02.png',
      'assets/category_icons/custom_03.png',
      'assets/category_icons/custom_04.png',
      'assets/category_icons/custom_05.png',
      'assets/category_icons/custom_06.png',
      'assets/category_icons/custom_07.png',
      'assets/category_icons/custom_08.png',
      'assets/category_icons/custom_09.png',
      'assets/category_icons/custom_10.png',
      'assets/category_icons/custom_11.png',
      'assets/category_icons/custom_12.png',
      'assets/category_icons/custom_13.png',
      'assets/category_icons/custom_14.png',
      'assets/category_icons/custom_15.png',
      'assets/category_icons/custom_16.png',
      'assets/category_icons/custom_17.png',
      'assets/category_icons/custom_18.png',
    ];
