import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/exercise.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/unit_converter.dart';
import '../../providers/records_provider.dart';
import '../../providers/unit_settings_provider.dart';

class OneRmPanel extends ConsumerStatefulWidget {
  final Exercise exercise;
  const OneRmPanel({required this.exercise, super.key});

  @override
  ConsumerState<OneRmPanel> createState() => _OneRmPanelState();
}

class _OneRmPanelState extends ConsumerState<OneRmPanel> {
  int _percent = 80;
  late final FixedExtentScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = FixedExtentScrollController(initialItem: _percent - 1);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final records =
        ref.watch(recordsProvider(widget.exercise.id!)).valueOrNull ?? [];
    final unit =
        ref.watch(unitSettingsProvider).valueOrNull?.weightUnit ?? 'kg';

    double? bestKg;
    if (records.isNotEmpty) {
      bestKg = records.map((r) => r.value).reduce((a, b) => a > b ? a : b);
    }

    final calculated = bestKg != null ? bestKg * (_percent / 100) : null;
    final displayCalc = calculated != null
        ? UnitConverter.formatWeight(calculated, unit)
        : '—';

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '1RM %',
                style: TextStyle(
                    color: AppTheme.accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5),
              ),
              if (bestKg != null)
                GestureDetector(
                  onTap: () => _showTable(context, bestKg!, unit),
                  child: const Text(
                    '표로 보기',
                    style: TextStyle(
                        color: AppTheme.accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: SizedBox(
                  height: 140,
                  child: CupertinoPicker(
                    scrollController: _scrollController,
                    itemExtent: 40,
                    backgroundColor: AppTheme.background,
                    selectionOverlay: Container(
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(
                              color: AppTheme.separator, width: 0.8),
                          bottom: BorderSide(
                              color: AppTheme.separator, width: 0.8),
                        ),
                      ),
                    ),
                    onSelectedItemChanged: (index) {
                      setState(() => _percent = index + 1);
                    },
                    children: List.generate(
                      120,
                      (i) => Center(
                        child: Text(
                          '${i + 1}%',
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppTheme.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppTheme.separator, width: 0.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$_percent%',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        displayCalc,
                        style: const TextStyle(
                          color: AppTheme.accent,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (bestKg == null)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                '기록을 먼저 추가해주세요',
                style: TextStyle(
                    color: AppTheme.textSecondary, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  void _showTable(BuildContext context, double bestKg, String unit) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _OneRmTableScreen(
          exerciseName: widget.exercise.name,
          bestKg: bestKg,
          unit: unit,
          currentPercent: _percent,
        ),
      ),
    );
  }
}

// ── 표 전체화면 ──────────────────────────────────────────────

class _OneRmTableScreen extends StatefulWidget {
  final String exerciseName;
  final double bestKg;
  final String unit;
  final int currentPercent;

  const _OneRmTableScreen({
    required this.exerciseName,
    required this.bestKg,
    required this.unit,
    required this.currentPercent,
  });

  @override
  State<_OneRmTableScreen> createState() => _OneRmTableScreenState();
}

class _OneRmTableScreenState extends State<_OneRmTableScreen> {
  static const double _rowHeight = 48;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    // 두 열 모두 60행이므로 나머지로 행 인덱스 계산
    final rowIndex = (widget.currentPercent - 1) % 60;
    final offset = (rowIndex * _rowHeight - 120).clamp(0.0, double.infinity);
    _scrollController = ScrollController(initialScrollOffset: offset);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.exerciseName} — 1RM 표'),
      ),
      body: Column(
        children: [
          // 헤더
          Container(
            color: AppTheme.background,
            child: Row(
              children: [
                Expanded(
                  child: _HeaderCell(
                      left: '1 — 60%',
                      right: UnitConverter.formatWeight(
                          widget.bestKg, widget.unit)),
                ),
                const VerticalDivider(
                    width: 1, thickness: 0.5, color: AppTheme.separator),
                Expanded(
                  child: _HeaderCell(
                      left: '61 — 120%',
                      right: UnitConverter.formatWeight(
                          widget.bestKg * 1.2, widget.unit)),
                ),
              ],
            ),
          ),
          const Divider(height: 0.5, thickness: 0.5, color: AppTheme.separator),
          // 데이터
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: 60,
              itemExtent: _rowHeight,
              itemBuilder: (_, i) {
                final leftPct = i + 1;
                final rightPct = i + 61;
                final leftW = UnitConverter.formatWeight(
                    widget.bestKg * (leftPct / 100), widget.unit);
                final rightW = UnitConverter.formatWeight(
                    widget.bestKg * (rightPct / 100), widget.unit);
                final leftSel = leftPct == widget.currentPercent;
                final rightSel = rightPct == widget.currentPercent;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: _TableCell(
                                percent: leftPct,
                                weight: leftW,
                                highlighted: leftSel),
                          ),
                          const VerticalDivider(
                              width: 1,
                              thickness: 0.5,
                              color: AppTheme.separator),
                          Expanded(
                            child: _TableCell(
                                percent: rightPct,
                                weight: rightW,
                                highlighted: rightSel),
                          ),
                        ],
                      ),
                    ),
                    const Divider(
                        height: 0.5,
                        thickness: 0.5,
                        color: AppTheme.separator),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String left;
  final String right;
  const _HeaderCell({required this.left, required this.right});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Text(left,
              style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
          const Spacer(),
          Text('(1RM: $right)',
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }
}

class _TableCell extends StatelessWidget {
  final int percent;
  final String weight;
  final bool highlighted;
  const _TableCell(
      {required this.percent,
      required this.weight,
      required this.highlighted});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: highlighted
          ? AppTheme.accent.withValues(alpha: 0.08)
          : Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              '$percent%',
              style: TextStyle(
                color: highlighted ? AppTheme.accent : AppTheme.textSecondary,
                fontSize: 13,
                fontWeight:
                    highlighted ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
          Expanded(
            child: Text(
              weight,
              style: TextStyle(
                color: highlighted ? AppTheme.accent : AppTheme.textPrimary,
                fontSize: 13,
                fontWeight:
                    highlighted ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
          if (highlighted)
            const Icon(Icons.check, color: AppTheme.accent, size: 13),
        ],
      ),
    );
  }
}
