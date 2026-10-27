import 'package:intl/intl.dart';

class Formatters {
  Formatters._();

  static final NumberFormat _amount = NumberFormat('#,##0.##');
  static final DateFormat dateOnly = DateFormat('dd-MMM-yyyy');
  static final DateFormat dayDateMonthYear = DateFormat('EEE, dd MMM yyyy');
  static final DateFormat timeOnly = DateFormat('hh:mm a');
  static final DateFormat monthYear = DateFormat('MMMM yyyy');
  static final DateFormat dayMonth = DateFormat('dd MMM');

  static String amount(num value) => _amount.format(value);

  static String signedAmount(num value, {required bool positive}) =>
      '${positive ? '' : '-'}${_amount.format(value.abs())}';
}
