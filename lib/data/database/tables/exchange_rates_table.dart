import 'package:drift/drift.dart';

import 'currencies_table.dart';

/// Drift table for `exchange_rates`.
///
/// Stores forward exchange rates only (no inverse rows — UI always looks up
/// foreign→default direction). Rate is stored as `rate_scaled_e9` =
/// `round(rate × 10⁹)`, which fits any fiat rate comfortably in int64 (the
/// max representable rate is ≈9.2e9 before overflow on the int64 column).
/// We use a fixed scale rather than a numerator/denominator fraction
/// because the API returns rates as `double` — the fraction representation
/// would not preserve information that has already been lost at parse time.
///
/// See `docs/superpowers/specs/2026-05-14-multi-currency-conversion-design.md`.
@DataClassName('ExchangeRateRow')
@TableIndex(
  name: 'idx_exchange_rates_pair',
  columns: {#baseCurrency, #quoteCurrency},
  unique: true,
)
class ExchangeRates extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get baseCurrency =>
      text().named('base_currency').references(Currencies, #code)();
  TextColumn get quoteCurrency =>
      text().named('quote_currency').references(Currencies, #code)();
  IntColumn get rateScaledE9 => integer()
      .named('rate_scaled_e9')
      .customConstraint('CHECK(rate_scaled_e9 > 0) NOT NULL')();
  DateTimeColumn get fetchedAt => dateTime().named('fetched_at')();
}
