import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:peaklog/core/models/note.dart';
import 'package:peaklog/features/calendar/calendar_screen.dart';
import 'package:peaklog/l10n/app_localizations.dart';
import 'package:peaklog/providers/notes_provider.dart';

/// Call history shared across every `_FakeNotesNotifier` instance created
/// for one test. Riverpod's autoDispose family providers may recreate the
/// notifier (calling the override's `create` factory again) whenever the
/// provider is re-read after its listener count drops to zero — which
/// happens here between Save taps, since NoteEditSheet only ever `ref
/// .read`s the notifier transactionally and never `watch`es it. Recording
/// into a fake tied 1:1 to a single notifier *instance* would break the
/// moment Riverpod recreated it (worse, reusing the very same instance
/// object across recreations throws — see the doc on `_FakeNotesNotifier`
/// below); a recorder that outlives any one instance keeps the call
/// history correct regardless of how many times Riverpod rebuilds it.
class _NotesRecorder {
  final List<Note> addedNotes = [];
  final List<Note> updatedNotes = [];
  /// When true, the next updateNote() call throws instead of succeeding —
  /// used to verify Save-failure behavior (Section 2 of the spec) without
  /// touching real persistence.
  bool failNextUpdate = false;
}

/// Records calls instead of touching the DB — NotesNotifier normally calls
/// through to NoteRepositoryImpl.instance (real sqflite), which this test
/// suite avoids entirely by overriding notesProvider with this fake. That
/// keeps these tests fast/deterministic and focused purely on the Note
/// Edit popup's own Save/Share state machine (NoteShareAvailability) and
/// its use of the real Save/Share code paths — not on Note persistence,
/// which is already covered elsewhere (calendar_month_provider_test.dart).
///
/// A NEW instance must be constructed by the override's `create` factory
/// every time Riverpod calls it (mirroring production's `NotesNotifier
/// .new` constructor tear-off) — reusing one captured instance across
/// multiple `create()` calls throws a LateInitializationError the second
/// time Riverpod tries to attach it to a (new) provider element.
class _FakeNotesNotifier extends NotesNotifier {
  _FakeNotesNotifier(this._recorder);
  final _NotesRecorder _recorder;

  @override
  Future<List<Note>> build(int notePerformedOn) async => const [];

  @override
  Future<void> addNote({required String title, required String body}) async {
    _recorder.addedNotes
        .add(Note.create(performedOn: arg, title: title, body: body));
  }

  @override
  Future<void> updateNote(Note note) async {
    if (_recorder.failNextUpdate) {
      _recorder.failNextUpdate = false;
      throw Exception('simulated save failure');
    }
    _recorder.updatedNotes.add(note);
  }

  @override
  Future<void> deleteNote(String id) async {}
}

/// Records every `extra` a '/share/note' navigation carried, without
/// pumping the real (heavily-dependent) ExportScreen — see
/// export_screen_note_test.dart for that. This is "the smallest
/// deterministic navigation abstraction that proves the Note enters the
/// existing visual share route": same path app.dart registers
/// ExportScreen's Note mode under, same `extra` contract.
class _ShareNavRecorder {
  final List<Object?> extras = [];
}

