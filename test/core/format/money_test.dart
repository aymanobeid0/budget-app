import 'package:budget_app/core/format/money.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Money.parseMinor', () {
    test('reads whole amounts and up to two decimals into minor units', () {
      expect(Money.parseMinor('42'), 4200);
      expect(Money.parseMinor('42.5'), 4250);
      expect(Money.parseMinor('42.05'), 4205);
      expect(Money.parseMinor('0.01'), 1);
      expect(Money.parseMinor(' 1250 '), 125000);
    });

    test('takes a comma as the decimal point', () {
      expect(Money.parseMinor('42,50'), 4250);
    });

    test('keeps exact cents a double would round', () {
      expect(Money.parseMinor('0.29'), 29);
      expect(Money.parseMinor('1.15'), 115);
      expect(Money.parseMinor('123456789.99'), 12345678999);
    });

    test('a trailing separator is a whole amount', () {
      expect(Money.parseMinor('42.'), 4200);
    });

    test('rejects what is not an amount', () {
      for (final text in ['', ' ', '.', '.5', '1.2.3', '1,250.00', '1.234', 'abc', '-5']) {
        expect(Money.parseMinor(text), isNull, reason: text);
      }
    });
  });
}
