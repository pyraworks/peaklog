import 'package:flutter_test/flutter_test.dart';
import 'package:peaklog/features/calculators/plate_calculator_logic.dart';

void main() {
  group('computeTotal', () {
    test('bar only (no plates)', () {
      final total = PlateCalculatorLogic.computeTotal(
        barWeight: 20.0,
        plateCounts: {},
      );
      expect(total, closeTo(20.0, 0.001));
    });
    test('20kg bar + 25×2 + 15×2 = 100kg', () {
      final total = PlateCalculatorLogic.computeTotal(
        barWeight: 20.0,
        plateCounts: {25.0: 2, 15.0: 2},
      );
      expect(total, closeTo(100.0, 0.001));
    });
    test('counts of zero contribute nothing', () {
      final total = PlateCalculatorLogic.computeTotal(
        barWeight: 20.0,
        plateCounts: {25.0: 0, 10.0: 0},
      );
      expect(total, closeTo(20.0, 0.001));
    });
  });

  group('solvePlates kg', () {
    test('100kg target → 25×2 + 15×2', () {
      final counts = PlateCalculatorLogic.solvePlates(
        totalWeightTarget: 100.0,
        barWeight: 20.0,
        plateSizes: PlateCalculatorLogic.kgPlates,
      );
      expect(counts[25.0], 2);
      expect(counts[15.0], 2);
      expect(counts[20.0] ?? 0, 0);
    });
    test('all counts are even', () {
      for (final target in [60.0, 80.0, 100.0, 120.0, 140.0]) {
        final counts = PlateCalculatorLogic.solvePlates(
          totalWeightTarget: target,
          barWeight: 20.0,
          plateSizes: PlateCalculatorLogic.kgPlates,
        );
        for (final count in counts.values) {
          expect(count % 2, 0, reason: 'count $count for target $target is odd');
        }
      }
    });
    test('target equals bar weight → all zeros', () {
      final counts = PlateCalculatorLogic.solvePlates(
        totalWeightTarget: 20.0,
        barWeight: 20.0,
        plateSizes: PlateCalculatorLogic.kgPlates,
      );
      expect(counts.values.every((v) => v == 0), isTrue);
    });
    test('target less than bar → all zeros', () {
      final counts = PlateCalculatorLogic.solvePlates(
        totalWeightTarget: 15.0,
        barWeight: 20.0,
        plateSizes: PlateCalculatorLogic.kgPlates,
      );
      expect(counts.values.every((v) => v == 0), isTrue);
    });
    test('round-trip: solvePlates then computeTotal gives back target', () {
      const target = 100.0;
      final counts = PlateCalculatorLogic.solvePlates(
        totalWeightTarget: target,
        barWeight: 20.0,
        plateSizes: PlateCalculatorLogic.kgPlates,
      );
      final total = PlateCalculatorLogic.computeTotal(
        barWeight: 20.0,
        plateCounts: counts,
      );
      expect(total, closeTo(target, 0.01));
    });
  });

  group('solvePlates lb', () {
    test('225lb target with 45lb bar → 45×4', () {
      final counts = PlateCalculatorLogic.solvePlates(
        totalWeightTarget: 225.0,
        barWeight: 45.0,
        plateSizes: PlateCalculatorLogic.lbPlates,
      );
      expect(counts[45.0], 4); // 2 per side
    });
    test('135lb target with 45lb bar → 45×2', () {
      final counts = PlateCalculatorLogic.solvePlates(
        totalWeightTarget: 135.0,
        barWeight: 45.0,
        plateSizes: PlateCalculatorLogic.lbPlates,
      );
      expect(counts[45.0], 2);
    });
  });
}