void main() {
  Note note({
    String title = 'Title',
    String body = 'Body',
    int performedOn = 1700000000000,
  }) =>
      Note.create(performedOn: performedOn, title: title, body: body);

  /// Pumps a screen with an "open" button that shows NoteEditSheet via
  /// showModalBottomSheet — the exact same route mechanism
  /// CalendarScreen._showNoteEditSheet uses in production — inside a
  /// GoRouter with a '/share/note' route mirroring app.dart's real one
  /// (same path, same `extra` contract), so tapping Share exercises the
  /// exact same context.push call NoteEditSheet makes in production.
  ///
  /// "open" is only ever tapped once per test now that a successful Edit
  /// Save keeps the sheet open — it exists so tests that DO need a fresh
  /// session (closing and reopening, or Add) can get one, not to simulate
  /// re-enabling Share after Save.
  Future<_NotesRecorder> pumpEditSheet(
    WidgetTester tester, {
    Note? initialNote,
    int performedOn = 1700000000000,
    required _ShareNavRecorder shareNav,
  }) async {
    final recorder = _NotesRecorder();
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  builder: (_) => NoteEditSheet(
                    performedOn: performedOn,
                    initialNote: recorder.updatedNotes.isNotEmpty
                        ? recorder.updatedNotes.last
                        : initialNote,
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/share/note',
          builder: (context, state) {
            shareNav.extras.add(state.extra);
            return const Scaffold(body: Text('SHARE_NOTE_PROBE'));
          },
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        // notesProvider.overrideWith (not notesProvider(arg).overrideWith)
        // is the family-level override — the only form
        // AutoDisposeAsyncNotifierProviderFamily.overrideWith supports.
        // Safe here since every test in this file only ever reads a
        // single fixed `performedOn` argument. A NEW _FakeNotesNotifier is
        // constructed on every call (not a captured single instance) —
        // see that class's own doc for why.
        overrides: [
          notesProvider.overrideWith(() => _FakeNotesNotifier(recorder)),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return recorder;
  }

  Finder titleField() => find.byType(TextField).at(0);
  Finder bodyField() => find.byType(TextField).at(1);
  NoteShareButton shareButtonWidget(WidgetTester tester) =>
      tester.widget<NoteShareButton>(find.byType(NoteShareButton));

  GestureDetector saveDetector(WidgetTester tester) => tester.widget<GestureDetector>(
      find.ancestor(of: find.text('Save'), matching: find.byType(GestureDetector)).first);
  bool saveEnabled(WidgetTester tester) => saveDetector(tester).onTap != null;
  Color? saveColor(WidgetTester tester) {
    final container = tester.widget<Container>(
        find.ancestor(of: find.text('Save'), matching: find.byType(Container)).first);
    return (container.decoration as BoxDecoration?)?.color;
  }

  group('NoteShareAvailability (pure state machine)', () {
    test('starts available: Share enabled, Save enabled (State A)', () {
      final s = NoteShareAvailability();
      expect(s.isAvailable, isTrue);
      expect(s.isSaveAvailable, isTrue);
    });

    test('markInteracted: Share disabled, Save enabled (State B), even '
        'with no text change, and idempotent across repeated calls '
        '(State C — not a dirty-text comparison)', () {
      final s = NoteShareAvailability()..markInteracted();
      expect(s.isAvailable, isFalse);
      expect(s.isSaveAvailable, isTrue);
      s
        ..markInteracted()
        ..markInteracted();
      expect(s.isAvailable, isFalse);
      expect(s.isSaveAvailable, isTrue);
    });

    test('markSaved: Share enabled, Save disabled (State C/successful '
        'save)', () {
      final s = NoteShareAvailability()
        ..markInteracted()
        ..markSaved();
      expect(s.isAvailable, isTrue);
      expect(s.isSaveAvailable, isFalse);
    });

    test('the cycle repeats: interact → saved → interact → saved', () {
      final s = NoteShareAvailability();
      s.markInteracted();
      expect((s.isAvailable, s.isSaveAvailable), (false, true));
      s.markSaved();
      expect((s.isAvailable, s.isSaveAvailable), (true, false));
      s.markInteracted();
      expect((s.isAvailable, s.isSaveAvailable), (false, true));
      s.markSaved();
      expect((s.isAvailable, s.isSaveAvailable), (true, false));
    });
  });

  group('NoteShareButton (pure widget)', () {
    Future<void> pump(WidgetTester tester,
        {required bool enabled, required VoidCallback onTap}) {
      return tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: NoteShareButton(enabled: enabled, onTap: onTap),
        ),
      ));
    }

    testWidgets('enabled: tapping invokes onTap', (tester) async {
      var tapped = false;
      await pump(tester, enabled: true, onTap: () => tapped = true);
      await tester.tap(find.byType(NoteShareButton));
      expect(tapped, isTrue);
    });

    testWidgets('disabled: tapping never invokes onTap', (tester) async {
      var tapped = false;
      await pump(tester, enabled: false, onTap: () => tapped = true);
      await tester.tap(find.byType(NoteShareButton));
      expect(tapped, isFalse);
    });

    testWidgets(
        'disabled uses the muted/disabled icon color, not the enabled one',
        (tester) async {
      await pump(tester, enabled: true, onTap: () {});
      final enabledColor =
          tester.widget<Icon>(find.byType(Icon)).color;
      await pump(tester, enabled: false, onTap: () {});
      final disabledColor =
          tester.widget<Icon>(find.byType(Icon)).color;
      expect(disabledColor, isNot(equals(enabledColor)));
    });
  });

  group('NoteEditSheet — Add Note (Section 2: unchanged)', () {
    testWidgets('no Share button, Save initially enabled', (tester) async {
      await pumpEditSheet(tester,
          initialNote: null, shareNav: _ShareNavRecorder());
      expect(find.byType(NoteShareButton), findsNothing);
      expect(saveEnabled(tester), isTrue);
    });

    testWidgets(
        'a successful Add Save preserves existing behavior — persists via '
        'addNote and closes the sheet (no saved-state UI introduced)',
        (tester) async {
      final fake = await pumpEditSheet(tester,
          initialNote: null, shareNav: _ShareNavRecorder());
      await tester.enterText(bodyField(), 'a fresh note');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(fake.addedNotes, hasLength(1));
      expect(fake.addedNotes.single.body, 'a fresh note');
      expect(find.byType(NoteEditSheet), findsNothing); // sheet closed
    });
  });

  group('NoteEditSheet — Edit opened (State A)', () {
    testWidgets('Share enabled, Save enabled', (tester) async {
      await pumpEditSheet(tester,
          initialNote: note(), shareNav: _ShareNavRecorder());
      expect(find.byType(NoteShareButton), findsOneWidget);
      expect(shareButtonWidget(tester).enabled, isTrue);
      expect(saveEnabled(tester), isTrue);
    });
  });

  group('NoteEditSheet — field interaction (State B)', () {
    testWidgets('focusing Body without changing text: Share disabled, '
        'Save stays enabled', (tester) async {
      await pumpEditSheet(tester,
          initialNote: note(), shareNav: _ShareNavRecorder());
      await tester.tap(bodyField());
      await tester.pump();
      expect(shareButtonWidget(tester).enabled, isFalse);
      expect(saveEnabled(tester), isTrue);
    });

    testWidgets('focusing Title without changing text: Share disabled, '
        'Save stays enabled', (tester) async {
      await pumpEditSheet(tester,
          initialNote: note(), shareNav: _ShareNavRecorder());
      await tester.tap(titleField());
      await tester.pump();
      expect(shareButtonWidget(tester).enabled, isFalse);
      expect(saveEnabled(tester), isTrue);
    });

    testWidgets('changing, deleting, or restoring text after interacting '
        'never re-enables Share before Save (not a dirty-text comparison)',
        (tester) async {
      await pumpEditSheet(tester,
          initialNote: note(body: 'original'), shareNav: _ShareNavRecorder());
      await tester.enterText(bodyField(), 'changed');
      await tester.pump();
      expect(shareButtonWidget(tester).enabled, isFalse);
      await tester.enterText(bodyField(), 'original'); // exact restore
      await tester.pump();
      expect(shareButtonWidget(tester).enabled, isFalse);
    });
  });

  group('NoteEditSheet — successful Save (State C)', () {
    testWidgets('does NOT close the Edit Sheet — the same instance stays '
        'mounted', (tester) async {
      await pumpEditSheet(tester,
          initialNote: note(body: 'unchanged'), shareNav: _ShareNavRecorder());
      await tester.tap(bodyField());
      await tester.pump();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.byType(NoteEditSheet), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(2));
    });

    testWidgets('Share becomes enabled, Save becomes disabled/gray, in '
        'the same still-open Edit Sheet instance', (tester) async {
      await pumpEditSheet(tester,
          initialNote: note(body: 'unchanged'), shareNav: _ShareNavRecorder());
      await tester.tap(bodyField());
      await tester.pump();
      expect(shareButtonWidget(tester).enabled, isFalse);
      expect(saveEnabled(tester), isTrue);
      final enabledSaveColor = saveColor(tester);

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.byType(NoteEditSheet), findsOneWidget); // still the same sheet
      expect(shareButtonWidget(tester).enabled, isTrue);
      expect(saveEnabled(tester), isFalse);
      // Reuses AppColors.disabled, the same token already used elsewhere
      // for a disabled primary CTA — not a newly invented color, and
      // visibly different from the enabled fill.
      expect(saveColor(tester), isNot(equals(enabledSaveColor)));
    });

    testWidgets('Save is non-interactive while disabled/gray', (tester) async {
      final fake = await pumpEditSheet(tester,
          initialNote: note(body: 'unchanged'), shareNav: _ShareNavRecorder());
      await tester.tap(bodyField());
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(saveEnabled(tester), isFalse);
      final savedCount = fake.updatedNotes.length;

      await tester.tap(find.text('Save')); // disabled: must be inert
      await tester.pumpAndSettle();
      expect(fake.updatedNotes.length, savedCount); // no new save happened
    });

    testWidgets('Share immediately after Save (no further interaction) '
        'uses the newly saved Note content', (tester) async {
      final shareNav = _ShareNavRecorder();
      final fake = await pumpEditSheet(
        tester,
        initialNote: note(title: 'Old', body: 'stale'),
        shareNav: shareNav,
      );
      await tester.enterText(bodyField(), 'fresh');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(fake.updatedNotes.single.body, 'fresh');
      expect(shareButtonWidget(tester).enabled, isTrue);

      await tester.tap(find.byType(NoteShareButton));
      await tester.pumpAndSettle();
      expect(shareNav.extras, hasLength(1));
      final shared = shareNav.extras.single as Note;
      expect(shared.body, 'fresh');
      expect(shared.body, isNot('stale'));
    });
  });

  group('NoteEditSheet — repeated interact/save cycles, State D and E', () {
    testWidgets(
        'focus → save → focus again → Share disabled/Save enabled again → '
        'save again → Share enabled/Save disabled again, repeatable, all '
        'within the same sheet instance', (tester) async {
      // Share taps are intentionally not exercised mid-cycle here —
      // tapping Share navigates to '/share/note' (a real page push, not a
      // dialog), which naturally leaves this popup's own context behind;
      // that boundary is covered separately in its own test group. This
      // test is purely about the Share/Save *enabled-state* cycle
      // repeating correctly within one still-open sheet instance.
      final fake = await pumpEditSheet(
        tester,
        initialNote: note(title: 'v0', body: 'v0'),
        shareNav: _ShareNavRecorder(),
      );

      // --- cycle 1 ---
      await tester.tap(bodyField());
      await tester.pump();
      expect(shareButtonWidget(tester).enabled, isFalse);
      expect(saveEnabled(tester), isTrue);
      await tester.enterText(bodyField(), 'v1');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.byType(NoteEditSheet), findsOneWidget);
      expect(shareButtonWidget(tester).enabled, isTrue);
      expect(saveEnabled(tester), isFalse);
      expect(fake.updatedNotes.last.body, 'v1');

      // --- cycle 2 (State D: focus again disables Share, re-enables Save) ---
      await tester.tap(titleField());
      await tester.pump();
      expect(shareButtonWidget(tester).enabled, isFalse);
      expect(saveEnabled(tester), isTrue);

      // State E: saving again re-enables Share, disables Save again.
      await tester.enterText(bodyField(), 'v2');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.byType(NoteEditSheet), findsOneWidget);
      expect(shareButtonWidget(tester).enabled, isTrue);
      expect(saveEnabled(tester), isFalse);
      expect(fake.updatedNotes.last.body, 'v2');

      // --- cycle 3, to prove this isn't a one-time reset. Uses the Title
      // field (currently unfocused — Body has held focus continuously
      // since cycle 2's enterText, and Save never unfocuses it) so this
      // is a genuine focus transition, exercised independently of the
      // "still-focused field" case covered by the test below.
      await tester.tap(titleField());
      await tester.pump();
      expect(shareButtonWidget(tester).enabled, isFalse);
      expect(saveEnabled(tester), isTrue);
      await tester.tap(find.text('Save')); // no text change this time
      await tester.pumpAndSettle();
      expect(shareButtonWidget(tester).enabled, isTrue);
      expect(saveEnabled(tester), isFalse);
      expect(fake.updatedNotes.length, 3); // three successful saves total
    });

    testWidgets(
        'a field that stays focused across a Save (never loses focus) '
        'still disables Share and re-enables Save once the user types '
        'more into it — Save does not unfocus fields, so this cannot rely '
        'on a focus transition alone', (tester) async {
      final fake = await pumpEditSheet(tester,
          initialNote: note(body: 'v0'), shareNav: _ShareNavRecorder());
      await tester.enterText(bodyField(), 'v1'); // focuses + types in one step
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(shareButtonWidget(tester).enabled, isTrue);
      expect(saveEnabled(tester), isFalse);
      expect(fake.updatedNotes.last.body, 'v1');

      // Body field is still focused (Save never unfocused it) — typing
      // more must still disable Share/re-enable Save, with no
      // intervening focus change.
      await tester.enterText(bodyField(), 'v2');
      await tester.pump();
      expect(shareButtonWidget(tester).enabled, isFalse);
      expect(saveEnabled(tester), isTrue);
    });
  });

  group('NoteEditSheet — cancel/close without saving', () {
    testWidgets(
        'closing without saving discards the temporary state; reopening '
        'the same persisted note starts with Share enabled, Save enabled',
        (tester) async {
      final original = note(body: 'saved content');
      final fake = await pumpEditSheet(tester,
          initialNote: original, shareNav: _ShareNavRecorder());
      await tester.tap(bodyField());
      await tester.pump();
      expect(shareButtonWidget(tester).enabled, isFalse);

      // Close via the popup's own close (X) button — not Save.
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(fake.updatedNotes, isEmpty); // nothing was persisted
      expect(find.byType(NoteEditSheet), findsNothing); // actually closed

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(shareButtonWidget(tester).enabled, isTrue);
      expect(saveEnabled(tester), isTrue);
    });
  });

  group('NoteEditSheet — Save failure', () {
    testWidgets(
        'a failed Save does not re-enable Share, does not disable Save, '
        'does not update the saved-note source of truth, does not let '
        'unsaved content be shared, and does not close the sheet',
        (tester) async {
      final shareNav = _ShareNavRecorder();
      final fake = await pumpEditSheet(
        tester,
        initialNote: note(title: 'Old', body: 'stale'),
        shareNav: shareNav,
      );
      await tester.tap(bodyField());
      await tester.pump();
      expect(shareButtonWidget(tester).enabled, isFalse);
      expect(saveEnabled(tester), isTrue);

      fake.failNextUpdate = true;
      await tester.enterText(bodyField(), 'attempted change');
      // _save() has no try/catch (existing behavior, preserved as-is), so
      // it throws asynchronously. Driving this through tester.tap() would
      // dispatch it as a fire-and-forget pointer event — the framework
      // never awaits _save()'s Future, so the rejection becomes a truly
      // unhandled async error that fails the whole test run rather than
      // landing in tester.takeException(). Invoking the button's onTap
      // directly lets the test await and catch it like any other Future,
      // while still exercising the exact same production _save() call.
      Object? caught;
      try {
        await (saveDetector(tester).onTap! as Future<void> Function())();
      } catch (e) {
        caught = e;
      }
      await tester.pump();
      // The simulated failure propagates rather than being silently
      // swallowed — existing _save() has no try/catch, so this confirms
      // "keep the existing error handling" (i.e. none was added).
      expect(caught, isNotNull);

      expect(find.byType(NoteEditSheet), findsOneWidget); // not popped
      expect(shareButtonWidget(tester).enabled, isFalse); // still disabled
      expect(saveEnabled(tester), isTrue); // still available to retry
      expect(fake.updatedNotes, isEmpty); // nothing persisted

      await tester.tap(find.byType(NoteShareButton)); // disabled: inert
      await tester.pumpAndSettle();
      expect(shareNav.extras, isEmpty); // unsaved content was never shared
    });
  });

  group('NoteEditSheet — Share navigation boundary', () {
    testWidgets('tapping Share (immediately, no interaction) navigates to '
        'the same /share/note route workout sharing uses, passing the '
        'persisted Note as `extra` — not a plain-text OS share sheet',
        (tester) async {
      final shareNav = _ShareNavRecorder();
      await pumpEditSheet(
        tester,
        initialNote: note(title: 'Saved Title', body: 'Saved Body'),
        shareNav: shareNav,
      );
      expect(shareButtonWidget(tester).enabled, isTrue);

      await tester.tap(find.byType(NoteShareButton));
      await tester.pumpAndSettle();

      expect(shareNav.extras, hasLength(1));
      final shared = shareNav.extras.single;
      expect(shared, isA<Note>());
      expect((shared as Note).title, 'Saved Title');
      expect(shared.body, 'Saved Body');
      expect(find.text('SHARE_NOTE_PROBE'), findsOneWidget); // reached the route
    });

    testWidgets('after editing and saving, Share carries the newly saved '
        'content — never the live unsaved edit that was reverted before '
        'that save', (tester) async {
      final shareNav = _ShareNavRecorder();
      final fake = await pumpEditSheet(
        tester,
        initialNote: note(title: 'Title', body: 'stale'),
        shareNav: shareNav,
      );
      await tester.enterText(bodyField(), 'unsaved draft'); // Share disables
      await tester.enterText(bodyField(), 'fresh'); // final committed content
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(fake.updatedNotes.single.body, 'fresh');
      expect(shareButtonWidget(tester).enabled, isTrue);

      await tester.tap(find.byType(NoteShareButton));
      await tester.pumpAndSettle();

      final shared = shareNav.extras.single as Note;
      expect(shared.body, 'fresh');
      expect(shared.body, isNot(contains('unsaved draft')));
      expect(shared.body, isNot('stale'));
    });
  });
}
