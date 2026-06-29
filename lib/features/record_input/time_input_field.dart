import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';

class TimeInputField extends StatefulWidget {
  final ValueChanged<int> onChanged;
  final int initialSeconds;

  const TimeInputField({
    required this.onChanged,
    this.initialSeconds = 0,
    super.key,
  });

  @override
  State<TimeInputField> createState() => _TimeInputFieldState();
}

class _TimeInputFieldState extends State<TimeInputField> {
  late final TextEditingController _h;
  late final TextEditingController _m;
  late final TextEditingController _s;

  @override
  void initState() {
    super.initState();
    final total = widget.initialSeconds;
    final h = total ~/ 3600;
    final m = (total % 3600) ~/ 60;
    final s = total % 60;
    // Pre-populate all fields so every digit uses identical text style
    // (no hint-vs-text color mismatch).
    _h = TextEditingController(text: h.toString());
    _m = TextEditingController(text: m.toString().padLeft(2, '0'));
    _s = TextEditingController(text: s.toString().padLeft(2, '0'));
  }

  @override
  void dispose() {
    _h.dispose();
    _m.dispose();
    _s.dispose();
    super.dispose();
  }

  void _notify() {
    final h = int.tryParse(_h.text) ?? 0;
    final m = int.tryParse(_m.text) ?? 0;
    final s = int.tryParse(_s.text) ?? 0;
    widget.onChanged(h * 3600 + m * 60 + s);
  }

  static const _valueStyle = TextStyle(
    color: AppTheme.textPrimary,
    fontSize: 24,
    fontWeight: FontWeight.w700,
  );

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Field(controller: _h, label: 'h',   maxLength: 2, zeroText: '0',  onChanged: (_) => _notify()),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text(':', style: _valueStyle),
        ),
        _Field(controller: _m, label: 'min', maxLength: 2, zeroText: '00', onChanged: (_) => _notify()),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text(':', style: _valueStyle),
        ),
        _Field(controller: _s, label: 'sec', maxLength: 2, zeroText: '00', onChanged: (_) => _notify()),
      ],
    );
  }
}

class _Field extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final int maxLength;
  final String zeroText;
  final ValueChanged<String> onChanged;

  static const _valueStyle = TextStyle(
    color: AppTheme.textPrimary,
    fontSize: 24,
    fontWeight: FontWeight.w700,
  );

  const _Field({
    required this.controller,
    required this.label,
    required this.maxLength,
    required this.zeroText,
    required this.onChanged,
  });

  @override
  State<_Field> createState() => _FieldState();
}

class _FieldState extends State<_Field> {
  late final FocusNode _focus;

  @override
  void initState() {
    super.initState();
    _focus = FocusNode();
    _focus.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocusChange);
    _focus.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (_focus.hasFocus) {
      if (widget.controller.text == widget.zeroText) {
        widget.controller.clear();
        widget.onChanged('');
      }
    } else {
      if (widget.controller.text.isEmpty) {
        widget.controller.text = widget.zeroText;
        widget.onChanged(widget.zeroText);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          TextField(
            controller: widget.controller,
            focusNode: _focus,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: _Field._valueStyle,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(widget.maxLength),
            ],
            decoration: const InputDecoration(
              hintStyle: _Field._valueStyle,
            ),
            onChanged: widget.onChanged,
          ),
          const SizedBox(height: 4),
          Text(
            widget.label,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
