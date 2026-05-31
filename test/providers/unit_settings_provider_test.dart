import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pbpr/providers/unit_settings_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('initial state is kg and km', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final settings = await container.read(unitSettingsProvider.future);
    expect(settings.weightUnit, 'kg');
    expect(settings.distanceUnit, 'km');
  });

  test('toggleWeightUnit switches kg to lbs', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(unitSettingsProvider.future);
    await container.read(unitSettingsProvider.notifier).toggleWeightUnit();

    final settings = container.read(unitSettingsProvider).valueOrNull;
    expect(settings?.weightUnit, 'lbs');
  });

  test('toggleWeightUnit switches lbs back to kg', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(unitSettingsProvider.future);
    await container.read(unitSettingsProvider.notifier).toggleWeightUnit();
    await container.read(unitSettingsProvider.notifier).toggleWeightUnit();

    final settings = container.read(unitSettingsProvider).valueOrNull;
    expect(settings?.weightUnit, 'kg');
  });

  test('toggleDistanceUnit switches km to mi', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(unitSettingsProvider.future);
    await container.read(unitSettingsProvider.notifier).toggleDistanceUnit();

    final settings = container.read(unitSettingsProvider).valueOrNull;
    expect(settings?.distanceUnit, 'mi');
  });
}
