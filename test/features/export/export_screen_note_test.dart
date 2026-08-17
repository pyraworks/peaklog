import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peaklog/core/models/exercise.dart';
import 'package:peaklog/core/models/note.dart';
import 'package:peaklog/core/services/analytics_service.dart';
import 'package:peaklog/features/export/export_screen.dart';
import 'package:peaklog/l10n/app_localizations.dart';
import 'package:peaklog/providers/analytics_provider.dart';
import 'package:peaklog/providers/unit_settings_provider.dart';
import 'package:share_plus_platform_interface/share_plus_platform_interface.dart';

/// Verifies the actual production requirement — Note sharing reuses the
/// EXISTING visual share/customization screen (ExportScreen) and its
/// existing final SharePlus pipeline, rather than a Note-specific editor
/// or a plain OS text-share call. NoteEditSheet's side of this boundary
/// (that it navigates to '/share/note' with the persisted Note, and never
/// calls SharePlus directly) is covered in
/// test/features/calendar/calendar_note_share_test.dart; this file covers
/// what's on the other end of that route: does ExportScreen actually
/// render and share Note content correctly, using the same widgets and
/// pipeline Exercise/Activity mode already used.
class _FakeUnitSettingsNotifier extends UnitSettingsNotifier {
  @override
  Future<UnitSettings> build() async => const UnitSettings();
}

class _FakeSharePlatform extends SharePlatform {
  final List<ShareParams> calls = [];

  @override
  Future<ShareResult> share(ShareParams params) async {
    calls.add(params);
    return const ShareResult('', ShareResultStatus.success);
  }
}

class _FakeAnalyticsService extends AnalyticsService {
  int shareUsedCount = 0;

  @override
  Future<void> logShareUsed() async {
    shareUsedCount++;
  }
}

const _pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');

void main() {
  final fakeShare = _FakeSharePlatform();
  SharePlatform.instance = fakeShare;

  late Directory tempDir;

  setUp(() {
    fakeShare.calls.clear();
    tempDir = Directory.systemTemp.createTempSync('export_screen_note_test');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_pathProviderChannel, (call) async {
      if (call.method == 'getTemporaryDirectory') return tempDir.path;
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_pathProviderChannel, null);
    tempDir.deleteSync(recursive: true);
  });

  Future<_FakeAnalyticsService> pumpExportScreen(
    WidgetTester tester, {
    Note? note,
    Exercise? exercise,
    double? newValue,
    DateTime? date,
  }) async {
    final analytics = _FakeAnalyticsService();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          unitSettingsProvider.overrideWith(() => _FakeUnitSettingsNotifier()),
          analyticsProvider.overrideWithValue(analytics),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ExportScreen(
            note: note,
            exercise: exercise,
            newValue: newValue,
            date: date,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return analytics;
  }

  Note note({
    String title = 'My Note Title',
    String body = 'My note body content.',
    int performedOn = 1700000000000,
  }) =>
      Note.create(performedOn: performedOn, title: title, body: body);

  Exercise exercise() => const Exercise(
        id: 'ex1',
        displayName: 'Back Squat',
        normalizedName: 'back squat',
        recordType: RecordType.weight,
        baseUnit: 'kg',
        createdAt: 0,
        updatedAt: 0,
      );

  AppLocalizations l10nOf(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(ExportScreen)))!;

  // The "Share" label also appears in ScreenHeader's title — .last always
  // targets the action button, which is built after the header.
  Finder shareActionButton(WidgetTester tester) =>
      find.text(l10nOf(tester).share).last;

  group('ExportScreen — Note mode reuses the existing visual editor', () {
    testWidgets('renders the Note title/body — not a PR badge or numeric '
        'achievement value', (tester) async {
      await pumpExportScreen(tester, note: note(title: 'Hi', body: 'World'));

      expect(find.text('HI'), findsOneWidget); // titleText, uppercased by CleanFrame
      expect(find.text('World'), findsOneWidget); // valueText verbatim
      expect(find.textContaining('NEW '), findsNothing); // no "NEW {badge}"
      expect(find.text('Personal Best'), findsNothing); // no PR badge label
    });

    testWidgets('the same customization controls used for workout sharing '
        'are present for Note sharing (frame style, aspect ratio, '
        'background media, Save Image/Share actions)', (tester) async {
      await pumpExportScreen(tester, note: note());
      final l10n = l10nOf(tester);

      expect(find.text(l10n.exportLabelRatio), findsOneWidget);
      expect(find.text(l10n.exportLabelFrame), findsOneWidget);
      expect(find.text(l10n.exportLabelBackground), findsOneWidget);
      expect(find.text(l10n.saveImage), findsOneWidget);
      expect(shareActionButton(tester), findsOneWidget);
    });

    testWidgets('tapping Share invokes the existing SharePlus pipeline '
        'exactly once, with an image file and the Note-date subject line',
        (tester) async {
      final analytics = await pumpExportScreen(tester, note: note());

      // runAsync lets the real dart:ui canvas rendering and real disk
      // I/O inside _share() actually complete — the fake test clock
      // pump() advances doesn't drive those. Not pumpAndSettle either:
      // _share() shows an indeterminate CircularProgressIndicator while
      // exporting, which animates forever and would make it time out.
      await tester.runAsync(() async {
        await tester.tap(shareActionButton(tester));
        await tester.pump();
        for (var i = 0; i < 50 && fakeShare.calls.isEmpty; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 20));
          await tester.pump();
        }
      });

      expect(fakeShare.calls, hasLength(1));
      expect(fakeShare.calls.single.files, isNotNull);
      expect(fakeShare.calls.single.files, hasLength(1));
      expect(fakeShare.calls.single.subject, contains('PeakLog'));
      // Same final analytics call workout sharing already makes — logged
      // exactly once (not duplicated by NoteEditSheet, which no longer
      // calls it itself).
      expect(analytics.shareUsedCount, 1);
    });
  });

  group('ExportScreen — Exercise mode is unaffected (regression)', () {
    testWidgets('still renders the PR badge/name/value for an Exercise, '
        'through the same widget this Note mode now also uses',
        (tester) async {
      await pumpExportScreen(
        tester,
        exercise: exercise(),
        newValue: 100,
        date: DateTime(2026, 1, 1),
      );

      expect(find.text('BACK SQUAT'), findsOneWidget);
      expect(find.textContaining('NEW '), findsOneWidget);
      expect(find.text('Personal Best'), findsOneWidget);
    });

    testWidgets('sharing an Exercise still uses the existing SharePlus '
        'pipeline with the exercise-name/PR subject line', (tester) async {
      await pumpExportScreen(
        tester,
        exercise: exercise(),
        newValue: 100,
        date: DateTime(2026, 1, 1),
      );

      await tester.runAsync(() async {
        await tester.tap(shareActionButton(tester));
        await tester.pump();
        for (var i = 0; i < 50 && fakeShare.calls.isEmpty; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 20));
          await tester.pump();
        }
      });

      expect(fakeShare.calls, hasLength(1));
      expect(fakeShare.calls.single.subject, contains('Back Squat'));
    });
  });
}
