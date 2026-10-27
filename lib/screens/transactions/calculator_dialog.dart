import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';

/// A small calculator matching the reference UI's amount-field calculator
/// shortcut. Lets the user type an expression like "500+250*2" and returns
/// the evaluated result to prefill the amount field.
class CalculatorDialog extends StatefulWidget {
  final String initialExpression;
  CalculatorDialog({super.key, this.initialExpression = ''});

  @override
  State<CalculatorDialog> createState() => _CalculatorDialogState();
}

class _CalculatorDialogState extends State<CalculatorDialog> {
  late String _expr;

  @override
  void initState() {
    super.initState();
    _expr = widget.initialExpression;
  }

  double? get _result => _evaluate(_expr);

  void _tap(String v) {
    setState(() {
      if (v == 'C') {
        _expr = '';
      } else if (v == '⌫') {
        if (_expr.isNotEmpty) _expr = _expr.substring(0, _expr.length - 1);
      } else if (v == '=') {
        final r = _result;
        if (r != null) _expr = _formatNum(r);
      } else {
        _expr += v;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                _expr.isEmpty ? '0' : _expr,
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w600),
              ),
            ),
            if (result != null && _expr.isNotEmpty)
              Align(
                alignment: Alignment.centerRight,
                child: Text('= ${_formatNum(result)}',
                    style: TextStyle(
                        color: AppColors.accent, fontSize: 14)),
              ),
            SizedBox(height: 12),
            Divider(color: AppColors.border),
            SizedBox(height: 8),
            _row(['7', '8', '9', '÷']),
            _row(['4', '5', '6', '×']),
            _row(['1', '2', '3', '-']),
            _row(['C', '0', '.', '+']),
            SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.border)),
                    onPressed: () => _tap('⌫'),
                    child: Icon(Icons.backspace_outlined,
                        color: AppColors.textPrimary, size: 18),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.border)),
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel',
                        style: TextStyle(color: AppColors.textPrimary)),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent),
                    onPressed: result == null
                        ? null
                        : () => Navigator.pop(context, result),
                    child: Text('Use',
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(List<String> keys) {
    return Row(
      children: keys
          .map((k) => Expanded(
                child: Padding(
                  padding: EdgeInsets.all(4),
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.border),
                      padding: EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () => _tap(
                        k == '÷' ? '/' : (k == '×' ? '*' : k)),
                    child: Text(k,
                        style: TextStyle(
                            color: AppColors.textPrimary, fontSize: 16)),
                  ),
                ),
              ))
          .toList(),
    );
  }

  String _formatNum(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  /// Tiny two-pass evaluator for +, -, *, / with standard precedence
  /// (no parentheses needed for this simple amount calculator).
  double? _evaluate(String expr) {
    if (expr.trim().isEmpty) return null;
    try {
      final tokens = <String>[];
      var num = '';
      for (final ch in expr.split('')) {
        if ('+-*/'.contains(ch)) {
          if (num.isEmpty) return null;
          tokens.add(num);
          tokens.add(ch);
          num = '';
        } else {
          num += ch;
        }
      }
      if (num.isEmpty) return null;
      tokens.add(num);

      // First pass: resolve * and /
      final pass1 = <String>[];
      var i = 0;
      pass1.add(double.parse(tokens[0]).toString());
      while (i + 2 < tokens.length) {
        final op = tokens[i + 1];
        final next = double.parse(tokens[i + 2]);
        if (op == '*' || op == '/') {
          final prev = double.parse(pass1.removeLast());
          pass1.add((op == '*' ? prev * next : prev / next).toString());
        } else {
          pass1.add(op);
          pass1.add(next.toString());
        }
        i += 2;
      }

      // Second pass: resolve + and -
      double result = double.parse(pass1[0]);
      for (var j = 1; j + 1 < pass1.length; j += 2) {
        final op = pass1[j];
        final v = double.parse(pass1[j + 1]);
        result = op == '+' ? result + v : result - v;
      }
      return result;
    } catch (_) {
      return null;
    }
  }
}
