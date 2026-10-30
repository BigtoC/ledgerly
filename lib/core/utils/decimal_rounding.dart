/// Converts a plain decimal string (e.g. a CSV amount such as
/// `23.6000003814697`) to integer minor units without ever going through
/// a `double`.
///
/// [digits] must match `^[0-9]+(\.[0-9]+)?$` exactly: no sign, no
/// grouping separators, no exponent and no surrounding whitespace. The
/// fraction is rounded half-up once, on the digit string, to [scale]
/// places, then padded with zeros to [decimals] places. [scale] must not
/// exceed [decimals].
///
/// Returns 0 when the value rounds to zero; callers decide whether that
/// is valid. Throws [FormatException] on bad syntax or when the result
/// does not fit in a signed 64-bit `int` (possible for 18-decimal
/// currencies, where `int.parse` would otherwise be the only guard).
int decimalStringToMinorUnits(
  String digits, {
  required int scale,
  required int decimals,
}) {
  assert(scale >= 0 && scale <= decimals);
  final match = _decimalPattern.firstMatch(digits);
  if (match == null) {
    throw const FormatException('Not a plain decimal number');
  }
  final integerPart = match[1]!;
  final fraction = match[2] ?? '';

  var kept = integerPart + fraction.padRight(scale, '0').substring(0, scale);
  if (fraction.length > scale && fraction.codeUnitAt(scale) >= _five) {
    kept = _incrementDigits(kept);
  }

  final minor = (kept + '0' * (decimals - scale)).replaceFirst(
    _leadingZeros,
    '',
  );
  if (minor.length > _maxInt64.length ||
      (minor.length == _maxInt64.length && minor.compareTo(_maxInt64) > 0)) {
    throw const FormatException('Amount does not fit in 64 bits');
  }
  return int.parse(minor);
}

final _decimalPattern = RegExp(r'^([0-9]+)(?:\.([0-9]+))?$');
final _leadingZeros = RegExp(r'^0+(?=[0-9])');
const _maxInt64 = '9223372036854775807';
const _five = 0x35;
const _zero = 0x30;
const _nine = 0x39;

/// Adds one to a non-empty string of ASCII digits, carrying left.
String _incrementDigits(String digits) {
  final units = digits.codeUnits.toList();
  for (var i = units.length - 1; i >= 0; i--) {
    if (units[i] != _nine) {
      units[i]++;
      return String.fromCharCodes(units);
    }
    units[i] = _zero;
  }
  return '1${String.fromCharCodes(units)}';
}
