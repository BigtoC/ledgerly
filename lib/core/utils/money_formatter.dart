import 'package:intl/intl.dart';

import '../../data/models/currency.dart';

/// Locale-aware formatter for integer minor-unit money amounts.
///
/// Scaling factor comes from `Currency.decimals` (SSOT — PRD.md 253-277).
/// Storage stays `int`; `double` lives exclusively inside this file and
/// only as the intermediate for `NumberFormat.currency`. See PRD.md ->
/// Money Storage Policy and CLAUDE.md -> Data-Model Invariants.
class MoneyFormatter {
  const MoneyFormatter._();

  /// Formats [amountMinorUnits] in [currency] for [locale] (e.g. `'en_US'`,
  /// `'zh_TW'`, `'zh_CN'`). Uses `currency.symbol` if present, otherwise
  /// falls back to `currency.code`. Negative amounts render with the
  /// locale-native sign (e.g. `-$1.23`). Zero renders with zero fractional
  /// digits matching `currency.decimals` (`$0.00`, `¥0`).
  static String format({
    required int amountMinorUnits,
    required Currency currency,
    required String locale,
  }) {
    final symbol = currency.symbol ?? currency.code;
    // `double` is safe up to ~15 significant digits. Above that, fall
    // through to a BigInt-based string path to avoid ULP drift (ETH @ 18).
    if (currency.decimals <= 12) {
      final fmt = NumberFormat.currency(
        locale: locale,
        symbol: symbol,
        decimalDigits: currency.decimals,
      );
      return fmt.format(amountMinorUnits / _scale(currency.decimals));
    }
    return _formatHighPrecision(
      amountMinorUnits: amountMinorUnits,
      currency: currency,
      locale: locale,
      symbol: symbol,
    );
  }

  /// Formats [amountMinorUnits] with an explicit leading sign for use in
  /// the Home list (`+$3.50` for income, `-$3.50` for expense) per PRD.md
  /// line 491. Zero renders without a sign. For negative inputs, returns
  /// the same string as [format] (the locale-native `-` is preserved).
  static String formatSigned({
    required int amountMinorUnits,
    required Currency currency,
    required String locale,
  }) {
    final base = format(
      amountMinorUnits: amountMinorUnits,
      currency: currency,
      locale: locale,
    );
    if (amountMinorUnits > 0) return '+$base';
    return base; // negatives already carry '-', zero stays bare.
  }

  /// Bare-number variant (no symbol, no code) for inputs and summary
  /// strips where the currency symbol is rendered separately. Uses
  /// locale-aware grouping and the decimal character from [locale].
  static String formatBare({
    required int amountMinorUnits,
    required Currency currency,
    required String locale,
  }) {
    if (currency.decimals <= 12) {
      final fmt = NumberFormat.decimalPatternDigits(
        locale: locale,
        decimalDigits: currency.decimals,
      );
      return fmt.format(amountMinorUnits / _scale(currency.decimals));
    }
    // High-precision: reuse the BigInt path but without any symbol.
    return _formatHighPrecision(
      amountMinorUnits: amountMinorUnits,
      currency: currency,
      locale: locale,
      symbol: '',
    );
  }

  /// Parses a user-entered decimal string into an integer minor-unit
  /// amount, scaled by [currency].`decimals`. Accepts the locale's decimal
  /// separator. Throws [FormatException] on unparseable input or on inputs
  /// whose fractional part exceeds `currency.decimals` digits (i.e. a
  /// rounding decision is required). Caller decides whether to catch or
  /// reject at the UI. Consumed by the Add/Edit Transaction calculator
  /// (M5) and the Account opening-balance input.
  static int parseToMinorUnits({
    required String input,
    required Currency currency,
    required String locale,
  }) {
    final symbols = NumberFormat.decimalPattern(locale).symbols;
    // Strip grouping separators, then normalize the locale decimal to '.'.
    final normalized = input
        .replaceAll(symbols.GROUP_SEP, '')
        .replaceAll(symbols.DECIMAL_SEP, '.');
    final isNegative = normalized.startsWith('-');
    final body = isNegative ? normalized.substring(1) : normalized;
    if (body.isEmpty) {
      throw FormatException('Unparseable amount: "$input"');
    }
    final parts = body.split('.');
    if (parts.length > 2) {
      throw FormatException('Unparseable amount: "$input"');
    }
    final whole = parts[0].isEmpty ? '0' : parts[0];
    final frac = parts.length == 2 ? parts[1] : '';
    if (frac.length > currency.decimals) {
      throw FormatException(
        'Fractional digits (${frac.length}) exceed '
        '${currency.code}.decimals (${currency.decimals}): "$input"',
      );
    }
    if (!_digitsOnly(whole) || !_digitsOnly(frac)) {
      throw FormatException('Unparseable amount: "$input"');
    }
    final padded = frac.padRight(currency.decimals, '0');
    final combined = '$whole$padded';
    final parsed = int.tryParse(combined);
    if (parsed == null) {
      throw FormatException('Unparseable amount: "$input"');
    }
    return isNegative ? -parsed : parsed;
  }

  // --- Internals ---------------------------------------------------------

  /// Returns 10^[decimals] as a `double`. Documented `double` escape hatch
  /// (G4 exemption) — callers sandwich this between `int` in / `String` out.
  static double _scale(int decimals) {
    var s = 1.0;
    for (var i = 0; i < decimals; i++) {
      s *= 10.0;
    }
    return s;
  }

  static bool _digitsOnly(String s) {
    if (s.isEmpty) return true;
    for (var i = 0; i < s.length; i++) {
      final c = s.codeUnitAt(i);
      if (c < 0x30 || c > 0x39) return false;
    }
    return true;
  }

  /// Formats a minor-unit [amountMinorUnits] with `decimals > 12` using
  /// `BigInt` arithmetic so no ULP drift can contaminate the fractional
  /// tail. Applies locale-aware grouping + decimal separator from
  /// `NumberFormat.decimalPattern(locale)`; prefixes [symbol] (pass `''`
  /// for the bare variant).
  static String _formatHighPrecision({
    required int amountMinorUnits,
    required Currency currency,
    required String locale,
    required String symbol,
  }) {
    final isNeg = amountMinorUnits < 0;
    final abs = BigInt.from(amountMinorUnits).abs();
    final scale = BigInt.from(10).pow(currency.decimals);
    final whole = abs ~/ scale;
    final frac = (abs % scale).toString().padLeft(currency.decimals, '0');
    final pattern = NumberFormat.decimalPattern(locale);
    // Re-group using BigInt string path when `whole` exceeds int range.
    final wholeStr = whole.bitLength <= 53
        ? pattern.format(whole.toInt())
        : _groupBigIntDecimal(whole, pattern.symbols.GROUP_SEP);
    final decSep = pattern.symbols.DECIMAL_SEP;
    final body = '$wholeStr$decSep$frac';
    return isNeg ? '-$symbol$body' : '$symbol$body';
  }

  static String _groupBigIntDecimal(BigInt v, String groupSep) {
    final digits = v.toString();
    final buf = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buf.write(groupSep);
      buf.write(digits[i]);
    }
    return buf.toString();
  }
}
