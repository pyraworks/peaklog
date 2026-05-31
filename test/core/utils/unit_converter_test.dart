import 'package:flutter_test/flutter_test.dart';
import 'package:pbpr/core/utils/unit_converter.dart';

void main() {
  group('weight conversion', () {
    test('kgToLbs', () {
      expect(UnitConverter.kgToLbs(100), closeTo(220.462, 0.001));
    });
    test('lbsToKg round-trip', () {
      expect(UnitConverter.lbsToKg(UnitConverter.kgToLbs(100)), closeTo(100, 0.001));
    });
  });

  group('distance conversion', () {
    test('kmToMi', () {
      expect(UnitConverter.kmToMi(5), closeTo(3.107, 0.001));
    });
    test('miToKm round-trip', () {
      expect(UnitConverter.miToKm(UnitConverter.kmToMi(5)), closeTo(5, 0.001));
    });
  });

  group('time formatting', () {
    test('under 1 hour shows MM:SS', () {
      expect(UnitConverter.secondsToDisplay(90), '01:30');
    });
    test('1 hour and over shows H:MM:SS', () {
      expect(UnitConverter.secondsToDisplay(3661), '1:01:01');
    });
    test('zero shows 00:00', () {
      expect(UnitConverter.secondsToDisplay(0), '00:00');
    });
  });

  group('time parsing', () {
    test('parses MM:SS', () {
      expect(UnitConverter.displayToSeconds('19:30'), 1170);
    });
    test('parses H:MM:SS', () {
      expect(UnitConverter.displayToSeconds('1:23:45'), 5025);
    });
    test('round-trip', () {
      expect(UnitConverter.displayToSeconds(UnitConverter.secondsToDisplay(5025)), 5025);
    });
  });

  group('formatWeight', () {
    test('kg stays as kg', () {
      expect(UnitConverter.formatWeight(100, 'kg'), '100 kg');
    });
    test('converts to lbs', () {
      expect(UnitConverter.formatWeight(100, 'lbs'), '220.5 lbs');
    });
    test('integer display for whole numbers', () {
      expect(UnitConverter.formatWeight(50, 'kg'), '50 kg');
    });
    test('one decimal for fractional', () {
      expect(UnitConverter.formatWeight(102.5, 'kg'), '102.5 kg');
    });
  });

  group('formatDistance', () {
    test('km stays as km', () {
      expect(UnitConverter.formatDistance(5, 'km'), '5 km');
    });
    test('converts to mi', () {
      expect(UnitConverter.formatDistance(5, 'mi'), '3.1 mi');
    });
  });

  group('formatDiffWeight', () {
    test('positive diff', () {
      expect(UnitConverter.formatDiffWeight(2.5, 'kg'), '+2.5 kg');
    });
    test('negative diff', () {
      expect(UnitConverter.formatDiffWeight(-5.0, 'kg'), '-5 kg');
    });
  });
}
