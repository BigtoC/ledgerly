import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/data/models/currency.dart';
import 'package:ledgerly/features/accounts/widgets/currency_display.dart';
import 'package:ledgerly/l10n/app_localizations_en.dart';

void main() {
  final l10n = AppLocalizationsEn();

  test('seeded currencies resolve localized full names', () {
    expect(
      currencyDisplayName(
        const Currency(code: 'USD', decimals: 2, nameL10nKey: 'currency.usd'),
        l10n,
      ),
      'US Dollar',
    );
  });

  test('customName wins over seeded l10n', () {
    expect(
      currencyDisplayName(
        const Currency(
          code: 'USD',
          decimals: 2,
          nameL10nKey: 'currency.usd',
          customName: 'Travel Card Dollars',
        ),
        l10n,
      ),
      'Travel Card Dollars',
    );
  });

  test('unknown keys still fall back to code', () {
    expect(
      currencyDisplayName(
        const Currency(code: 'XYZ', decimals: 2, nameL10nKey: 'currency.xyz'),
        l10n,
      ),
      'XYZ',
    );
  });

  test('all seeded currencies resolve to non-empty non-code names', () {
    const seeded = [
      ('currency.usd', 'USD'),
      ('currency.eur', 'EUR'),
      ('currency.jpy', 'JPY'),
      ('currency.twd', 'TWD'),
      ('currency.cny', 'CNY'),
      ('currency.hkd', 'HKD'),
      ('currency.gbp', 'GBP'),
      ('currency.cad', 'CAD'),
      ('currency.sgd', 'SGD'),
      ('currency.aud', 'AUD'),
      ('currency.nzd', 'NZD'),
    ];
    for (final (key, code) in seeded) {
      final name = currencyDisplayName(
        Currency(code: code, decimals: 2, nameL10nKey: key),
        l10n,
      );
      expect(
        name,
        isNot(equals(code)),
        reason: '$key should resolve to a full name, not $code',
      );
      expect(name, isNotEmpty, reason: '$key resolved to empty string');
    }
  });
}
