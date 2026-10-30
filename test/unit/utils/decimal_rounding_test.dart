import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/core/utils/decimal_rounding.dart';

void main() {
  int hkd(String s) => decimalStringToMinorUnits(s, scale: 2, decimals: 2);

  group('decimalStringToMinorUnits half-up rounding', () {
    test('float32 artifacts round to two places', () {
      expect(hkd('23.6000003814697'), 2360);
      expect(hkd('74.8000030517578'), 7480);
      expect(hkd('19869.76953125'), 1986977);
      expect(hkd('483.049987792969'), 48305);
      expect(hkd('14.61'), 1461);
    });

    test('the first dropped digit decides', () {
      expect(hkd('0.005'), 1);
      expect(hkd('0.004'), 0);
    });

    test('carry propagates into the integer part', () {
      expect(hkd('9.995'), 1000);
      expect(hkd('99.999'), 10000);
    });

    test('integers and short fractions are padded', () {
      expect(hkd('4000'), 400000);
      expect(hkd('0'), 0);
      expect(hkd('7.5'), 750);
      expect(hkd('007.50'), 750);
    });

    test('JPY rounds to whole units', () {
      expect(decimalStringToMinorUnits('1234.5', scale: 0, decimals: 0), 1235);
      expect(decimalStringToMinorUnits('1234.4', scale: 0, decimals: 0), 1234);
      expect(decimalStringToMinorUnits('1234', scale: 0, decimals: 0), 1234);
    });

    test('three-decimal currency rounds to scale 2, then pads', () {
      expect(decimalStringToMinorUnits('1.2345', scale: 2, decimals: 3), 1230);
      expect(decimalStringToMinorUnits('1.235', scale: 2, decimals: 3), 1240);
    });
  });

  group('decimalStringToMinorUnits int64 overflow guard', () {
    int eth(String s) => decimalStringToMinorUnits(s, scale: 2, decimals: 18);

    test('values that fit in int64 are accepted', () {
      expect(eth('1.5'), 1500000000000000000);
      expect(eth('9.22'), 9220000000000000000);
    });

    test('values above 2^63 - 1 throw', () {
      expect(() => eth('9.23'), throwsFormatException);
      expect(() => eth('10.5'), throwsFormatException);
    });

    test('the check runs after the carry', () {
      expect(() => eth('9.225'), throwsFormatException);
    });

    test('leading zeros do not count towards the length', () {
      expect(eth('0000000000000000000001.5'), 1500000000000000000);
    });
  });

  group('decimalStringToMinorUnits syntax', () {
    for (final input in [
      '-1',
      '+1',
      '1,000',
      '1e5',
      '',
      ' 1 2',
      ' 1',
      '1.',
      '.5',
      '1.2.3',
      '١٢',
    ]) {
      test('rejects "$input"', () {
        expect(() => hkd(input), throwsFormatException);
      });
    }
  });

  group('minorUnitsToDecimalString', () {
    test('inserts the decimal point at the currency scale', () {
      expect(minorUnitsToDecimalString(1234, decimals: 2), '12.34');
      expect(minorUnitsToDecimalString(1200, decimals: 2), '12.00');
    });

    test('pads small amounts with leading zeros', () {
      expect(minorUnitsToDecimalString(5, decimals: 2), '0.05');
      expect(minorUnitsToDecimalString(0, decimals: 2), '0.00');
      expect(
        minorUnitsToDecimalString(1, decimals: 18),
        '0.000000000000000001',
      );
    });

    test('zero-decimal currencies have no decimal point', () {
      expect(minorUnitsToDecimalString(1500, decimals: 0), '1500');
    });

    test('keeps the sign', () {
      expect(minorUnitsToDecimalString(-1234, decimals: 2), '-12.34');
      expect(minorUnitsToDecimalString(-5, decimals: 2), '-0.05');
    });
  });
}
