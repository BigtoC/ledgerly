/// Pure scaled-integer minor-unit currency conversion.
///
/// Converts an amount in one currency's minor units to another using a
/// rate stored as `rate_scaled_e9` (rate × 10⁹). `BigInt` is used for the
/// intermediate multiplication because legitimate fiat amounts can push
/// the product past int64: a $1M balance (10⁸ minor units) at a rate
/// approaching the sanity ceiling (~10⁹ scaled) already produces 10¹⁷,
/// which is close enough to int64 max (≈9.2e18) that any tighter math
/// is fragile. BigInt allocations are O(1) per conversion; the perf
/// implications are documented and acceptable for the MVP's 10k-tx cap.
///
/// MVP scope: fiat only (decimals 0–8). 18-decimal token support is
/// deferred to a later phase; do not add ETH/wei tests here.
///
/// See `docs/superpowers/specs/2026-05-14-multi-currency-conversion-design.md`.
class CurrencyConverter {
  const CurrencyConverter._();

  static final BigInt _e9 = BigInt.from(1000000000);

  /// Converts [amountMinorUnits] from a currency with [fromDecimals]
  /// minor-unit digits to a currency with [toDecimals] minor-unit digits,
  /// using a rate scaled by 10⁹ (i.e., [rateScaledE9] = `round(rate × 1e9)`).
  ///
  /// Formula:
  ///   target = amount × rate × 10^(toDecimals − fromDecimals)
  ///          = amount × rateScaledE9 × 10^(toDecimals − fromDecimals) / 10⁹
  ///
  /// The result is truncated toward zero (BigInt `~/` semantics). The
  /// caller rounds at the API boundary by using `(rate × 1e9).round()`.
  static int convertMinorUnits({
    required int amountMinorUnits,
    required int rateScaledE9,
    required int fromDecimals,
    required int toDecimals,
  }) {
    final amount = BigInt.from(amountMinorUnits);
    final rate = BigInt.from(rateScaledE9);
    final shift = toDecimals - fromDecimals;

    if (shift >= 0) {
      final scale = BigInt.from(10).pow(shift);
      return ((amount * rate * scale) ~/ _e9).toInt();
    } else {
      final scale = BigInt.from(10).pow(-shift);
      return (amount * rate ~/ (_e9 * scale)).toInt();
    }
  }
}
