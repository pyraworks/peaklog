import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:peaklog/features/calculators/one_rm_calculator_screen.dart';
import 'package:peaklog/features/calculators/plate_calculator_screen.dart';
import 'package:peaklog/l10n/app_localizations.dart';
import 'package:peaklog/providers/unit_settings_provider.dart';

// Regression coverage for the "Preferred Weight Unit stuck on kg until
// Settings is opened" bug. Root cause: unitSettingsProvider is a plain
// AsyncNotifier awaiting SharedPreferences.getInstance() in build(). Left to
// build lazily on whichever screen reads it first, that screen's initState
// synchronous read can never see the persisted value — only visiting some
// other screen later (once the provider has since resolved in the
// background) would happen to show it correctly. The fix pre-loads
// unitSettingsProvider in bootstrap() before runApp(); these tests build the
// same pre-loaded-container sequence bootstrap() now performs, then mount
// the real screens on top of it — matching the actual first-consumer path,
// not a simplified provider-only check.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ProviderContainer> preloadedContainer() async {
    final container = ProviderContainer();
    await container.read(unitSettingsProvider.future);
    return container;
  }

  Future<void> pump(WidgetTester tester, ProviderContainer container, Widget screen) {
    return tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: screen,
        ),
      ),
    );
  }

  group('PlateCalculatorScreen', () {
    testWidgets(
        'Scenario A: cold start — a persisted lbs preference is reflected '
        'on the very first render, no Settings visit involved', (tester) async {
      SharedPreferences.setMockInitialValues({'weightUnit': 'lbs'});
      final container = await preloadedContainer();
      addTearDown(container.dispose);

      await pump(tester, container, const PlateCalculatorScreen());

      // 45 only appears as a bar option in lb mode (lbBars); 20 only in kg
      // mode (kgBars) — a public, rendered-text signal of which unit the
      // screen actually initialized with.
      expect(find.text('45 lb'), findsWidgets);
      expect(find.text('20 kg'), findsNothing);
    });

    testWidgets('a persisted kg preference is reflected on first render',
        (tester) async {
      SharedPreferences.setMockInitialValues({'weightUnit': 'kg'});
      final container = await preloadedContainer();
      addTearDown(container.dispose);

      await pump(tester, container, const PlateCalculatorScreen());

      expect(find.text('20 kg'), findsWidgets);
      expect(find.text('45 lb'), findsNothing);
    });

    testWidgets(
        'Scenario D: the user\'s manual kg/lb toggle inside the calculator '
        'is not overwritten by a later change to the persisted preference',
        (tester) async {
      SharedPreferences.setMockInitialValues({'weightUnit': 'kg'});
      final container = await preloadedContainer();
      addTearDown(container.dispose);

      await pump(tester, container, const PlateCalculatorScreen());
      expect(find.text('20 kg'), findsWidgets);

      // User manually switches to lb inside the calculator.
      await tester.tap(find.text('lb'));
      await tester.pump();
      expect(find.text('45 lb'), findsWidgets);

      // Settings changes the persisted preference back to kg while this
      // screen is still open (e.g. changed in another session/screen).
      await container.read(unitSettingsProvider.notifier).setWeightUnit('kg');
      await tester.pump();

      // The user's manual in-screen choice must still stand.
      expect(find.text('45 lb'), findsWidgets,
          reason: 'manual selection must not be overwritten by a live '
              'preference change while the calculator stays open');
    });

    testWidgets(
        'reopening the calculator (a fresh screen instance) picks up the '
        'persisted preference again, without needing Settings', (tester) async {
      SharedPreferences.setMockInitialValues({'weightUnit': 'lbs'});
      final container = await preloadedContainer();
      addTearDown(container.dispose);

      await pump(tester, container, const PlateCalculatorScreen());
      expect(find.text('45 lb'), findsWidgets);

      // Simulate leaving and reopening: swap in a brand new screen widget
      // (a new State instance, exactly like real navigation would create).
      await pump(tester, container, const SizedBox.shrink());
      await pump(tester, container, const PlateCalculatorScreen());

      expect(find.text('45 lb'), findsWidgets);
    });
  });

  group('OneRmCalculatorScreen', () {
    Color? unitChipColor(WidgetTester tester, String label) =>
        tester.widget<Text>(find.text(label)).style?.color;

    testWidgets(
        'Scenario A: cold start — a persisted lbs preference is reflected '
        'on the very first render, no Settings visit involved', (tester) async {
      SharedPreferences.setMockInitialValues({'weightUnit': 'lbs'});
      final container = await preloadedContainer();
      addTearDown(container.dispose);

      await pump(tester, container, const OneRmCalculatorScreen());

      expect(unitChipColor(tester, 'lb'), Colors.white);
      expect(unitChipColor(tester, 'kg'), isNot(Colors.white));
    });

    testWidgets('a persisted kg preference is reflected on first render',
        (tester) async {
      SharedPreferences.setMockInitialValues({'weightUnit': 'kg'});
      final container = await preloadedContainer();
      addTearDown(container.dispose);

      await pump(tester, container, const OneRmCalculatorScreen());

      expect(unitChipColor(tester, 'kg'), Colors.white);
      expect(unitChipColor(tester, 'lb'), isNot(Colors.white));
    });
  });
}
