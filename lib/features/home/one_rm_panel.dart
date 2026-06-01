import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/exercise.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/unit_converter.dart';
import '../../providers/records_provider.dart';
import '../../providers/unit_settings_provider.dart';

// 범위: 50% ~ 120% (71항목)
const int _kMinPercent = 50;
const int _kMaxPercent = 120;

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
    _scrollController =
        FixedExtentScrollController(initialItem: _percent - _kMinPercent);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final records =
        ref.watch(recordsProvider(widget.exercise.id)).valueOrNull ?? [];
    final unit =
        ref.watch(unitSettingsProvider).valueOrNull?.weightUnit ?? 'kg';

    double? bestKg;
    final oneReps = records
        .where((r) => r.weight != null && (r.reps == null || r.reps == 1))
        .toList();
    if (oneReps.isNotEmpty) {
      bestKg = oneReps.map((r) => r.weight!).reduce((a, b) => a > b ? a : b);
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더 행
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '1RM 계산기',
                  style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600),
                ),
                if (bestKg != null)
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => _showTable(context, bestKg!, unit),
                    child: const Text(
                      '표로 보기',
                      style: TextStyle(
                          color: AppTheme.accent,
                          fontSize: 13,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 6, 0, 8),
            child: SizedBox(
              height: 130,
              child: CupertinoPicker(
                scrollController: _scrollController,
                itemExtent: 38,
                backgroundColor: AppTheme.card,
                selectionOverlay: Container(
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(
                          color: AppTheme.separator, width: 0.5),
                      bottom: BorderSide(
                          color: AppTheme.separator, width: 0.5),
                    ),
                  ),
                ),
                onSelectedItemChanged: (index) {
                  setState(() => _percent = index + _kMinPercent);
                },
                children: List.generate(
                  _kMaxPercent - _kMinPercent + 1,
                  (i) {
                    final pct = i + _kMinPercent;
                    final wt = bestKg != null
                        ? UnitConverter.formatWeight(
                            bestKg * (pct / 100), unit)
                        : '—';
                    return Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '$pct%',
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 17,
                            ),
                          ),
                          Text(
                            wt,
                            style: TextStyle(
                              color: bestKg != null
                                  ? AppTheme.accent
                                  : AppTheme.textSecondary,
                              fontSize: 17,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
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
          exerciseName: widget.exercise.displayName,
          bestKg: bestKg,
          unit: unit,
          currentPercent: _percent,
        ),
      ),
    );
  }
}

// ── 표 전체화면 (50~120%, 2열) ───────────────────────────────

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
  // 왼쪽: 50-84% (35항목), 오른쪽: 85-120% (36항목) → 36행
  static const int _totalRows = 36;
  static const double _rowHeight = 46;

  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    final cp = widget.currentPercent;
    int rowIndex;
    if (cp >= 50 && cp <= 84) {
      rowIndex = cp - 50;
    } else if (cp >= 85 && cp <= 120) {
      rowIndex = cp - 85;
    } else {
      rowIndex = 0;
    }
    final offset =
        (rowIndex * _rowHeight - 140).clamp(0.0, double.infinity);
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
          // 컬럼 헤더
          Container(
            color: AppTheme.background,
            child: Row(
              children: [
                Expanded(child: _columnHeader('50 — 84%')),
                const VerticalDivider(
                    width: 1, thickness: 0.5, color: AppTheme.separator),
                Expanded(child: _columnHeader('85 — 120%')),
              ],
            ),
          ),
          const Divider(
              height: 0.5, thickness: 0.5, color: AppTheme.separator),
          // 데이터
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _totalRows,
              itemExtent: _rowHeight,
              itemBuilder: (_, i) {
                final leftPct = (i < 35) ? 50 + i : null;
                final rightPct = 85 + i; // 85..120

                final leftW = leftPct != null
                    ? UnitConverter.formatWeight(
                        widget.bestKg * (leftPct / 100), widget.unit)
                    : null;
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
                            child: leftPct != null
                                ? _TableCell(
                                    percent: leftPct,
                                    weight: leftW!,
                                    highlighted: leftSel)
                                : const SizedBox(),
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

  Widget _columnHeader(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        label,
        style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500),
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
            width: 38,
            child: Text(
              '$percent%',
              style: TextStyle(
                color: highlighted
                    ? AppTheme.accent
                    : AppTheme.textSecondary,
                fontSize: 13,
                fontWeight:
                    highlighted ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
          Expanded(
            child: Text(
              weight,
              style: TextStyle(
                color: highlighted
                    ? AppTheme.accent
                    : AppTheme.textPrimary,
                fontSize: 13,
                fontWeight:
                    highlighted ? FontWeight.w600 : FontWeight.w400,
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
