import 'package:flutter_test/flutter_test.dart';
import 'package:peaklog/features/calculators/pace_calculator_logic.dart';

void main() {
  group('paceSecondsPerKm', () {
    test('5km in 20 min → 240 sec/km', () {
      expect(
        PaceCalculatorLogic.paceSecondsPerKm(distanceKm: 5.0, totalSeconds: 1200),
        closeTo(240.0, 0.01),
      );
    });
    test('zero distance returns null', () {
      expect(PaceCalculatorLogic.paceSecondsPerKm(distanceKm: 0, totalSeconds: 600), isNull);
    });
    test('zero time returns null', () {
      expect(PaceCalculatorLogic.paceSecondsPerKm(distanceKm: 5.0, totalSeconds: 0), isNull);
    });
  });

  group('totalSeconds', () {
    test('5km at 4:00/km → 20 min (1200s)', () {
      expect(
        PaceCalculatorLogic.totalSeconds(distanceKm: 5.0, paceSecondsPerKm: 240.0),
        1200,
      );
    });
    test('zero pace returns null', () {
      expect(PaceCalculatorLogic.totalSeconds(distanceKm: 5.0, paceSecondsPerKm: 0), isNull);
    });
  });

  group('formatPace', () {
    test('240 sec/km → "4:00"', () {
      expect(PaceCalculatorLogic.formatPace(240.0), '4:00');
    });
    test('270 sec/km → "4:30"', () {
      expect(PaceCalculatorLogic.formatPace(270.0), '4:30');
    });
    test('24 sec/km → "0:24"', () {
      expect(PaceCalculatorLogic.formatPace(24.0), '0:24');
    });
  });

  group('formatTime', () {
    test('1200s → "20:00"', () {
      expect(PaceCalculatorLogic.formatTime(1200), '20:00');
    });
    test('24s → "0:24"', () {
      expect(PaceCalculatorLogic.formatTime(24), '0:24');
    });
    test('3661s → "1:01:01"', () {
      expect(PaceCalculatorLogic.formatTime(3661), '1:01:01');
    });
  });

  group('parseTimeOrPace', () {
    test('"20:00" → 1200', () {
      expect(PaceCalculatorLogic.parseTimeOrPace('20:00'), 1200);
    });
    test('"4:00" → 240', () {
      expect(PaceCalculatorLogic.parseTimeOrPace('4:00'), 240);
    });
    test('"1:00:00" → 3600', () {
      expect(PaceCalculatorLogic.parseTimeOrPace('1:00:00'), 3600);
    });
    test('invalid "abc" → null', () {
      expect(PaceCalculatorLogic.parseTimeOrPace('abc'), isNull);
    });
    test('invalid seconds "4:60" → null', () {
      expect(PaceCalculatorLogic.parseTimeOrPace('4:60'), isNull);
    });
  });

  group('generateSplits — 5km at 4:00/km', () {
    late List<(String, int)> splits;
    setUp(() {
      splits = PaceCalculatorLogic.generateSplits(5.0, 240.0);
    });
    test('has 5 splits total', () {
      expect(splits.length, 5); // 1km … 5km, no sub-km
    });
    test('first split is 1km = 240s', () {
      expect(splits.first, ('1km', 240));
    });
    test('last split is 5km = 1200s', () {
      expect(splits.last, ('5km', 1200));
    });
    test('1km split = 240s', () {
      final km1 = splits.firstWhere((s) => s.$1 == '1km');
      expect(km1.$2, 240);
    });
  });

  group('generateSplits — half marathon at 5:00/km', () {
    late List<(String, int)> splits;
    setUp(() {
      splits = PaceCalculatorLogic.generateSplits(
          PaceCalculatorLogic.halfMarathonKm, 300.0);
    });
    test('last split label is "21.1km Finish"', () {
      expect(splits.last.$1, '21.1km Finish');
    });
    test('last split time = halfMarathonKm * 300 seconds', () {
      expect(splits.last.$2,
          (PaceCalculatorLogic.halfMarathonKm * 300.0).round());
    });
  });

  group('generateSplits — marathon at 5:00/km', () {
    test('last split label is "42.195km Finish"', () {
      final splits = PaceCalculatorLogic.generateSplits(
          PaceCalculatorLogic.marathonKm, 300.0);
      expect(splits.last.$1, '42.195km Finish');
    });
  });

  group('generateSplits — 1km at 4:00/km', () {
    late List<(String, int)> splits;
    setUp(() {
      splits = PaceCalculatorLogic.generateSplits(1.0, 240.0);
    });
    test('has 10 splits (100m increments)', () {
      expect(splits.length, 10);
    });
    test('first split is 100m = 24s', () {
      expect(splits.first, ('100m', 24));
    });
    test('last split is 1000m = 240s', () {
      expect(splits.last, ('1000m', 240));
    });
  });

  group('generateSplits — empty when invalid', () {
    test('returns empty for zero distance', () {
      expect(PaceCalculatorLogic.generateSplits(0, 240), isEmpty);
    });
    test('returns empty for zero pace', () {
      expect(PaceCalculatorLogic.generateSplits(5.0, 0), isEmpty);
    });
  });
}
