import 'package:flutter/material.dart';
import '../../core/design/app_colors.dart';
import '../../core/design/app_icons.dart';
import '../../core/design/app_spacing.dart';
import '../../core/design/app_typography.dart';
import '../../widgets/screen_header.dart';
import 'calculator_prefs.dart';
import 'pace_calculator_logic.dart';

class _Preset {
  final String label;
  final double km;
  const _Preset(this.label, this.km);
}

const _presets = [
  _Preset('1 km', 1.0),
  _Preset('2 km', 2.0),
  _Preset('3 km', 3.0),
  _Preset('5 km', 5.0),
  _Preset('10 km', 10.0),
  _Preset('Half', PaceCalculatorLogic.halfMarathonKm),
  _Preset('Marathon', PaceCalculatorLogic.marathonKm),
  _Preset('Custom', -1.0),
];

class PaceCalculatorScreen extends StatefulWidget {
  const PaceCalculatorScreen({super.key});

  @override
  State<PaceCalculatorScreen> createState() => _PaceCalculatorScreenState();
}

class _PaceCalculatorScreenState extends State<PaceCalculatorScreen> {
  final _timeCtrl = TextEditingController();
  final _paceCtrl = TextEditingController();
  final _customDistCtrl = TextEditingController();

  String _selectedPreset = '5 km';
  double _distanceKm = 5.0;
  String _lastEdited = ''; // 'time' or 'pace'
  bool _splitsExpanded = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final preset = await CalculatorPrefs.getPacePreset();
    final distKm = await CalculatorPrefs.getPaceDistanceKm();
    final timeText = await CalculatorPrefs.getPaceTimeText();
    final paceText = await CalculatorPrefs.getPacePaceText();
    final lastEdited = await CalculatorPrefs.getPaceLastEdited();
    if (!mounted) return;
    setState(() {
      _selectedPreset = preset;
      _distanceKm = distKm;
      if (_selectedPreset == 'Custom') {
        _customDistCtrl.text = distKm == distKm.roundToDouble()
            ? distKm.toInt().toString()
            : distKm.toStringAsFixed(2);
      }
      _timeCtrl.text = timeText;
      _paceCtrl.text = paceText;
      _lastEdited = lastEdited;
      _loaded = true;
    });
  }

  @override
  void dispose() {
    _timeCtrl.dispose();
    _paceCtrl.dispose();
    _customDistCtrl.dispose();
    super.dispose();
  }

  void _selectPreset(String label) {
    final preset = _presets.firstWhere((p) => p.label == label);
    setState(() {
      _selectedPreset = label;
      if (preset.km > 0) _distanceKm = preset.km;
    });
    CalculatorPrefs.setPacePreset(label);
    if (preset.km > 0) {
      CalculatorPrefs.setPaceDistanceKm(preset.km);
      _recompute();
    }
  }

  void _onCustomDistChanged(String val) {
    final d = double.tryParse(val);
    if (d != null && d > 0) {
      setState(() => _distanceKm = d);
      CalculatorPrefs.setPaceDistanceKm(d);
      _recompute();
    }
  }

  void _onTimeChanged(String val) {
    setState(() => _lastEdited = 'time');
    CalculatorPrefs.setPaceTimeText(val);
    CalculatorPrefs.setPaceLastEdited('time');
    _recompute();
  }

  void _onPaceChanged(String val) {
    setState(() => _lastEdited = 'pace');
    CalculatorPrefs.setPacePaceText(val);
    CalculatorPrefs.setPaceLastEdited('pace');
    _recompute();
  }

  void _recompute() {
    if (_lastEdited == 'time') {
      final secs = PaceCalculatorLogic.parseTimeOrPace(_timeCtrl.text);
      if (secs != null && _distanceKm > 0) {
        final pace = PaceCalculatorLogic.paceSecondsPerKm(
          distanceKm: _distanceKm,
          totalSeconds: secs,
        );
        if (pace != null) {
          final formatted = PaceCalculatorLogic.formatPace(pace);
          if (_paceCtrl.text != formatted) {
            _paceCtrl.text = formatted;
            CalculatorPrefs.setPacePaceText(formatted);
          }
        }
      }
    } else if (_lastEdited == 'pace') {
      final paceSec = PaceCalculatorLogic.parseTimeOrPace(_paceCtrl.text);
      if (paceSec != null && _distanceKm > 0) {
        final totalSec = PaceCalculatorLogic.totalSeconds(
          distanceKm: _distanceKm,
          paceSecondsPerKm: paceSec.toDouble(),
        );
        if (totalSec != null) {
          final formatted = PaceCalculatorLogic.formatTime(totalSec);
          if (_timeCtrl.text != formatted) {
            _timeCtrl.text = formatted;
            CalculatorPrefs.setPaceTimeText(formatted);
          }
        }
      }
    }
    setState(() {});
  }

  (double?, int?) get _computed {
    final paceSec = PaceCalculatorLogic.parseTimeOrPace(_paceCtrl.text);
    final timeSec = PaceCalculatorLogic.parseTimeOrPace(_timeCtrl.text);
    if (paceSec != null && timeSec != null) {
      return (paceSec.toDouble(), timeSec);
    }
    return (null, null);
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final (paceSecPerKm, totalSec) = _computed;
    final hasSplits = paceSecPerKm != null && paceSecPerKm > 0;
    final splits = hasSplits
        ? PaceCalculatorLogic.generateSplits(_distanceKm, paceSecPerKm)
        : <(String, int)>[];

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            const ScreenHeader(
                backLabel: 'Calculators', title: 'Pace Calculator'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s16,
                  vertical: AppSpacing.s24,
                ),
                children: [
                  // ── Distance presets ─────────────────────────────────
                  const _SectionLabel('DISTANCE'),
                  const SizedBox(height: AppSpacing.s8),
                  SizedBox(
                    height: 32,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _presets.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final p = _presets[i];
                        final active = _selectedPreset == p.label;
                        return GestureDetector(
                          onTap: () => _selectPreset(p.label),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: active
                                  ? AppColors.chipSelected
                                  : AppColors.chip,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              p.label,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: active
                                    ? Colors.white
                                    : AppColors.textPrimaryAlt,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  if (_selectedPreset == 'Custom') ...[
                    const SizedBox(height: AppSpacing.s8),
                    _InputCard(
                      label: 'CUSTOM DISTANCE',
                      child: TextField(
                        controller: _customDistCtrl,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        style: AppTypography.inputValue
                            .copyWith(color: AppColors.label1),
                        cursorColor: AppColors.label1,
                        decoration: InputDecoration(
                          hintText: '5.0',
                          hintStyle: AppTypography.inputValue
                              .copyWith(color: AppColors.label2),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          suffix: Text(
                            'km',
                            style: AppTypography.inputValue
                                .copyWith(color: AppColors.label2),
                          ),
                        ),
                        onChanged: _onCustomDistChanged,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.s16),

                  // ── Time input ────────────────────────────────────────
                  const _SectionLabel('TARGET TIME'),
                  const SizedBox(height: AppSpacing.s8),
                  _InputCard(
                    label: 'H:MM:SS or MM:SS',
                    child: TextField(
                      controller: _timeCtrl,
                      keyboardType: TextInputType.datetime,
                      style: AppTypography.inputValue
                          .copyWith(color: AppColors.label1),
                      cursorColor: AppColors.label1,
                      decoration: InputDecoration(
                        hintText: '20:00',
                        hintStyle: AppTypography.inputValue
                            .copyWith(color: AppColors.label2),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: _onTimeChanged,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s12),

                  // ── Pace input ────────────────────────────────────────
                  const _SectionLabel('TARGET PACE'),
                  const SizedBox(height: AppSpacing.s8),
                  _InputCard(
                    label: 'M:SS /km',
                    child: TextField(
                      controller: _paceCtrl,
                      keyboardType: TextInputType.datetime,
                      style: AppTypography.inputValue
                          .copyWith(color: AppColors.label1),
                      cursorColor: AppColors.label1,
                      decoration: InputDecoration(
                        hintText: '4:00',
                        hintStyle: AppTypography.inputValue
                            .copyWith(color: AppColors.label2),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        suffix: Text(
                          '/km',
                          style: AppTypography.inputValue
                              .copyWith(color: AppColors.label2),
                        ),
                      ),
                      onChanged: _onPaceChanged,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s24),

                  // ── Result cards ──────────────────────────────────────
                  if (paceSecPerKm != null || totalSec != null) ...[
                    Row(
                      children: [
                        Expanded(
                          child: _ResultCard(
                            label: 'PACE',
                            value: paceSecPerKm != null
                                ? '${PaceCalculatorLogic.formatPace(paceSecPerKm)} /km'
                                : '—',
                          ),
                        ),
                        const SizedBox(width: AppSpacing.s12),
                        Expanded(
                          child: _ResultCard(
                            label: 'TIME',
                            value: totalSec != null
                                ? PaceCalculatorLogic.formatTime(totalSec)
                                : '—',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.s24),
                  ],

                  // ── Split table ───────────────────────────────────────
                  if (hasSplits && splits.isNotEmpty) ...[
                    _SplitTable(
                      splits: splits,
                      expanded: _splitsExpanded,
                      onToggle: () =>
                          setState(() => _splitsExpanded = !_splitsExpanded),
                    ),
                    const SizedBox(height: AppSpacing.s24),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Text(
          text,
          style: AppTypography.sectionLabel.copyWith(color: AppColors.label2),
        ),
      );
}

class _InputCard extends StatelessWidget {
  final String label;
  final Widget child;
  const _InputCard({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Text(label,
              style:
                  AppTypography.inputLabel.copyWith(color: AppColors.label2)),
          const SizedBox(height: 4),
          child,
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final String label;
  final String value;
  const _ResultCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Text(label,
              style: AppTypography.sectionLabel
                  .copyWith(color: AppColors.label2)),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTypography.calcValue.copyWith(color: AppColors.label1),
          ),
        ],
      ),
    );
  }
}

class _SplitTable extends StatelessWidget {
  final List<(String, int)> splits;
  final bool expanded;
  final VoidCallback onToggle;

  const _SplitTable({
    required this.splits,
    required this.expanded,
    required this.onToggle,
  });

  (String, int)? get _hundredMSplit =>
      splits.where((s) => s.$1 == '100m').firstOrNull;

  (String, int)? get _collapsedSecondSplit {
    final km1 = splits.where((s) => s.$1 == '1km').firstOrNull;
    return km1 ?? splits.lastOrNull;
  }

  List<(String, int)> get _subKm =>
      splits.where((s) => s.$1.endsWith('m') && !s.$1.contains('km')).toList();

  List<(String, int)> get _kmPlus =>
      splits.where((s) => s.$1.contains('km')).toList();

  @override
  Widget build(BuildContext context) {
    final split100m = _hundredMSplit;
    final splitSecond = _collapsedSecondSplit;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.separator, width: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: [
          // Collapsed summary rows
          if (split100m != null)
            _SplitRow(
              label: '100m Split',
              time: PaceCalculatorLogic.formatTime(split100m.$2),
            ),
          if (split100m != null && splitSecond != null && splitSecond.$1 != '100m')
            const Divider(
                height: 1, thickness: 0.5, color: AppColors.separator),
          if (splitSecond != null && splitSecond.$1 != '100m')
            _SplitRow(
              label: splitSecond.$1 == '1km'
                  ? '1km Split'
                  : '${splitSecond.$1} Split',
              time: PaceCalculatorLogic.formatTime(splitSecond.$2),
            ),

          // Expanded detail
          if (expanded) ...[
            const Divider(
                height: 1, thickness: 0.5, color: AppColors.separator),
            ..._buildDetailRows(),
          ],

          // Toggle button
          const Divider(
              height: 1, thickness: 0.5, color: AppColors.separator),
          GestureDetector(
            onTap: onToggle,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s16, vertical: AppSpacing.s12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    expanded ? 'Hide Splits' : 'Show Detailed Splits',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.label2,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    expanded ? AppIcons.caretUp : AppIcons.caretDown,
                    size: 16,
                    color: AppColors.label2,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildDetailRows() {
    final rows = <Widget>[];
    final subKm = _subKm;
    final kmPlus = _kmPlus;

    for (int i = 0; i < subKm.length; i++) {
      if (i > 0) {
        rows.add(const Divider(
            height: 1, thickness: 0.5, color: AppColors.separator));
      }
      final s = subKm[i];
      rows.add(_SplitRow(
          label: s.$1, time: PaceCalculatorLogic.formatTime(s.$2)));
    }

    if (subKm.isNotEmpty && kmPlus.isNotEmpty) {
      rows.add(const Divider(
          height: 1, thickness: 1.5, color: AppColors.separatorAlt));
    }

    for (int i = 0; i < kmPlus.length; i++) {
      if (i > 0) {
        rows.add(const Divider(
            height: 1, thickness: 0.5, color: AppColors.separator));
      }
      final s = kmPlus[i];
      rows.add(_SplitRow(
          label: s.$1, time: PaceCalculatorLogic.formatTime(s.$2)));
    }

    return rows;
  }
}

class _SplitRow extends StatelessWidget {
  final String label;
  final String time;
  const _SplitRow({required this.label, required this.time});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s16, vertical: AppSpacing.s12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.label1,
            ),
          ),
          Text(
            time,
            style: AppTypography.tableCell.copyWith(color: AppColors.label1),
          ),
        ],
      ),
    );
  }
}
