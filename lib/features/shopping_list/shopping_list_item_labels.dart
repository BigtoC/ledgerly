// Shared label helpers for ShoppingListItem rows.
//
// Used by `_ShoppingListRow` (shopping_list_screen.dart) and `_PreviewRow`
// (widgets/shopping_list_card.dart). Top-level functions — no widget state.

import 'package:intl/intl.dart';

import '../../core/utils/money_formatter.dart';
import '../../data/models/account.dart';
import '../../data/models/category.dart';
import '../../data/models/currency.dart';
import '../../data/models/shopping_list_item.dart';

/// Returns memo if present and non-empty, otherwise category's display name.
String resolvePrimaryLabel(ShoppingListItem item, Category? category) {
  final memo = item.memo;
  if (memo != null && memo.isNotEmpty) return memo;
  if (category == null) return '';
  return category.customName ?? category.l10nKey ?? '';
}

/// Returns "category name · account name".
String resolveSecondaryLabel(Category? category, Account? account) {
  final catName = category == null
      ? ''
      : (category.customName ?? category.l10nKey ?? '');
  final accName = account?.name ?? '';
  if (catName.isEmpty && accName.isEmpty) return '';
  if (catName.isEmpty) return accName;
  if (accName.isEmpty) return catName;
  return '$catName · $accName';
}

/// Returns formatted date + optionally amount+currency.
String resolveTrailingLabel(
  ShoppingListItem item,
  Currency? currency,
  String locale,
) {
  final dateFmt = DateFormat.MMMd(locale);
  final date = dateFmt.format(item.draftDate);

  if (item.draftAmountMinorUnits != null && currency != null) {
    final amount = MoneyFormatter.format(
      amountMinorUnits: item.draftAmountMinorUnits!,
      currency: currency,
      locale: locale,
    );
    return '$date\n$amount';
  }

  return date;
}
