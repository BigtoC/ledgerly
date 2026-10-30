import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/features/categories/widgets/category_display.dart';
import 'package:ledgerly/l10n/app_localizations.dart';

Future<AppLocalizations> _resolve(Locale locale) =>
    AppLocalizations.delegate.load(locale);

void main() {
  test('category.investment resolves per locale', () async {
    final en = await _resolve(const Locale('en'));
    final zhTw = await _resolve(const Locale('zh', 'TW'));
    final zhCn = await _resolve(const Locale('zh', 'CN'));

    expect(categoryDisplayNameForKey('category.investment', en), 'Investment');
    expect(categoryDisplayNameForKey('category.investment', zhTw), '理財');
    expect(categoryDisplayNameForKey('category.investment', zhCn), '理财');
  });
}
