import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/design/app_colors.dart';
import '../../core/design/app_icons.dart';
import '../../core/design/app_spacing.dart';
import '../../core/design/app_typography.dart';
import '../../core/utils/unit_converter.dart';
import '../../widgets/screen_header.dart';
import 'calculator_prefs.dart';

class OneRmCalculatorScreen extends StatefulWidget {
  const OneRmCalculatorScreen({super.key});

  @override
  State<OneRmCalculatorScreen> createState() => _OneRmCalculatorScreenState();
}

class _OneRmCalculatorScreenState extends State<OneRmCalculatorScreen> {
  static const _quickPcts = [70, 75, 80, 85, 90, 95];

  final _weightCtrl = TextEditingController();
  final _pctCtrl = TextEditingController(text: '85');
  String _unit = 'kg';
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final weight = await CalculatorPrefs.get1rmWeight();
    final unit = await CalculatorPrefs.get1rmUnit();
    if (!mounted) return;
    setState(() {
      _weightCtrl.text = _fmtInput(weight);
      _unit = unit;
      _loaded = true;
    });
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _pctCtrl.dispose();
    super.dispose();
  }

  String _fmtInput(double v) {
    final s = v.toStringAsFixed(1);
    return s.endsWith('.0') ? v.toInt().toString() : s;
  }

  double? get _weightKg {
    final raw = double.tryParse(_weightCtrl.text.trim());
    if (raw == null || raw <= 0) return null;
    return _unit == 'lbs' ? UnitConverter.lbsToKg(raw) : raw;
  }

  double? get _parsedPct {
    final v = double.tryParse(_pctCtrl.text.trim());
    if (v == null || v <= 0 || v > 200) return null;
    return v;
  }

  int? get _activeChip {
    final pct = _parsedPct;
    if (pct == null) return null;
    for (final q in _quickPcts) {
      if ((pct - q).abs() < 0.001) return q;
    }
    return null;
  }

  String _formatResult(double kg) {
    if (_unit == 'lbs') return UnitConverter.formatWeight(kg, 'lbs');
    final rounded = (kg * 10).round() / 10;
    return rounded == rounded.roundToDouble()
        ? '${rounded.toInt()} kg'
        : '${rounded.toStringAsFixed(1)} kg';
  }

  void _onUnitChanged(String newUnit) {
    if (newUnit == _unit) return;
    final raw = double.tryParse(_weightCtrl.text.trim());
    if (raw != null && raw > 0) {
      final converted = newUnit == 'lbs'
          ? UnitConverter.kgToLbs(raw)
          : UnitConverter.lbsToKg(raw);
      _weightCtrl.text = _fmtInput(converted);
      CalculatorPrefs.set1rmWeight(converted);
    }
    setState(() => _unit = newUnit);
    CalculatorPrefs.set1rmUnit(newUnit);
  }

  void _tapChip(int pct) {
    _pctCtrl.text = '$pct';
    _pctCtrl.selection =
        TextSelection.collapsed(offset: _pctCtrl.text.length);
    setState(() {});
  }

  void _saveAndNavigateTable() {
    final wKg = _weightKg;
    if (wKg == null) return;
    final displayWeight = _unit == 'lbs' ? UnitConverter.kgToLbs(wKg) : wKg;
    CalculatorPrefs.set1rmWeight(displayWeight);
    CalculatorPrefs.set1rmUnit(_unit);
    context.push(
      '/calculators/1rm-table',
      extra: <String, dynamic>{'weight': wKg, 'unit': _unit == 'lbs' ? 'lbs' : 'kg'},
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final wKg = _weightKg;
    final pct = _parsedPct;
    final resultKg = (wKg != null && pct != null) ? wKg * pct / 100 : null;
    final resultDisplay = resultKg != null ? _formatResult(resultKg) : '—';
    final activeChip = _activeChip;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            const ScreenHeader(backLabel: 'Calculators', title: '1RM Calculator'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s16,
                  vertical: AppSpacing.s24,
                ),
                children: [
                  // ── Weight input card ──────────────────────────────────
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: AppColors.separator, width: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s16,
                      vertical: AppSpacing.s12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '1RM WEIGHT',
                          style: AppTypography.sectionLabel
                              .copyWith(color: AppColors.label2),
                        ),
                        const SizedBox(height: AppSpacing.s12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _weightCtrl,
                                keyboardType: const TextInputType.numberWithOptions(
                                    decimal: true),
                                style: AppTypography.inputValue.copyWith(
                                  color: AppColors.label1,
                                ),
                                cursorColor: AppColors.label1,
                                cursorHeight: 20,
                                decoration: InputDecoration(
                                  hintText: '100',
                                  hintStyle: AppTypography.inputValue.copyWith(
                                    color: AppColors.label2,
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                onChanged: (_) {
                                  setState(() {});
                                  final w = double.tryParse(_weightCtrl.text.trim());
                                  if (w != null) {
                                    CalculatorPrefs.set1rmWeight(w);
                                    CalculatorPrefs.set1rmUnit(_unit);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: AppSpacing.s8),
                            _UnitToggle(
                              selected: _unit,
                              onTap: _onUnitChanged,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s16),

                  // ── Calculator card ────────────────────────────────────
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: AppColors.separator, width: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s16,
                      vertical: AppSpacing.s12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '1RM CALCULATOR',
                              style: AppTypography.sectionLabel
                                  .copyWith(color: AppColors.label2),
                            ),
                            GestureDetector(
                              onTap: wKg != null ? _saveAndNavigateTable : null,
                              behavior: HitTestBehavior.opaque,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(AppIcons.chart,
                                      size: 12,
                                      color: wKg != null
                                          ? AppColors.textTertiary
                                          : AppColors.disabled),
                                  const SizedBox(width: 4),
                                  Text(
                                    'View Table',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: wKg != null
                                          ? AppColors.textTertiary
                                          : AppColors.disabled,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.s16),

                        // % chips
                        Row(
                          children: _quickPcts.map((p) {
                            final active = p == activeChip;
                            final isLast = p == _quickPcts.last;
                            return Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(right: isLast ? 0 : 4),
                                child: GestureDetector(
                                  onTap: () => _tapChip(p),
                                  child: Container(
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: active
                                          ? AppColors.chipSelected
                                          : Colors.transparent,
                                      border: Border.all(
                                          color: AppColors.separator,
                                          width: 0.5),
                                      borderRadius: BorderRadius.circular(7),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '$p%',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: active
                                              ? Colors.white
                                              : AppColors.label2,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: AppSpacing.s12),

                        // % input + result
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Expanded(flex: 1, child: SizedBox()),
                            Expanded(
                              flex: 4,
                              child: Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 64,
                                      height: 30,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF3F4F6),
                                        borderRadius: BorderRadius.circular(7),
                                      ),
                                      clipBehavior: Clip.hardEdge,
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Expanded(
                                            child: TextField(
                                              controller: _pctCtrl,
                                              keyboardType:
                                                  const TextInputType
                                                      .numberWithOptions(
                                                      decimal: true),
                                              textAlign: TextAlign.right,
                                              textAlignVertical:
                                                  TextAlignVertical.center,
                                              cursorColor: AppColors.label1,
                                              cursorWidth: 1.5,
                                              cursorHeight: 14,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.label1,
                                              ),
                                              decoration:
                                                  const InputDecoration(
                                                border: InputBorder.none,
                                                enabledBorder: InputBorder.none,
                                                focusedBorder: InputBorder.none,
                                                filled: false,
                                                isDense: true,
                                                contentPadding:
                                                    EdgeInsets.symmetric(
                                                        horizontal: 6),
                                              ),
                                              onChanged: (_) => setState(() {}),
                                              onTap: () =>
                                                  _pctCtrl.selection =
                                                      TextSelection(
                                                baseOffset: 0,
                                                extentOffset:
                                                    _pctCtrl.text.length,
                                              ),
                                            ),
                                          ),
                                          const Padding(
                                            padding: EdgeInsets.only(
                                                left: 2, right: 7),
                                            child: Text(
                                              '%',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                                color: AppColors.label2,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      resultDisplay,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 30,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.label1,
                                        letterSpacing: -0.8,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const Expanded(flex: 1, child: SizedBox()),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Unit toggle (KG / LBS) ────────────────────────────────────────────────────

class _UnitToggle extends StatelessWidget {
  final String selected;
  final void Function(String) onTap;

  const _UnitToggle({required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.separator, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _UnitChip(
              label: 'kg',
              active: selected == 'kg',
              onTap: () => onTap('kg')),
          _UnitChip(
              label: 'lb',
              active: selected == 'lbs',
              onTap: () => onTap('lbs')),
        ],
      ),
    );
  }
}

class _UnitChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _UnitChip(
      {required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppColors.chipSelected : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: active ? Colors.white : AppColors.label2,
          ),
        ),
      ),
    );
  }
}
