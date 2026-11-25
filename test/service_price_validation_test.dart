import 'package:flutter_test/flutter_test.dart';
import 'package:bookease/core/utils/validators.dart';

void main() {
  group('Service Price Validation Tests', () {
    test('rejects empty or null price with exact message', () {
      expect(
        Validators.validateServicePrice(null),
        'Please enter service price',
      );
      expect(
        Validators.validateServicePrice(''),
        'Please enter service price',
      );
      expect(
        Validators.validateServicePrice('   '),
        'Please enter service price',
      );
    });

    test('rejects zero price', () {
      expect(
        Validators.validateServicePrice('0'),
        'Please enter valid service price',
      );
      expect(
        Validators.validateServicePrice('0.00'),
        'Please enter valid service price',
      );
    });

    test('rejects negative price', () {
      expect(
        Validators.validateServicePrice('-100'),
        'Please enter valid service price',
      );
      expect(
        Validators.validateServicePrice('-0.01'),
        'Please enter valid service price',
      );
    });

    test('rejects non-numeric or invalid text', () {
      expect(
        Validators.validateServicePrice('abc'),
        'Please enter valid service price',
      );
      expect(
        Validators.validateServicePrice('Rs. 2500'),
        'Please enter valid service price',
      );
    });

    test('accepts valid numeric positive prices (integer or decimal)', () {
      expect(Validators.validateServicePrice('2500'), isNull);
      expect(Validators.validateServicePrice('2500.50'), isNull);
      expect(Validators.validateServicePrice('100'), isNull);
      expect(Validators.validateServicePrice('0.99'), isNull);
    });
  });
}
