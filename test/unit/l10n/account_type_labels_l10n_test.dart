import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/data/models/account_type.dart';
import 'package:ledgerly/features/accounts/widgets/account_type_display.dart';
import 'package:ledgerly/l10n/app_localizations.dart';

void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  final zhTw = lookupAppLocalizations(const Locale('zh', 'TW'));
  final zhCn = lookupAppLocalizations(const Locale('zh', 'CN'));

  test('seeded account-type keys resolve per locale', () {
    expect(accountTypeDisplayNameForKey('accountType.cash', en), 'Cash');
    expect(accountTypeDisplayNameForKey('accountType.cash', zhTw), '現金');
    expect(accountTypeDisplayNameForKey('accountType.cash', zhCn), '现金');
    expect(
      accountTypeDisplayNameForKey('accountType.investment', en),
      'Investment',
    );
    expect(accountTypeDisplayNameForKey('accountType.investment', zhTw), '投資');
    expect(accountTypeDisplayNameForKey('accountType.investment', zhCn), '投资');
  });

  test('an unknown key falls through to the raw key', () {
    expect(
      accountTypeDisplayNameForKey('accountType.gone', en),
      'accountType.gone',
    );
  });

  test('accountTypeDisplayName prefers customName, then the key label', () {
    const seeded = AccountType(
      id: 1,
      l10nKey: 'accountType.cash',
      icon: 'wallet',
      color: 0,
    );
    expect(accountTypeDisplayName(seeded, zhTw), '現金');
    expect(
      accountTypeDisplayName(seeded.copyWith(customName: 'Wallet'), zhTw),
      'Wallet',
    );
    expect(
      accountTypeDisplayName(seeded.copyWith(customName: '  '), en),
      'Cash',
    );
    expect(accountTypeDisplayName(seeded.copyWith(l10nKey: null), en), '');
  });
}
