import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/core/utils/currency_converter.dart';

void main() {
  group('CurrencyConverter.convertMinorUnits', () {
    test('same-currency (USD→USD) returns same amount', () {
      expect(
        CurrencyConverter.convertMinorUnits(
          amountMinorUnits: 10000, // $100.00
          rateScaledE9: 1000000000,
          fromDecimals: 2,
          toDecimals: 2,
        ),
        10000,
      );
    });

    test('USD→EUR at 0.85 rate', () {
      // $100.00 = 10000 minor units, rate 0.85 → 8500 EUR minor units
      expect(
        CurrencyConverter.convertMinorUnits(
          amountMinorUnits: 10000,
          rateScaledE9: (0.85 * 1000000000).round(),
          fromDecimals: 2,
          toDecimals: 2,
        ),
        8500,
      );
    });

    test('JPY→USD (0 decimals → 2 decimals)', () {
      // ¥1000 = 1000 minor units, rate 0.0067 → $6.70 = 670
      expect(
        CurrencyConverter.convertMinorUnits(
          amountMinorUnits: 1000,
          rateScaledE9: (0.0067 * 1000000000).round(),
          fromDecimals: 0,
          toDecimals: 2,
        ),
        670,
      );
    });

    test('USD→JPY (2 decimals → 0 decimals)', () {
      // $6.70 = 670 minor units, rate 149.25 → 670 * 149.25 / 100
      // = 999.975 → 999 (truncated toward zero per BigInt ~/ semantics).
      expect(
        CurrencyConverter.convertMinorUnits(
          amountMinorUnits: 670,
          rateScaledE9: (149.25 * 1000000000).round(),
          fromDecimals: 2,
          toDecimals: 0,
        ),
        999,
      );
    });

    test('rounding: truncates fractional remainder toward zero', () {
      // 100 minor units * 0.333 rate = 33.3 → 33 (fractional dropped)
      expect(
        CurrencyConverter.convertMinorUnits(
          amountMinorUnits: 100,
          rateScaledE9: (0.333 * 1000000000).round(),
          fromDecimals: 2,
          toDecimals: 2,
        ),
        33,
      );
    });

    test('round-trip drift is within ±1 minor unit', () {
      // 100 HKD → USD → HKD should be within ±1 of 100
      const amount = 10000; // HK$100.00
      final hkdToUsdE9 = (0.1277 * 1000000000).round();
      final usdToHkdE9 = (1 / 0.1277 * 1000000000).round();

      final usd = CurrencyConverter.convertMinorUnits(
        amountMinorUnits: amount,
        rateScaledE9: hkdToUsdE9,
        fromDecimals: 2,
        toDecimals: 2,
      );
      final hkdRoundTrip = CurrencyConverter.convertMinorUnits(
        amountMinorUnits: usd,
        rateScaledE9: usdToHkdE9,
        fromDecimals: 2,
        toDecimals: 2,
      );

      expect(hkdRoundTrip, closeTo(amount, 1));
    });

    test('handles large fiat amounts without overflow', () {
      // $1M = 100_000_000 minor units; rate at upper sanity bound 1e6
      // = 1e15 scaled. Product is 1e23 — easily handled by BigInt path.
      expect(
        () => CurrencyConverter.convertMinorUnits(
          amountMinorUnits: 100000000,
          rateScaledE9: 1000000000000000, // 1e15
          fromDecimals: 2,
          toDecimals: 2,
        ),
        returnsNormally,
      );
    });
  });
}
