import 'package:flutter_test/flutter_test.dart';
import 'package:peaklog/providers/launch_screen_provider.dart';

void main() {
  group('parseLaunchScreen', () {
    test('null raw value defaults to home', () {
      expect(parseLaunchScreen(null), LaunchScreen.home);
    });

    test('unrecognized raw value defaults to home', () {
      expect(parseLaunchScreen('not_a_real_screen'), LaunchScreen.home);
    });

    test('parses stored "home"', () {
      expect(parseLaunchScreen('home'), LaunchScreen.home);
    });

    test('parses stored "calendar"', () {
      expect(parseLaunchScreen('calendar'), LaunchScreen.calendar);
    });

    test('parses stored "calculatorHub"', () {
      expect(parseLaunchScreen('calculatorHub'), LaunchScreen.calculatorHub);
    });
  });
}
