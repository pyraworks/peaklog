import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peaklog/features/calendar/calendar_screen.dart';

// Regression coverage for a real overflow found during review: at the
// narrowest realistic Month View cell widths (320-375pt-wide devices, cell
// width = (deviceWidth - 32) / 7 for the existing card margin + grid
// padding), 4 category dots + the "+" overflow + the note indicator
// together needed more width than a fixed-width Row could give them
// without overflowing (confirmed 1-9px overflow before the fix). Fixed by
// switching CalendarCategoryDots from Row to Wrap, so excess content
// reflows onto a second centered line instead of overlapping or clipping.
//
// CalendarCategoryDots takes plain constructor parameters (no
// Riverpod/database dependency), so it can be pumped directly and
// constrained to realistic cell widths deterministically.
//
// Height is deliberately left unconstrained here (not pinned to a fixed
// SizedBox height): in the real _CalendarCell, CalendarCategoryDots is a
// plain (non-Expanded/Flexible) child of a Column with
// mainAxisSize.min, which gives it a *loose* height constraint — sizing to
// its own content, not to a fixed box. Pinning height in the test would
// force Wrap's *reported* size to that fixed value regardless of how much
// vertical space its content actually uses, which doesn't match the real
// constraint environment and would make the "stays on one line" /
// "fits within the cell" checks below meaningless.
void main() {
  // Card margin (8+8) + grid Padding(horizontal: 8)*2 = 32px removed from
  // the device width, split across 7 columns — same formula
  // calendar_screen.dart's own grid uses.
  double cellWidthFor(double deviceWidth) => (deviceWidth - 32) / 7;
  // Cell height (66) minus the day-number circle's own footprint
  // (SizedBox(7) + 32px circle) — the real vertical budget left for
  // CalendarCategoryDots before it would visually exceed the cell.
  const remainingCellHeight = 66.0 - 7.0 - 32.0;

  Future<void> pumpDots(
    WidgetTester tester, {
    required double cellWidth,
    required List<String> colorKeys,
    required bool hasNote,
  }) {
    return tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: cellWidth, // height intentionally omitted — see file doc comment
            child: CalendarCategoryDots(colorKeys: colorKeys, hasNote: hasNote),
          ),
        ),
      ),
    );
  }

  const deviceWidths = [320.0, 360.0, 375.0, 414.0];

  group('note-only (no categories)', () {
    for (final deviceWidth in deviceWidths) {
      testWidgets('renders without overflow at ${deviceWidth}pt', (tester) async {
        await pumpDots(
          tester,
          cellWidth: cellWidthFor(deviceWidth),
          colorKeys: const [],
          hasNote: true,
        );
        expect(tester.takeException(), isNull);
        expect(find.byType(Container), findsOneWidget,
            reason: 'exactly the one note indicator, no category dots');
      });
    }
  });

  group('1 category + note', () {
    for (final deviceWidth in deviceWidths) {
      testWidgets('renders without overflow at ${deviceWidth}pt', (tester) async {
        await pumpDots(
          tester,
          cellWidth: cellWidthFor(deviceWidth),
          colorKeys: const ['gold'],
          hasNote: true,
        );
        expect(tester.takeException(), isNull);
        expect(find.byType(Container), findsNWidgets(2)); // 1 dot + 1 note
        expect(find.text('+'), findsNothing);
      });
    }
  });

  group('4 categories + note (no overflow "+")', () {
    for (final deviceWidth in deviceWidths) {
      testWidgets('renders without overflow at ${deviceWidth}pt', (tester) async {
        await pumpDots(
          tester,
          cellWidth: cellWidthFor(deviceWidth),
          colorKeys: const ['crimson', 'rust', 'gold', 'teal'],
          hasNote: true,
        );
        expect(tester.takeException(), isNull);
        expect(find.byType(Container), findsNWidgets(5)); // 4 dots + 1 note
        expect(find.text('+'), findsNothing,
            reason: 'exactly 4 categories must not trigger overflow "+"');
      });
    }
  });

  group('5+ categories + note (existing "+" overflow still shown)', () {
    for (final deviceWidth in deviceWidths) {
      testWidgets('renders without overflow at ${deviceWidth}pt — the '
          'narrowest realistic width this was actually failing at before '
          'the Wrap fix', (tester) async {
        await pumpDots(
          tester,
          cellWidth: cellWidthFor(deviceWidth),
          colorKeys: const ['crimson', 'rust', 'gold', 'teal', 'ocean', 'olive'],
          hasNote: true,
        );
        expect(tester.takeException(), isNull);
        // Only the first 4 are shown as dots — existing max-4 behavior
        // must be unchanged even with a note also present.
        expect(find.byType(Container), findsNWidgets(5)); // 4 visible dots + 1 note
        expect(find.text('+'), findsOneWidget);
      });

      testWidgets(
          'the worst case (4 dots + overflow + note) never needs more than '
          'the cell\'s real vertical budget at ${deviceWidth}pt', (tester) async {
        await pumpDots(
          tester,
          cellWidth: cellWidthFor(deviceWidth),
          colorKeys: const ['crimson', 'rust', 'gold', 'teal', 'ocean'],
          hasNote: true,
        );
        expect(tester.takeException(), isNull);
        final size = tester.getSize(find.byType(Wrap));
        expect(size.width, lessThanOrEqualTo(cellWidthFor(deviceWidth)));
        expect(size.height, lessThanOrEqualTo(remainingCellHeight),
            reason: 'even when it must wrap to a second line at very '
                'narrow widths, it must still fit the cell\'s remaining '
                'vertical space, not just avoid a RenderFlex exception');
      });
    }
  });

  group('existing category-only behavior (no note) is unchanged', () {
    testWidgets('4 dots + overflow, no note, still renders on a single line '
        'at every realistic width tested', (tester) async {
      for (final deviceWidth in deviceWidths) {
        await pumpDots(
          tester,
          cellWidth: cellWidthFor(deviceWidth),
          colorKeys: const ['crimson', 'rust', 'gold', 'teal', 'ocean'],
          hasNote: false,
        );
        expect(tester.takeException(), isNull);
        final size = tester.getSize(find.byType(Wrap));
        expect(size.height, lessThanOrEqualTo(9.5),
            reason: 'must still fit on one line at ${deviceWidth}pt, '
                'matching pre-existing (pre-Note-indicator) behavior');
        expect(find.text('+'), findsOneWidget);
      }
    });

    testWidgets('a single category, no note, is unaffected', (tester) async {
      await pumpDots(
        tester,
        cellWidth: cellWidthFor(375.0),
        colorKeys: const ['gold'],
        hasNote: false,
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(Container), findsOneWidget);
    });
  });

  testWidgets(
      'the note indicator is visually distinguishable from category dots '
      '(square vs. circle) regardless of category color', (tester) async {
    await pumpDots(
      tester,
      cellWidth: cellWidthFor(375.0),
      colorKeys: const ['gold'],
      hasNote: true,
    );
    final containers = tester.widgetList<Container>(find.byType(Container)).toList();
    expect(containers, hasLength(2));
    final shapes = containers
        .map((c) => (c.decoration as BoxDecoration).shape)
        .toList();
    final borderRadii = containers
        .map((c) => (c.decoration as BoxDecoration).borderRadius)
        .toList();
    // One is a circle (the category dot), one is a rounded square (the note).
    expect(shapes, containsAll([BoxShape.circle]));
    expect(borderRadii.whereType<BorderRadius>(), isNotEmpty);
  });
}
