import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peaklog/core/design/app_colors.dart';
import 'package:peaklog/domain/models/category.dart';
import 'package:peaklog/features/calendar/calendar_screen.dart';

// Regression coverage for the normal (non-capture) Month View legend's
// permanent Note entry. This is deliberately a *separate* piece of logic
// from the Month View capture legend (buildMonthShareShowNoteLegend in
// month_share_builder.dart) — the two must never be merged:
//   - normal Month View legend: Note entry is ALWAYS shown.
//   - capture legend: Note entry depends on hasAnyNotes/includeEmpty.
//
// buildCalendarLegendItems takes no note-presence or capture-toggle input
// at all — that absence is itself the guarantee that this legend can never
// be affected by either, verified below by calling it under a variety of
// category configurations and confirming the Note entry is present every
// time, unconditionally.
void main() {
  Category category({required String id, required String name, String color = 'gold'}) =>
      Category(id: id, name: name, color: color, sortOrder: 0, createdAt: 0, updatedAt: 0);

  group('buildCalendarLegendItems — Note entry is always present', () {
    test('with categories present, the Note entry is included, last, after '
        'every category', () {
      final items = buildCalendarLegendItems(
        categories: [category(id: 'c1', name: 'Strength'), category(id: 'c2', name: 'Cardio')],
        noteLegendLabel: 'Note',
      );
      expect(items.last.isNote, isTrue);
      expect(items.last.label, 'Note');
      expect(items.where((i) => i.isNote), hasLength(1));
    });

    test('with zero categories configured, the Note entry is still '
        'included — "no categories" must not mean "no legend at all"', () {
      final items = buildCalendarLegendItems(categories: const [], noteLegendLabel: 'Note');
      expect(items, hasLength(1));
      expect(items.single.isNote, isTrue);
    });

    test('with only Uncategorized configured (which is itself excluded), '
        'the Note entry is still included', () {
      final items = buildCalendarLegendItems(
        categories: [category(id: Category.uncategorizedId, name: 'Uncategorized')],
        noteLegendLabel: 'Note',
      );
      expect(items, hasLength(1));
      expect(items.single.isNote, isTrue);
    });

    test(
        'the function accepts no note-presence or capture-toggle input at '
        'all (only categories + the label to display) — the strongest '
        'possible guarantee that "month has notes" and the capture '
        '"Show categories without workout records" toggle can never affect '
        'this legend, unlike the separate capture-legend logic in '
        'month_share_builder.dart', () {
      // Calling it repeatedly with the exact same categories always
      // produces the exact same result — nothing external can vary it.
      final categories = [category(id: 'c1', name: 'Strength')];
      final a = buildCalendarLegendItems(categories: categories, noteLegendLabel: 'Note');
      final b = buildCalendarLegendItems(categories: categories, noteLegendLabel: 'Note');
      expect(a.map((i) => (i.label, i.isNote)).toList(), b.map((i) => (i.label, i.isNote)).toList());
      expect(a.last.isNote, isTrue);
      expect(b.last.isNote, isTrue);
    });
  });

  group('buildCalendarLegendItems — existing category behavior unchanged', () {
    test('Uncategorized is still excluded from category items', () {
      final items = buildCalendarLegendItems(
        categories: [
          category(id: Category.uncategorizedId, name: 'Uncategorized'),
          category(id: 'c1', name: 'Strength'),
        ],
        noteLegendLabel: 'Note',
      );
      // Just Strength + the Note entry — Uncategorized contributes nothing.
      expect(items.map((i) => i.label).toList(), ['Strength', 'Note']);
    });

    test('category color/name are reused verbatim, and Note is never '
        'inserted as if it were a category', () {
      final items = buildCalendarLegendItems(
        categories: [category(id: 'c1', name: 'Strength', color: 'ocean')],
        noteLegendLabel: 'Note',
      );
      final categoryItem = items.firstWhere((i) => !i.isNote);
      expect(categoryItem.label, 'Strength');
      expect(categoryItem.color, CategoryColor.toColor('ocean'));
      expect(categoryItem.isNote, isFalse);
      // The Note entry carries no category color at all.
      expect(items.firstWhere((i) => i.isNote).color, isNull);
    });

    test('the localized label passed in is used verbatim for the Note entry',
        () {
      final en = buildCalendarLegendItems(categories: const [], noteLegendLabel: 'Note');
      expect(en.single.label, 'Note');
      final ko = buildCalendarLegendItems(categories: const [], noteLegendLabel: '메모');
      expect(ko.single.label, '메모');
    });
  });

  group('CalendarLegendItem — same visual marker language as the date '
      'indicator (CalendarCategoryDots)', () {
    Future<Widget> pump(WidgetTester tester, CalendarLegendItem item) async {
      await tester.pumpWidget(
        Directionality(textDirection: TextDirection.ltr, child: item),
      );
      await tester.pump();
      return item;
    }

    testWidgets('the Note marker is a rounded square, not a circle', (tester) async {
      await pump(tester, const CalendarLegendItem(label: 'Note', isNote: true));
      final container = tester.widget<Container>(find.byType(Container));
      final decoration = container.decoration as BoxDecoration;
      // Exactly matches CalendarCategoryDots' note marker: 1.5-radius
      // rounded square, AppColors.label1 fill — never a circle, so it can
      // never be mistaken for a category dot regardless of color.
      expect(decoration.shape, BoxShape.rectangle);
      expect(decoration.borderRadius, BorderRadius.circular(1.5));
      expect(decoration.color, AppColors.label1);
      expect(container.constraints?.maxWidth ?? 5, 5);
    });

    testWidgets('a category marker is still a plain colored circle',
        (tester) async {
      await pump(
        tester,
        CalendarLegendItem(label: 'Strength', color: CategoryColor.toColor('gold')),
      );
      final container = tester.widget<Container>(find.byType(Container));
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.shape, BoxShape.circle);
      expect(decoration.color, CategoryColor.toColor('gold'));
    });

    testWidgets('the Note marker size matches the category dot size (5x5)',
        (tester) async {
      await pump(tester, const CalendarLegendItem(label: 'Note', isNote: true));
      final size = tester.getSize(find.byType(Container));
      expect(size, const Size(5, 5));
    });
  });
}
