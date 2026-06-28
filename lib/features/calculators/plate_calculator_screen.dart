import 'package:flutter/material.dart';
import '../../core/design/app_colors.dart';
import '../../core/design/app_spacing.dart';
import '../../core/design/app_typography.dart';
import '../../widgets/screen_header.dart';
import 'calculator_prefs.dart';
import 'plate_calculator_logic.dart';

class PlateCalculatorScreen extends StatefulWidget {
  const PlateCalculatorScreen({super.key});

  @override
  State<PlateCalculatorScreen> createState() => _PlateCalculatorScreenState();
}

class _PlateCalculatorScreenState extends State<PlateCalculatorScreen> {
  final _totalCtrl = TextEditingController();

  String _unit = 'kg';
  double _barWeight = 20.0;
  Map<double, int> _counts = {};
  bool _loaded = false;

  List<double> get _plateSizes =>
      _unit == 'kg' ? PlateCalculatorLogic.kgPlates : PlateCalculatorLogic.lbPlates;

  List<double> get _barOptions =>
      _unit == 'kg' ? PlateCalculatorLogic.kgBars : PlateCalculatorLogic.lbBars;

  String get _unitLabel => _unit == 'kg' ? 'kg' : 'lb';

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final unit = await CalculatorPrefs.getPlateUnit();
    final barWeight = await CalculatorPrefs.getPlateBarWeight();
    final totalWeight = await CalculatorPrefs.getPlateTotalWeight();
    final savedCounts = await CalculatorPrefs.getPlateCounts(unit);

