import 'package:flutter_test/flutter_test.dart';
import 'package:peaklog/core/utils/normalize.dart';

void main() {
  test('Back Squat → back_squat', () {
    expect(normalize('Back Squat'), 'back_squat');
  });

  test('Clean & Jerk → clean_and_jerk', () {
    expect(normalize('Clean & Jerk'), 'clean_and_jerk');
  });

  test('Back-Squat → back_squat', () {
    expect(normalize('Back-Squat'), 'back_squat');
  });

  test('"  Back  Squat  " → back_squat', () {
    expect(normalize('  Back  Squat  '), 'back_squat');
  });

  test('Back_Squat → back_squat', () {
    expect(normalize('Back_Squat'), 'back_squat');
  });
}
