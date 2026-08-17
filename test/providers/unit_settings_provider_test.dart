import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:peaklog/providers/default_best_type_provider.dart';
import 'package:peaklog/providers/unit_settings_provider.dart';
import 'package:peaklog/core/enums/best_type.dart';

// Covers the actual root cause of the "stuck on default until Settings is
// opened" bug: unitSettingsProvider and defaultBestTypeProvider are plain
// AsyncNotifiers that await SharedPreferences.getInstance() in build().
// Left to build lazily on whichever consumer touches them first (as they
// were before bootstrap() pre-loaded them), the very first synchronous read
// can never see the persisted value — only a later rebuild (e.g. the one
// triggered by navigating through Settings) would. bootstrap() now awaits
// both providers' `.future` before runApp(), exactly like it already does
// for resolvedLaunchScreenProvider; these tests model that same sequence.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('unmitigated race (documents the bug the fix removes)', () {
    test('unitSettingsProvider: persisted lbs is not yet available on the '
        'very first synchronous read of a freshly created container',
        () async {
      SharedPreferences.setMockInitialValues({'weightUnit': 'lbs'});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(unitSettingsProvider).valueOrNull, isNull);
    });

    test('defaultBestTypeProvider: persisted pb is not yet available on the '
        'very first synchronous read of a freshly created container',
        () async {
      SharedPreferences.setMockInitialValues({'default_best_type': 'pb'});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(defaultBestTypeProvider).valueOrNull, isNull);
    });
  });

  group('bootstrap-style pre-load (the fix)', () {
    Future<ProviderContainer> preloadedContainer() async {
      final container = ProviderContainer();
      await Future.wait([
        container.read(unitSettingsProvider.future),
        container.read(defaultBestTypeProvider.future),
      ]);
      return container;
    }

    test('Scenario A: cold start — both providers already have the '
        'persisted value on the very first synchronous read, no Settings '
        'visit involved', () async {
      SharedPreferences.setMockInitialValues({
        'weightUnit': 'lbs',
        'default_best_type': 'pb',
      });
      final container = await preloadedContainer();
      addTearDown(container.dispose);

      expect(container.read(unitSettingsProvider).valueOrNull?.weightUnit, 'lbs');
      expect(container.read(defaultBestTypeProvider).valueOrNull, BestType.pb);
    });

    test('Scenario B/C: whether or not something reads the provider again '
        'afterward (standing in for a Settings visit) makes no difference '
        '— the value was already correct from the very first read',
        () async {
      SharedPreferences.setMockInitialValues({
        'weightUnit': 'lbs',
        'default_best_type': 'pb',
      });
      final container = await preloadedContainer();
      addTearDown(container.dispose);

      final beforeUnit = container.read(unitSettingsProvider).valueOrNull?.weightUnit;
      final beforeType = container.read(defaultBestTypeProvider).valueOrNull;

      // Simulate visiting Settings: just another read/watch of the same
      // already-resolved providers — nothing Settings-specific about it.
      container.listen(unitSettingsProvider, (_, __) {});
      container.listen(defaultBestTypeProvider, (_, __) {});

      expect(container.read(unitSettingsProvider).valueOrNull?.weightUnit, beforeUnit);
      expect(container.read(defaultBestTypeProvider).valueOrNull, beforeType);
      expect(beforeUnit, 'lbs');
      expect(beforeType, BestType.pb);
    });

    test('kg / pr defaults still resolve correctly when nothing is '
        'persisted', () async {
      SharedPreferences.setMockInitialValues({});
      final container = await preloadedContainer();
      addTearDown(container.dispose);

      expect(container.read(unitSettingsProvider).valueOrNull?.weightUnit, 'kg');
      expect(container.read(defaultBestTypeProvider).valueOrNull, BestType.pr);
    });

    test('Scenario D: a later in-session change (e.g. via Settings) still '
        'updates the live provider normally — pre-loading does not freeze '
        'it', () async {
      SharedPreferences.setMockInitialValues({'weightUnit': 'kg'});
      final container = await preloadedContainer();
      addTearDown(container.dispose);

      expect(container.read(unitSettingsProvider).valueOrNull?.weightUnit, 'kg');

      await container
          .read(unitSettingsProvider.notifier)
          .setWeightUnit('lbs');

      expect(container.read(unitSettingsProvider).valueOrNull?.weightUnit, 'lbs');
    });
  });
}
