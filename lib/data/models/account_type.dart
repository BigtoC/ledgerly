import 'package:freezed_annotation/freezed_annotation.dart';

import 'currency.dart';

part 'account_type.freezed.dart';

/// User-facing account type (e.g. "Cash", "Investment"). Mirrors the
/// `account_types` row. Seeded rows (`accountType.cash`,
/// `accountType.investment`) are identified by `l10nKey`; users can rename
/// (sets `customName`) or add custom types. Display name resolution:
/// `customName ?? l10nKey` — handled at the UI boundary, not here.
///
/// Archive-instead-of-delete when referenced by at least one `Account`
/// (enforced in `AccountTypeRepository` at M3).
@freezed
abstract class AccountType with _$AccountType {
  const factory AccountType({
    required int id,

    /// Stable identity for seeded rows.
    String? l10nKey,

    /// User override of the localized name.
    String? customName,

    /// Optional default-currency hint. Null = no preference;
    /// account-creation form falls back to
    /// `user_preferences.default_currency`, then `'USD'`.
    Currency? defaultCurrency,

    /// Icon-registry string key. Never `IconData`.
    required String icon,

    /// Index into `core/utils/color_palette.dart`. Never ARGB.
    required int color,

    /// Order in pickers.
    @Default(0) int sortOrder,

    /// DB default `false`.
    @Default(false) bool isArchived,
  }) = _AccountType;
}
