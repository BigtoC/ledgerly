import 'package:freezed_annotation/freezed_annotation.dart';

import 'currency.dart';

part 'account.freezed.dart';

/// User-facing account. Mirrors `accounts` row (PRD.md 315-334).
/// Current balance is DERIVED (PRD.md 331) — never a field on this model.
@freezed
abstract class Account with _$Account {
  const factory Account({
    required int id,

    /// User-visible account name.
    required String name,

    /// FK -> `account_types.id`. NOT NULL.
    required int accountTypeId,

    /// Native currency value object on the read side. Drift column stays
    /// a `TEXT` FK to `currencies.code`.
    required Currency currency,

    /// Integer minor units. Scaling factor is `Currency.decimals`. Never
    /// a double. See PRD.md -> Money Storage Policy.
    @Default(0) int openingBalanceMinorUnits,

    /// Icon-registry string key, or null. Never `IconData`.
    String? icon,

    /// Palette index, or null. Never ARGB.
    int? color,

    /// Order in pickers.
    int? sortOrder,

    /// DB default `false`.
    @Default(false) bool isArchived,
  }) = _Account;
}
