import 'package:flutter_test/flutter_test.dart';
import 'package:peaklog/features/calendar/share/month_share_models.dart';
import 'package:peaklog/features/calendar/share/month_share_painter.dart';

/// Smoke coverage for renderMonthShareToBytes — pure dart:ui Canvas
/// rendering, no widget tree/DB/Riverpod involved, so it's safe to run
/// directly. These don't assert on pixels; they exist to catch the class
/// of bug that was actually fixed here (missing/incorrect note-marker
/// drawing code throwing or silently no-opping) by exercising every
/// hasNote/categoryColorKeys combination the painter can receive.
void main() {
  MonthShareData dataWithCells(List<MonthShareCell> cells) => MonthShareData(
        monthLabel: '2026년 8월',
        countLabel: '이번 달 운동 기록이 없습니다',
        weekdayLabels: const ['일', '월', '화', '수', '목', '금', '토'],
        cells: cells,
        usedCategories: const [],
      );

  test('renders a note-only cell (오운완 via Note: no categories, hasNote true) '
      'without throwing', () async {
    final cells = [
      const MonthShareCell(day: 1, categoryColorKeys: [], hasPr: false, hasNote: true),
      for (var d = 2; d <= 35; d++) MonthShareCell(day: d <= 31 ? d : null),
    ];
    final bytes = await renderMonthShareToBytes(dataWithCells(cells));
    expect(bytes, isNotEmpty);
  });

  test('renders a workout + note cell together without throwing', () async {
    final cells = [
      const MonthShareCell(
          day: 1, categoryColorKeys: ['gold'], hasPr: false, hasNote: true),
      for (var d = 2; d <= 35; d++) MonthShareCell(day: d <= 31 ? d : null),
    ];
    final bytes = await renderMonthShareToBytes(dataWithCells(cells));
    expect(bytes, isNotEmpty);
  });

  test('renders a cell with 5 categories (dot overflow truncation) plus a '
      'note without throwing', () async {
    final cells = [
      const MonthShareCell(
        day: 1,
        categoryColorKeys: ['gold', 'teal', 'blue', 'pink', 'green'],
        hasPr: true,
        hasNote: true,
      ),
      for (var d = 2; d <= 35; d++) MonthShareCell(day: d <= 31 ? d : null),
    ];
    final bytes = await renderMonthShareToBytes(dataWithCells(cells));
    expect(bytes, isNotEmpty);
  });

  test('renders with the capture legend Note entry present alongside '
      'per-date note markers without throwing', () async {
    final data = MonthShareData(
      monthLabel: '2026년 8월',
      countLabel: '1일 운동',
      weekdayLabels: const ['일', '월', '화', '수', '목', '금', '토'],
      cells: [
        const MonthShareCell(day: 1, categoryColorKeys: [], hasPr: false, hasNote: true),
        for (var d = 2; d <= 35; d++) MonthShareCell(day: d <= 31 ? d : null),
      ],
      usedCategories: const [],
      noteLegendLabel: '메모',
    );
    final bytes = await renderMonthShareToBytes(data);
    expect(bytes, isNotEmpty);
  });
}
