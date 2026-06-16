import 'package:flutter/material.dart';
import '../../core/design/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/design/app_typography.dart';
import '../../core/utils/unit_converter.dart';
import '../../providers/exercises_provider.dart';
import '../../providers/personal_best_provider.dart';
import '../../widgets/screen_header.dart';

class OneRMTableScreen extends ConsumerWidget {
  final String? exerciseId;
  final double? directWeightKg;
  final String? directWeightUnit;

  const OneRMTableScreen({
    this.exerciseId,
    this.directWeightKg,
    this.directWeightUnit,
    super.key,
  }) : assert(
          exerciseId != null || directWeightKg != null,
          'Either exerciseId or directWeightKg must be provided',
        );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    double? pbKg = directWeightKg;
    String weightUnit = directWeightUnit ?? 'kg';
    String title = '1RM Table';

    if (exerciseId != null) {
      final pb = ref.watch(personalBestProvider(exerciseId!));
      final exercises = ref.watch(exercisesProvider).valueOrNull ?? [];
      final exercise =
          exercises.where((e) => e.id == exerciseId).firstOrNull;
      weightUnit = exercise?.baseUnit ?? 'kg';
      title = exercise != null
          ? '${exercise.displayName} — 1RM Table'
          : '1RM Table';
      pbKg = pb?.weight;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          ScreenHeader(backLabel: 'Back', title: title),
          Expanded(
            child: pbKg == null
                ? const Center(
                    child: Text(
                      '1RM 기록이 없습니다',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6E7781),
                      ),
                    ),
                  )
                : _TableBody(pbKg: pbKg, weightUnit: weightUnit),
          ),
        ],
      ),
    );
  }
}

class _TableBody extends StatelessWidget {
  final double pbKg;
  final String weightUnit;
  const _TableBody({required this.pbKg, required this.weightUnit});

  String _fmt(int pct) =>
      UnitConverter.formatWeight(pbKg * pct / 100, weightUnit);

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.separator, width: 0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          clipBehavior: Clip.hardEdge,
          child: Column(children: _buildRows()),
        ),
      ],
    );
  }

  List<Widget> _buildRows() {
    final rows = <Widget>[];

    // 120→101%
    for (int left = 120; left >= 102; left -= 2) {
      if (rows.isNotEmpty) rows.add(const _RowDivider());
      rows.add(_PairRow(
        leftPct: left,   leftValue: _fmt(left),
        rightPct: left - 1, rightValue: _fmt(left - 1),
      ));
    }

    // 100% — special row
    rows.add(const _RowDivider());
    rows.add(_HundredRow(pbValue: _fmt(100)));

    // 99→50%
    for (int left = 99; left >= 51; left -= 2) {
      rows.add(const _RowDivider());
      rows.add(_PairRow(
        leftPct: left,   leftValue: _fmt(left),
        rightPct: left - 1, rightValue: _fmt(left - 1),
      ));
    }

    return rows;
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 0, thickness: 0.5, color: AppColors.separator);
  }
}

class _PairRow extends StatelessWidget {
  final int leftPct;
  final String leftValue;
  final int rightPct;
  final String rightValue;
  const _PairRow({
    required this.leftPct,
    required this.leftValue,
    required this.rightPct,
    required this.rightValue,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: Row(
        children: [
          Expanded(child: _Cell(pct: leftPct, value: leftValue)),
          Container(width: 0.5, color: AppColors.separator),
          Expanded(child: _Cell(pct: rightPct, value: rightValue)),
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  final int pct;
  final String value;
  const _Cell({required this.pct, required this.value});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 32,
            child: Text(
              '$pct%',
              textAlign: TextAlign.right,
              style: AppTypography.tablePct.copyWith(
                color: const Color(0xFF6E7781),
              ),
            ),
          ),
          const SizedBox(width: 14),
          SizedBox(
            width: 68,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: AppTypography.tableCell.copyWith(
                color: AppColors.label1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HundredRow extends StatelessWidget {
  final String pbValue;
  const _HundredRow({required this.pbValue});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: Stack(
        children: [
          Container(color: const Color(0xFFF8F9FA)),
          Row(
            children: [
              Expanded(child: _Cell(pct: 100, value: pbValue)),
              const Expanded(
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('🏆', style: TextStyle(fontSize: 12)),
                      SizedBox(width: 4),
                      Text(
                        'Current 1RM',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFFB8860B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const Center(
            child: Text(
              '—',
              style: TextStyle(fontSize: 12, color: AppColors.separator),
            ),
          ),
        ],
      ),
    );
  }
}