    if (!mounted) return;
    setState(() {
      _unit = unit;
      _barWeight = barWeight;
      final sizes = unit == 'kg'
          ? PlateCalculatorLogic.kgPlates
          : PlateCalculatorLogic.lbPlates;
      _counts = {
        for (final s in sizes) s: savedCounts[s] ?? 0,
      };
      _totalCtrl.text = _fmtWeight(totalWeight);
      _loaded = true;
    });
  }

  @override
  void dispose() {
    _totalCtrl.dispose();
    super.dispose();
  }

  String _fmtWeight(double v) {
    final s = v.toStringAsFixed(1);
    return s.endsWith('.0') ? v.toInt().toString() : s;
  }

  void _onTotalChanged(String raw) {
    final target = double.tryParse(raw);
    if (target == null || target <= 0) return;
    final solved = PlateCalculatorLogic.solvePlates(
      totalWeightTarget: target,
      barWeight: _barWeight,
      plateSizes: _plateSizes,
    );
    setState(() {
      _counts = {for (final s in _plateSizes) s: solved[s] ?? 0};
    });
    CalculatorPrefs.setPlateTotalWeight(target);
    CalculatorPrefs.setPlateCounts(_unit, _counts);
  }

  void _adjustCount(double plate, int delta) {
    final current = _counts[plate] ?? 0;
    final next = (current + delta).clamp(0, 40);
    final evenNext = next % 2 == 0 ? next : (next - 1).clamp(0, 40);
    setState(() {
      _counts[plate] = evenNext;
    });
    final total = PlateCalculatorLogic.computeTotal(
      barWeight: _barWeight,
      plateCounts: _counts,
    );
    _totalCtrl.text = _fmtWeight(total);
    CalculatorPrefs.setPlateTotalWeight(total);
    CalculatorPrefs.setPlateCounts(_unit, _counts);
  }

  void _resetPlates() {
    setState(() {
      _counts = {for (final s in _plateSizes) s: 0};
      _totalCtrl.text = _fmtWeight(_barWeight);
    });
    CalculatorPrefs.setPlateTotalWeight(_barWeight);
    CalculatorPrefs.setPlateCounts(_unit, _counts);
  }

  void _selectBar(double weight) {
    setState(() => _barWeight = weight);
    CalculatorPrefs.setPlateBarWeight(weight);
    final total = PlateCalculatorLogic.computeTotal(
      barWeight: weight,
      plateCounts: _counts,
    );
    _totalCtrl.text = _fmtWeight(total);
    CalculatorPrefs.setPlateTotalWeight(total);
  }

  void _switchUnit(String newUnit) {
    if (newUnit == _unit) return;
    CalculatorPrefs.setPlateUnit(newUnit);
    final newBar = newUnit == 'kg' ? 20.0 : 45.0;
    final newSizes = newUnit == 'kg'
        ? PlateCalculatorLogic.kgPlates
        : PlateCalculatorLogic.lbPlates;
    setState(() {
      _unit = newUnit;
      _barWeight = newBar;
      _counts = {for (final s in newSizes) s: 0};
      _totalCtrl.text = _fmtWeight(newBar);
    });
    CalculatorPrefs.setPlateBarWeight(newBar);
    CalculatorPrefs.setPlateTotalWeight(newBar);
    CalculatorPrefs.setPlateCounts(newUnit, _counts);
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            const ScreenHeader(
                backLabel: 'Calculators', title: 'Plate Calculator'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s16,
                  vertical: AppSpacing.s24,
                ),
                children: [
                  // ── Unit toggle ────────────────────────────────────
                  Center(
                    child: _KgLbToggle(
                      selected: _unit,
                      onTap: _switchUnit,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s16),

                  // ── Total Weight input ─────────────────────────────
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: AppColors.separator, width: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.s16, vertical: AppSpacing.s12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TOTAL WEIGHT',
                          style: AppTypography.sectionLabel
                              .copyWith(color: AppColors.label2),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 80,
                              child: TextField(
                                controller: _totalCtrl,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),

                                style: AppTypography.inputValue
                                    .copyWith(color: AppColors.label1),
                                cursorColor: AppColors.label1,
                                cursorHeight: 20,
                                decoration: InputDecoration(
                                  hintText: '100',
                                  hintStyle: AppTypography.inputValue
                                      .copyWith(color: AppColors.label2),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                onChanged: _onTotalChanged,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _unitLabel,
                              style: AppTypography.inputValue
                                  .copyWith(color: AppColors.label1),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s16),

                  // ── Bar selector ───────────────────────────────────
                  Text(
                    'BAR',
                    style: AppTypography.sectionLabel
                        .copyWith(color: AppColors.label2),
                  ),
                  const SizedBox(height: AppSpacing.s8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      ..._barOptions.map((w) {
                        final active = (w - _barWeight).abs() < 0.01;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => _selectBar(w),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(
                                color: active
                                    ? AppColors.chipSelected
                                    : AppColors.chip,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                '${_fmtWeight(w)} $_unitLabel',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: active
                                      ? Colors.white
                                      : AppColors.textPrimaryAlt,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                      const Spacer(),
                      GestureDetector(
                        onTap: _resetPlates,
                        child: const Text(
                          'Reset',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.label2,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s16),

                  // ── Plate rows ─────────────────────────────────────
                  Text(
                    'PLATES',
                    style: AppTypography.sectionLabel
                        .copyWith(color: AppColors.label2),
                  ),
                  const SizedBox(height: AppSpacing.s8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: AppColors.separator, width: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: Column(
                      children: _plateSizes.asMap().entries.map((entry) {
                        final i = entry.key;
                        final plate = entry.value;
                        final count = _counts[plate] ?? 0;
                        return Column(
                          children: [
                            if (i > 0)
                              const Divider(
                                  height: 1,
                                  thickness: 0.5,
                                  color: AppColors.separator),
                            _PlateRow(
                              plate: plate,
                              unitLabel: _unitLabel,
                              count: count,
                              onMinus:
                                  count > 0 ? () => _adjustCount(plate, -2) : null,
                              onPlus: () => _adjustCount(plate, 2),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── KG / LB toggle ────────────────────────────────────────────────────────────

class _KgLbToggle extends StatelessWidget {
  final String selected;
  final void Function(String) onTap;

  const _KgLbToggle({required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.chip,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Tab(label: 'kg', active: selected == 'kg', onTap: () => onTap('kg')),
          _Tab(label: 'lb', active: selected == 'lb', onTap: () => onTap('lb')),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _Tab({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: active ? AppColors.label1 : AppColors.label2,
          ),
        ),
      ),
    );
  }
}

// ── Plate row ─────────────────────────────────────────────────────────────────

class _PlateRow extends StatelessWidget {
  final double plate;
  final String unitLabel;
  final int count;
  final VoidCallback? onMinus;
  final VoidCallback onPlus;

  const _PlateRow({
    required this.plate,
    required this.unitLabel,
    required this.count,
    required this.onMinus,
    required this.onPlus,
  });

  String _fmt(double v) {
    if (v == v.truncateToDouble()) return v.toInt().toString();
    final s = v.toStringAsFixed(2);
    return s.endsWith('0') ? v.toStringAsFixed(1) : s;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s16, vertical: AppSpacing.s12),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            child: Text(
              '${_fmt(plate)} $unitLabel',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.label1,
              ),
            ),
          ),
          const Spacer(),
          _StepButton(
            icon: '−',
            enabled: onMinus != null,
            onTap: onMinus,
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 28,
            child: Text(
              '$count',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.label1,
              ),
            ),
          ),
          const SizedBox(width: 12),
          _StepButton(icon: '+', enabled: true, onTap: onPlus),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final String icon;
  final bool enabled;
  final VoidCallback? onTap;

  const _StepButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: enabled ? AppColors.surface : AppColors.chip,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.separator, width: 0.5),
        ),
        child: Center(
          child: Text(
            icon,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w400,
              color: enabled ? AppColors.label1 : AppColors.disabled,
            ),
          ),
        ),
      ),
    );
  }
}
