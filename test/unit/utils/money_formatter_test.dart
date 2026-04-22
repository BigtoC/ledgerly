import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:ledgerly/core/utils/money_formatter.dart';
import 'package:ledgerly/data/models/currency.dart';

const _usd = Currency(code: 'USD', decimals: 2, symbol: r'$');
const _jpy = Currency(code: 'JPY', decimals: 0, symbol: '¥');
const _twd = Currency(code: 'TWD', decimals: 2, symbol: r'NT$');
const _cny = Currency(code: 'CNY', decimals: 2, symbol: '¥');
const _eth = Currency(code: 'ETH', decimals: 18, isToken: true);

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en_US', null);
    await initializeDateFormatting('zh_TW', null);
    await initializeDateFormatting('zh_CN', null);
  });

  group('MoneyFormatter.format — USD', () {
    test('M02: 12345 minor units in en_US renders \$123.45', () {
      expect(
        MoneyFormatter.format(
          amountMinorUnits: 12345,
          currency: _usd,
          locale: 'en_US',
        ),
        r'$123.45',
      );
    });
  });

  group('MoneyFormatter.format — JPY (zero-decimal)', () {
    test('M05: 1_234_567 minor units in en_US renders ¥1,234,567', () {
      expect(
        MoneyFormatter.format(
          amountMinorUnits: 1234567,
          currency: _jpy,
          locale: 'en_US',
        ),
        '¥1,234,567',
      );
    });
  });

  group('MoneyFormatter.format — TWD in zh_TW', () {
    test('M08: 1_234_567 minor units in zh_TW renders NT\$12,345.67', () {
      expect(
        MoneyFormatter.format(
          amountMinorUnits: 1234567,
          currency: _twd,
          locale: 'zh_TW',
        ),
        r'NT$12,345.67',
      );
    });
  });

  group('MoneyFormatter.format — CNY in zh_CN', () {
    test('M10: 123_456_789 minor units in zh_CN renders ¥1,234,567.89', () {
      expect(
        MoneyFormatter.format(
          amountMinorUnits: 123456789,
          currency: _cny,
          locale: 'zh_CN',
        ),
        '¥1,234,567.89',
      );
    });
  });

  group('MoneyFormatter.format — ETH (18 decimals, no symbol)', () {
    test('M11: 1.5 ETH renders with code fallback', () {
      expect(
        MoneyFormatter.format(
          amountMinorUnits: 1500000000000000000,
          currency: _eth,
          locale: 'en_US',
        ),
        'ETH1.500000000000000000',
      );
    });

    test('M12: 0 ETH renders with full 18 trailing zeros', () {
      expect(
        MoneyFormatter.format(
          amountMinorUnits: 0,
          currency: _eth,
          locale: 'en_US',
        ),
        'ETH0.000000000000000000',
      );
    });
  });

  group('MoneyFormatter.format — zero / negative', () {
    test('M01: USD 0 → \$0.00', () {
      expect(
        MoneyFormatter.format(
          amountMinorUnits: 0,
          currency: _usd,
          locale: 'en_US',
        ),
        r'$0.00',
      );
    });
    test('M03: USD -12345 → -\$123.45', () {
      expect(
        MoneyFormatter.format(
          amountMinorUnits: -12345,
          currency: _usd,
          locale: 'en_US',
        ),
        r'-$123.45',
      );
    });
    test('M04: JPY 0 → ¥0', () {
      expect(
        MoneyFormatter.format(
          amountMinorUnits: 0,
          currency: _jpy,
          locale: 'en_US',
        ),
        '¥0',
      );
    });
    test('M06: JPY -1_234_567 → -¥1,234,567', () {
      expect(
        MoneyFormatter.format(
          amountMinorUnits: -1234567,
          currency: _jpy,
          locale: 'en_US',
        ),
        '-¥1,234,567',
      );
    });
    test('M07: TWD 0 in zh_TW → NT\$0.00', () {
      expect(
        MoneyFormatter.format(
          amountMinorUnits: 0,
          currency: _twd,
          locale: 'zh_TW',
        ),
        r'NT$0.00',
      );
    });
    test('M09: TWD -1_234_567 in zh_TW → -NT\$12,345.67', () {
      expect(
        MoneyFormatter.format(
          amountMinorUnits: -1234567,
          currency: _twd,
          locale: 'zh_TW',
        ),
        r'-NT$12,345.67',
      );
    });
    test('M13: ETH -1.5 → -ETH1.500000000000000000', () {
      expect(
        MoneyFormatter.format(
          amountMinorUnits: -1500000000000000000,
          currency: _eth,
          locale: 'en_US',
        ),
        '-ETH1.500000000000000000',
      );
    });
  });

  group('MoneyFormatter.formatSigned — PRD 491 list rendering', () {
    test('M14: positive USD → +\$123.45', () {
      expect(
        MoneyFormatter.formatSigned(
          amountMinorUnits: 12345,
          currency: _usd,
          locale: 'en_US',
        ),
        r'+$123.45',
      );
    });
    test('M15: negative USD → -\$123.45 (preserve locale-native -)', () {
      expect(
        MoneyFormatter.formatSigned(
          amountMinorUnits: -12345,
          currency: _usd,
          locale: 'en_US',
        ),
        r'-$123.45',
      );
    });
    test('M16: zero USD → \$0.00 (no sign)', () {
      expect(
        MoneyFormatter.formatSigned(
          amountMinorUnits: 0,
          currency: _usd,
          locale: 'en_US',
        ),
        r'$0.00',
      );
    });
  });

  group('MoneyFormatter.formatBare — no symbol', () {
    test('M17: JPY 1_234_567 en_US → 1,234,567', () {
      expect(
        MoneyFormatter.formatBare(
          amountMinorUnits: 1234567,
          currency: _jpy,
          locale: 'en_US',
        ),
        '1,234,567',
      );
    });
    test('M18: USD 12345 zh_CN → 123.45', () {
      expect(
        MoneyFormatter.formatBare(
          amountMinorUnits: 12345,
          currency: _usd,
          locale: 'zh_CN',
        ),
        '123.45',
      );
    });
  });

  group('MoneyFormatter.parseToMinorUnits — happy path', () {
    test('M19: "123.45" USD en_US → 12345', () {
      expect(
        MoneyFormatter.parseToMinorUnits(
          input: '123.45',
          currency: _usd,
          locale: 'en_US',
        ),
        12345,
      );
    });
    test('M20: "1234" JPY en_US → 1234', () {
      expect(
        MoneyFormatter.parseToMinorUnits(
          input: '1234',
          currency: _jpy,
          locale: 'en_US',
        ),
        1234,
      );
    });
    test('M21: "1,234.56" USD zh_CN → 123456', () {
      expect(
        MoneyFormatter.parseToMinorUnits(
          input: '1,234.56',
          currency: _usd,
          locale: 'zh_CN',
        ),
        123456,
      );
    });
  });

  group('MoneyFormatter.parseToMinorUnits — errors', () {
    test('M22: "12.345" with USD (2) throws FormatException', () {
      expect(
        () => MoneyFormatter.parseToMinorUnits(
          input: '12.345',
          currency: _usd,
          locale: 'en_US',
        ),
        throwsA(isA<FormatException>()),
      );
    });
    test('M23: "abc" throws FormatException', () {
      expect(
        () => MoneyFormatter.parseToMinorUnits(
          input: 'abc',
          currency: _usd,
          locale: 'en_US',
        ),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
