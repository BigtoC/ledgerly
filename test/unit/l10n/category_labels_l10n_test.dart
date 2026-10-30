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

  test('zh labels follow Fortune City category names', () async {
    final zhTw = await _resolve(const Locale('zh', 'TW'));
    final zhCn = await _resolve(const Locale('zh', 'CN'));

    expect(zhTw.categoryFood, '食物');
    expect(zhTw.categoryDrinks, '飲品');
    expect(zhTw.categoryShopping, '消費');
    expect(zhTw.categoryHousing, '居家');
    expect(zhTw.categoryMedical, '醫藥');

    expect(zhCn.categoryFood, '食物');
    expect(zhCn.categoryDrinks, '饮品');
    expect(zhCn.categoryShopping, '消费');
    expect(zhCn.categoryHousing, '居家');
    expect(zhCn.categoryMedical, '医药');
  });
}
