import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peaklog/core/design/app_colors.dart';
import 'package:peaklog/features/calendar/calendar_screen.dart';

// CalendarDateCellStyle.resolve is a pure function extracted from
// _CalendarCell (private, and only reachable by rendering the full
// CalendarScreen, which requires DB-backed providers) specifically so the
// today-indicator logic can be verified deterministically, without
// widget-tree rendering or database access — see calendar_screen.dart's
// class doc comment.
void main() {
  group('CalendarDateCellStyle.resolve', () {
    test('a normal date (not today, not selected, in month) is unchanged: '
        'plain text, no fill, no border', () {
      final style = CalendarDateCellStyle.resolve(
        isSelected: false,
        isOutOfMonth: false,
        isToday: false,
      );
      expect(style.textColor, AppColors.label1);
      expect(style.fillColor, isNull);
      expect(style.borderColor, isNull);
    });

    test('today, unselected: black outline, no fill, and — critically — no '
        'red text treatment', () {
      final style = CalendarDateCellStyle.resolve(
        isSelected: false,
        isOutOfMonth: false,
        isToday: true,
      );
      expect(style.textColor, AppColors.label1,
          reason: 'must not use AppColors.todayAccent (red) anymore');
      expect(style.fillColor, isNull,
          reason: 'unselected today must not use the filled-selection style');
      expect(style.borderColor, isNotNull,
          reason: 'unselected today shows an outline');
      expect(style.borderColor, AppColors.actionDark);
    });

    test('today, selected: existing filled black circle style is preserved',
        () {
      final style = CalendarDateCellStyle.resolve(
        isSelected: true,
        isOutOfMonth: false,
        isToday: true,
      );
      expect(style.textColor, Colors.white);
      expect(style.fillColor, AppColors.actionDark);
      // Selection takes precedence: no separate outline drawn underneath.
      expect(style.borderColor, isNull);
    });

    test('a non-today date, selected: existing filled black circle style, '
        'same as today selected', () {
      final style = CalendarDateCellStyle.resolve(
        isSelected: true,
        isOutOfMonth: false,
        isToday: false,
      );
      expect(style.textColor, Colors.white);
      expect(style.fillColor, AppColors.actionDark);
    });

    test('an out-of-month date is unchanged regardless of today/selected',
        () {
      final plain = CalendarDateCellStyle.resolve(
        isSelected: false,
        isOutOfMonth: true,
        isToday: false,
      );
      expect(plain.textColor, AppColors.label5);
      expect(plain.fillColor, isNull);
      expect(plain.borderColor, isNull);

      // isOutOfMonth cells are never actually isToday/isSelected in
      // practice (calendar_screen.dart guards both with `!isOut`), but the
      // style resolver itself still shouldn't apply today/selected styling
      // if it were ever called that way.
      final withTodayFlag = CalendarDateCellStyle.resolve(
        isSelected: false,
        isOutOfMonth: true,
        isToday: true,
      );
      expect(withTodayFlag.textColor, AppColors.label5);
      expect(withTodayFlag.borderColor, isNull);
    });
  });
}
