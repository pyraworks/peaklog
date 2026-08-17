import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peaklog/core/design/app_typography.dart';
import 'package:peaklog/core/theme/app_theme.dart';

/// Regression coverage for the system-typography migration: PeakLog must
/// never select a named application font — Flutter/platform font
/// resolution is the only source of truth. These are deterministic
/// source/object-level checks (never pixel/golden comparisons, which
/// would be fragile and can't actually prove "no font was selected"
/// anyway).
void main() {
  group('AppTypography — no forced font family (Calendar/Notes/Records/'
      'Exercises/Settings/dialogs/buttons all route through these)', () {
    // Every named constant AppTypography exposes, kept as an explicit list
    // (rather than reflection) so a newly added style is exercised too —
    // if someone adds a 20th constant and forgets this list, that's the
    // one gap a reviewer should notice, not a silent skip.
    final styles = <String, TextStyle>{
      'appTitle': AppTypography.appTitle,
      'pageTitle': AppTypography.pageTitle,
      'headline': AppTypography.headline,
      'body': AppTypography.body,
      'cardTitle': AppTypography.cardTitle,
      'footnote': AppTypography.footnote,
      'pbValue': AppTypography.pbValue,
      'cardValue': AppTypography.cardValue,
      'calcValue': AppTypography.calcValue,
      'shareValue': AppTypography.shareValue,
      'inputValue': AppTypography.inputValue,
      'sectionLabel': AppTypography.sectionLabel,
      'inputLabel': AppTypography.inputLabel,
      'caption': AppTypography.caption,
      'button': AppTypography.button,
      'buttonLarge': AppTypography.buttonLarge,
      'badge': AppTypography.badge,
      'tableCell': AppTypography.tableCell,
      'tablePct': AppTypography.tablePct,
    };

    for (final entry in styles.entries) {
      test('AppTypography.${entry.key} does not select a named font',
          () {
        expect(entry.value.fontFamily, isNull);
        expect(entry.value.fontFamilyFallback, isNull);
      });
    }

    test('sanity: this list is not stale — matches the number of '
        'constants actually defined in app_typography.dart', () {
      final source =
          File('lib/core/design/app_typography.dart').readAsStringSync();
      final definedCount =
          RegExp(r'static const \w+ = TextStyle').allMatches(source).length;
      expect(styles.length, definedCount,
          reason: 'a constant was added to/removed from AppTypography '
              'without updating this test list');
    });
  });

  group('AppTheme.light — global theme does not force a named font', () {
    final theme = AppTheme.light;

    test('ThemeData(...) is not given an explicit fontFamily/textTheme '
        'override', () {
      // Deliberately NOT asserting theme.textTheme.bodyMedium?.fontFamily
      // is null: Flutter's own Typography.material2021 legitimately
      // names a platform-appropriate baseline font for its untouched
      // default roles (e.g. 'Roboto' under the test harness's Android
      // target) — that's Flutter/platform font resolution doing exactly
      // its job, not PeakLog selecting a font. What PeakLog controls is
      // whether AppTheme.light's own ThemeData(...) call passes a
      // fontFamily/textTheme override on top of that default — it must
      // not.
      final source = File('lib/core/theme/app_theme.dart').readAsStringSync();
      final start = source.indexOf('final base = ThemeData(');
      final end = source.indexOf('return base.copyWith(');
      expect(start, greaterThanOrEqualTo(0));
      expect(end, greaterThan(start));
      final themeDataCall = source.substring(start, end);
      expect(themeDataCall.contains('fontFamily'), isFalse);
      expect(themeDataCall.contains('textTheme'), isFalse);
    });

    test('AppBarTheme.titleTextStyle (nav/header titles) does not select '
        'a font', () {
      expect(theme.appBarTheme.titleTextStyle?.fontFamily, isNull);
    });

    test('DialogTheme title/content styles do not select a font '
        '(delegates to AppTypography.headline/body)', () {
      expect(theme.dialogTheme.titleTextStyle?.fontFamily, isNull);
      expect(theme.dialogTheme.contentTextStyle?.fontFamily, isNull);
    });

    test('InputDecorationTheme label/hint styles do not select a font',
        () {
      expect(theme.inputDecorationTheme.labelStyle?.fontFamily, isNull);
      expect(theme.inputDecorationTheme.hintStyle?.fontFamily, isNull);
    });

    test('ElevatedButtonTheme text style does not select a font', () {
      expect(
        theme.elevatedButtonTheme.style?.textStyle
            ?.resolve(<WidgetState>{})
            ?.fontFamily,
        isNull,
      );
    });
  });

  group('no CupertinoThemeData exists that could force a separate font',
      () {
    test('no production file constructs CupertinoThemeData', () {
      final matches = <String>[];
      for (final entity in Directory('lib').listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        if (entity.readAsStringSync().contains('CupertinoThemeData(')) {
          matches.add(entity.path);
        }
      }
      expect(matches, isEmpty,
          reason: 'Cupertino dialogs/sheets rely on the default '
              'MaterialBasedCupertinoThemeData derived from AppTheme.light '
              '— an explicit CupertinoThemeData here would be a second, '
              'independent font-selection path');
    });
  });

  group('Canvas/CustomPainter text rendering does not select a named font '
      '(generated calendar captures and ExportScreen share images)', () {
    // A string-literal fontFamily assignment (fontFamily: 'X') is a real
    // font selection. `fontFamily: icon.fontFamily` (seen in the two
    // share painters, for painting an icon glyph like the PB trophy) is
    // not — it passes through the icon's own required glyph font, not an
    // app text-font choice, so the check only flags quoted literals.
    final literalFontFamily = RegExp(r"fontFamily\s*:\s*'");

    for (final path in [
      'lib/features/export/frame_painter.dart',
      'lib/features/export/clean_frame.dart',
      'lib/features/export/rough_frame.dart',
      'lib/features/calendar/share/day_share_painter.dart',
      'lib/features/calendar/share/month_share_painter.dart',
    ]) {
      test(path, () {
        final source = File(path).readAsStringSync();
        expect(literalFontFamily.hasMatch(source), isFalse,
            reason: '$path must not select a named font for its '
                'Canvas/TextPainter-rendered text');
      });
    }
  });

  group('Note input and Note display continue to use the same '
      'typography source (AppTypography), not a divergent hardcoded '
      'style', () {
    final source =
        File('lib/features/calendar/calendar_screen.dart').readAsStringSync();

    test('the Note Edit input field style comes from AppTypography.body',
        () {
      // _buildField's TextField.style / hintStyle.
      expect(
        source.contains(
            'style: AppTypography.body.copyWith(color: AppColors.label1)'),
        isTrue,
      );
      expect(
        source.contains(
            'hintStyle: AppTypography.body.copyWith(color: AppColors.label3)'),
        isTrue,
      );
    });

    test('the saved Note display (_NoteCard) title/body styles come from '
        'AppTypography, matching the input field\'s architecture', () {
      expect(source.contains('style: AppTypography.cardTitle'), isTrue);
      expect(source.contains('style: AppTypography.footnote.copyWith'),
          isTrue);
    });
  });

  test('no bundled font asset remains declared in pubspec.yaml', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec.contains('fonts:'), isFalse);
    expect(pubspec.contains('Pretendard'), isFalse);
  });

  test('no bundled font files remain under assets/', () {
    expect(Directory('assets/fonts').existsSync(), isFalse);
  });
}
