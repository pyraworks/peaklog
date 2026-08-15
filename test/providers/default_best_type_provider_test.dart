import 'package:flutter_test/flutter_test.dart';
import 'package:peaklog/core/enums/best_type.dart';
import 'package:peaklog/providers/default_best_type_provider.dart';

void main() {
  group('parseDefaultBestType', () {
    test('null raw value defaults to pr', () {
      expect(parseDefaultBestType(null), BestType.pr);
    });

    test('unrecognized raw value defaults to pr', () {
      expect(parseDefaultBestType('not_a_real_type'), BestType.pr);
    });

    test('parses stored "pr"', () {
      expect(parseDefaultBestType('pr'), BestType.pr);
    });

    test('parses stored "pb"', () {
      expect(parseDefaultBestType('pb'), BestType.pb);
    });
  });
}
