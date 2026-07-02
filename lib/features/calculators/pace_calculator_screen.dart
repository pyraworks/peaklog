import 'package:flutter/material.dart';
import '../../core/design/app_colors.dart';
import '../../core/design/app_icons.dart';
import '../../core/design/app_spacing.dart';
import '../../core/design/app_typography.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/screen_header.dart';
import 'calculator_prefs.dart';
import 'pace_calculator_logic.dart';

class PaceCalculatorScreen extends StatefulWidget {
  const PaceCalculatorScreen({super.key});

  @override
  State<PaceCalculatorScreen> createState() => _PaceCalculatorScreenState();
}

class _PaceCalculatorScreenState extends State<PaceCalculatorScreen> {
  final _distCtrl = TextEditingController();
  final _timeCtrl = TextEditingController();
  final _paceCtrl = TextEditingController();
  final _timeFocus = FocusNode();
  final _paceFocus = FocusNode();

  double _distanceKm = 0.0;
  String _lastEdited = '';
  bool _splitsExpanded = false;

  @override
  void initState() {
    super.initState();
    _timeFocus.addListener(_onTimeFocusChange);
    _paceFocus.addListener(_onPaceFocusChange);
  }

  @override
  void dispose() {
    _timeFocus.removeListener(_onTimeFocusChange);
    _paceFocus.removeListener(_onPaceFocusChange);
    _timeFocus.dispose();
    _paceFocus.dispose();
    _distCtrl.dispose();
    _timeCtrl.dispose();
    _paceCtrl.dispose();
    super.dispose();
  }

  void _onTimeFocusChange() {
    if (!_timeFocus.hasFocus) _formatAndRecompute(_timeCtrl, lastEdited: 'time');
  }

  void _onPaceFocusChange() {
    if (!_paceFocus.hasFocus) _formatAndRecompute(_paceCtrl, lastEdited: 'pace');
  }

  void _formatAndRecompute(TextEditingController ctrl, {required String lastEdited}) {
    final raw = ctrl.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (raw.isEmpty) return;
    final capped = raw.length > 6 ? raw.substring(raw.length - 6) : raw;
    final formatted = PaceCalculatorLogic.formatRawDigits(capped);
    if (ctrl.text != formatted) {
      ctrl.text = formatted;
      if (lastEdited == 'time') {
        CalculatorPrefs.setPaceTimeText(formatted);
      } else {
        CalculatorPrefs.setPacePaceText(formatted);
      }
    }
    _lastEdited = lastEdited;
    _recompute();
  }

  void _onDistChanged(String val) {
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
    final l10n = AppLocalizations.of(context)!;
    final (paceSecPerKm, _) = _computed;
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
            ScreenHeader(
                backLabel: l10n.calculatorsTitle, title: l10n.paceCalculatorTitle),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s16,
                  vertical: AppSpacing.s24,
                ),
                children: [
                  // ── Distance input ────────────────────────────────────
                  _InputCard(
                    label: 'DISTANCE',
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 140,
                          child: TextField(
                            controller: _distCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            style: AppTypography.inputValue
                                .copyWith(color: AppColors.label1),
                            cursorColor: AppColors.label1,
                            cursorHeight: 22,
                            decoration: InputDecoration(
                              hintText: '5',
                              hintStyle: AppTypography.inputValue
                                  .copyWith(color: AppColors.label2),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            onChanged: _onDistChanged,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'km',
                          style: AppTypography.inputValue
                              .copyWith(color: AppColors.label1),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s12),

                  // ── Time input ────────────────────────────────────────
                  _InputCard(
                    label: l10n.timeLabel,
                    child: SizedBox(
                      width: 140,
                      child: TextField(
                        controller: _timeCtrl,
                        focusNode: _timeFocus,
                        keyboardType: TextInputType.number,
                        style: AppTypography.inputValue
                            .copyWith(color: AppColors.label1),
                        cursorColor: AppColors.label1,
                        cursorHeight: 22,
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
                  ),
                  const SizedBox(height: AppSpacing.s12),

                  // ── Pace input ────────────────────────────────────────
                  _InputCard(
                    label: l10n.paceLabel,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 120,
                          child: TextField(
                            controller: _paceCtrl,
                            focusNode: _paceFocus,
                            keyboardType: TextInputType.number,
                            style: AppTypography.inputValue
                                .copyWith(color: AppColors.label1),
                            cursorColor: AppColors.label1,
                            cursorHeight: 22,
                            decoration: InputDecoration(
                              hintText: '4:00',
                              hintStyle: AppTypography.inputValue
                                  .copyWith(color: AppColors.label2),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            onChanged: _onPaceChanged,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '/km',
                          style: AppTypography.inputValue
                              .copyWith(color: AppColors.label1),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s24),

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

// ── Split table ───────────────────────────────────────────────────────────────
// Flat split list. Shows first 10 rows; "More ▼" / "Hide ▲" for longer lists.

class _SplitTable extends StatelessWidget {
  final List<(String, int)> splits;
  final bool expanded;
  final VoidCallback onToggle;

  static const _previewCount = 10;

  const _SplitTable({
    required this.splits,
    required this.expanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final showToggle = splits.length > _previewCount;
    final visibleSplits =
        (expanded || !showToggle) ? splits : splits.sublist(0, _previewCount);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.separator, width: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: [
          for (int i = 0; i < visibleSplits.length; i++) ...[
            if (i > 0)
              const Divider(
                  height: 1, thickness: 0.5, color: AppColors.separator),
            _SplitRow(
              label: visibleSplits[i].$1,
              time: PaceCalculatorLogic.formatTime(visibleSplits[i].$2),
            ),
          ],
          if (showToggle) ...[
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
                      expanded
                          ? AppLocalizations.of(context)!.hideLabel
                          : AppLocalizations.of(context)!.moreLabel,
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
        ],
      ),
    );
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
