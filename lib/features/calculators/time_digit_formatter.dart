import 'package:flutter/services.dart';
import 'pace_calculator_logic.dart';

/// Formats a stream of raw digit keypresses into M:SS or H:MM:SS display text.
///
/// Users type digits only; the formatter strips colons and re-formats on every
/// keystroke, so the colon is never typed manually. Backspace removes the
/// rightmost raw digit because colons are stripped before formatting.
class TimeDigitFormatter extends TextInputFormatter {
  const TimeDigitFormatter();

  static const int _maxDigits = 6;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final capped = digits.length > _maxDigits
        ? digits.substring(digits.length - _maxDigits)
        : digits;
    final formatted = PaceCalculatorLogic.formatRawDigits(capped);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
