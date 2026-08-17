import 'package:flutter_test/flutter_test.dart';
import 'package:peaklog/l10n/app_localizations_en.dart';
import 'package:peaklog/l10n/app_localizations_ko.dart';

/// Regression coverage for the Day View capture empty-state message.
/// `_captureDayImage` (calendar_screen.dart) shows this via a SnackBar when
/// there are no records for the captured date — it must be date-neutral
/// (not "this month", not "today"), and must be a separate key from
/// calendarNoRecords (which stays "no workouts this month" and is used by
/// the normal Month View header, the normal Day Detail records section,
/// and the Month View capture empty state — none of which this task
/// touches).
void main() {
  final en = AppLocalizationsEn();
  final ko = AppLocalizationsKo();

  test('English Day View capture empty-state wording is exactly '
      '"No workout records."', () {
    expect(en.calendarDayCaptureNoRecords, 'No workout records.');
  });

  test('Korean Day View capture empty-state wording is exactly '
      '"운동 기록이 없습니다"', () {
    expect(ko.calendarDayCaptureNoRecords, '운동 기록이 없습니다');
  });

  test('the message is date-neutral: no reference to "month" or "today" '
      'in either locale', () {
    expect(en.calendarDayCaptureNoRecords.toLowerCase(), isNot(contains('month')));
    expect(en.calendarDayCaptureNoRecords.toLowerCase(), isNot(contains('today')));
    expect(ko.calendarDayCaptureNoRecords, isNot(contains('달'))); // month
    expect(ko.calendarDayCaptureNoRecords, isNot(contains('오늘'))); // today
  });

  test('the new key is distinct from calendarNoRecords (Month View '
      'wording is unaffected) in both locales', () {
    expect(en.calendarDayCaptureNoRecords, isNot(equals(en.calendarNoRecords)));
    expect(ko.calendarDayCaptureNoRecords, isNot(equals(ko.calendarNoRecords)));
    expect(en.calendarNoRecords, 'No workouts this month');
    expect(ko.calendarNoRecords, '이번 달 운동 기록이 없습니다');
  });
}
