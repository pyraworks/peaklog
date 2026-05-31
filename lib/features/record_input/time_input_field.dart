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
    _h = TextEditingController(text: h > 0 ? h.toString() : '');
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

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Field(controller: _h, hint: '0', label: '시간', maxLength: 2, onChanged: (_) => _notify()),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text(':', style: TextStyle(color: AppTheme.textPrimary, fontSize: 24, fontWeight: FontWeight.w700)),
        ),
        _Field(controller: _m, hint: '00', label: '분', maxLength: 2, onChanged: (_) => _notify()),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text(':', style: TextStyle(color: AppTheme.textPrimary, fontSize: 24, fontWeight: FontWeight.w700)),
        ),
        _Field(controller: _s, hint: '00', label: '초', maxLength: 2, onChanged: (_) => _notify()),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final String label;
  final int maxLength;
  final ValueChanged<String> onChanged;

  const _Field({
    required this.controller,
    required this.hint,
    required this.label,
    required this.maxLength,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w700),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(maxLength),
            ],
            decoration: InputDecoration(hintText: hint),
            onChanged: onChanged,
          ),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }
}
