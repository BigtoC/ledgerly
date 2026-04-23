import 'package:freezed_annotation/freezed_annotation.dart';

part 'currency.freezed.dart';

/// Currency descriptor. Mirrors `currencies` row (PRD.md 259-273).
/// `decimals` is the SSOT for minor-unit scaling (PRD.md Money Storage Policy).
@freezed
abstract class Currency with _$Currency {
  const factory Currency({
    /// PK. ISO 4217 for fiat, symbol for tokens.
    required String code,

    /// 2 for USD, 0 for JPY, 18 for ETH/ERC-20.
    required int decimals,

    /// Display symbol: `$`, `¥`, `NT$`, ...
    String? symbol,

    /// Localized-name key (SQL column: `name_l10n_key`). Seeded currencies
    /// use `currency.<code>` (e.g. `currency.usd`); nullable so Phase 2
    /// tokens can omit it when the symbol is itself the display name.
    String? nameL10nKey,

    /// Optional user override for the display name. When non-null, M5
    /// renders this instead of the localized label resolved from
    /// `nameL10nKey`. Written via `CurrencyRepository.updateCustomName`;
    /// never touched by `upsert`. Same rename pattern as
    /// `categories.custom_name` / `account_types.custom_name`.
    String? customName,

    /// Phase 2 token flag. DB default `false`.
    @Default(false) bool isToken,

    /// Order in pickers.
    int? sortOrder,
  }) = _Currency;
}
