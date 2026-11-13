// Widget tests for `AccountSelectorTile`: when the shown account switches
// to another, for example when a memo suggestion switches it (issue
// #152), the tile plays a ripple so the user notices.

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/core/l10n/app_localizations_delegates.dart';
import 'package:ledgerly/domain/models/account.dart';
import 'package:ledgerly/domain/models/currency.dart';
import 'package:ledgerly/l10n/app_localizations.dart';
import 'package:ledgerly/ui/features/transactions/views/account_selector_tile.dart';

const _usd = Currency(code: 'USD', decimals: 2);
const _cash = Account(id: 1, name: 'Cash', accountTypeId: 1, currency: _usd);
const _invest = Account(
  id: 3,
  name: 'Investment',
  accountTypeId: 1,
  currency: _usd,
);

// InkRipple paints a circle, which `paints` can match; the app's default
// on Android is InkSparkle, a shader.
Widget _host(Account? account) => MaterialApp(
  theme: ThemeData(splashFactory: InkRipple.splashFactory),
  localizationsDelegates: appLocalizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(
    body: AccountSelectorTile(account: account, onTap: () {}),
  ),
);

RenderObject _ink(WidgetTester tester) =>
    Material.of(tester.element(find.byType(ListTile))) as RenderObject;

void main() {
  testWidgets('switching the account plays a ripple that fades out', (
    tester,
  ) async {
    await tester.pumpWidget(_host(_cash));
    expect(_ink(tester), isNot(paints..circle()));

    await tester.pumpWidget(_host(_invest));
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Investment'), findsOneWidget);
    expect(_ink(tester), paints..circle());

    await tester.pumpAndSettle();
    expect(_ink(tester), isNot(paints..circle()));
  });

  testWidgets('rebuilding with the same account plays no ripple', (
    tester,
  ) async {
    await tester.pumpWidget(_host(_cash));

    await tester.pumpWidget(_host(_cash.copyWith(name: 'Wallet')));
    await tester.pump(const Duration(milliseconds: 50));

    expect(_ink(tester), isNot(paints..circle()));
  });

  testWidgets('an account appearing where none was shown plays no ripple', (
    tester,
  ) async {
    // The recurring rule form shows no account until the active accounts
    // load; that is not a switch.
    await tester.pumpWidget(_host(null));

    await tester.pumpWidget(_host(_cash));
    await tester.pump(const Duration(milliseconds: 50));

    expect(_ink(tester), isNot(paints..circle()));
  });
}
