// `CurrencyRepository` — SSOT for `currencies` rows.
//
// MVP is **read-mostly** on this repo: the only writes are the first-run
// seed's `upsert` and the user-facing `updateCustomName` rename (see M3
// Stream B plan §3.10). No `delete` / `archive` — `currencies` has no
// `is_archived` column (PRD lines 263–278).
//
// Drift rules (G2, Stream B §1.5):
//   - Drift's generated `Currency` data class lives in `app_database.dart`;
//     it collides by name with the Freezed `Currency` model. We import
//     the Drift module with a `drift` prefix so call sites stay readable.
//   - Drift types never leave this file. `_toDomain` maps the Drift row to
//     the Freezed model; `_toCompanion` is used only on the write path.
//
// Phase 2: `upsert` is deliberately generic enough to register tokens
// (ETH, USDC, …). `watchAll({includeTokens: true})` is the Phase-2 switch.
// Do NOT add `delete` / `archive` here without a schema change.

import 'package:drift/drift.dart';

import '../database/app_database.dart' as drift;
import '../database/daos/currency_dao.dart';
import '../models/currency.dart';
import 'repository_exceptions.dart';

/// Abstract contract consumed by controllers (M5) and by the first-run
/// seed in Stream C. Public API frozen by Stream B §1.1.
abstract class CurrencyRepository {
  /// Emits the current set of known currencies whenever the underlying
  /// row set changes. Ordered by `sort_order NULLS LAST, code ASC`.
  ///
  /// [includeTokens] defaults to `false` — MVP ships only fiats. Phase 2
  /// callers pass `true`. The Drift column `is_token` is the discriminator.
  Stream<List<Currency>> watchAll({bool includeTokens = false});

  /// One-shot read by PK. Returns null when the code is not registered.
  Future<Currency?> getByCode(String code);

  /// Insert-or-update by PK `code`. Used by the first-run seed and by
  /// Phase 2 token registration. Idempotent on the same `code`.
  ///
  /// Safety rails:
  ///   - Throws [CurrencyDecimalsMismatchException] when an existing row
  ///     has a different `decimals`; never silently invalidates stored
  ///     minor-unit amounts (see Stream B §3.8).
  ///   - Preserves the existing `custom_name` on update — user renames
  ///     flow through [updateCustomName], not this method (Stream B §3.10,
  ///     Stream C §12 Q7).
  ///   - When [Currency.sortOrder] is null on an existing row, the
  ///     previously stored `sort_order` is preserved.
  Future<void> upsert(Currency currency);

  /// Writes `currencies.custom_name` for an existing row. Leaves every
  /// other column untouched — same pattern as `categories` /
  /// `account_types` renames (Guardrail G7).
  ///
  /// - `customName == null` clears the override.
  /// - Empty / whitespace-only strings normalize to `null`.
  /// - Throws [CurrencyNotFoundException] when `code` has no row.
  Future<void> updateCustomName(String code, String? customName);
}

/// Concrete Drift-backed implementation of [CurrencyRepository].
final class DriftCurrencyRepository implements CurrencyRepository {
  DriftCurrencyRepository(this._db);

  final drift.AppDatabase _db;

  CurrencyDao get _dao => _db.currencyDao;

  // ---------- Mapping ----------

  Currency _toDomain(drift.Currency row) => Currency(
    code: row.code,
    decimals: row.decimals,
    symbol: row.symbol,
    nameL10nKey: row.nameL10nKey,
    customName: row.customName,
    isToken: row.isToken,
    sortOrder: row.sortOrder,
  );

  // ---------- Reads ----------

  @override
  Stream<List<Currency>> watchAll({bool includeTokens = false}) {
    return _dao.watchAll().map((rows) {
      final filtered = includeTokens
          ? rows
          : rows.where((r) => !r.isToken).toList(growable: false);
      return filtered.map(_toDomain).toList(growable: false);
    });
  }

  @override
  Future<Currency?> getByCode(String code) async {
    final row = await _dao.findByCode(code);
    return row == null ? null : _toDomain(row);
  }

  // ---------- Writes ----------

  @override
  Future<void> upsert(Currency currency) async {
    final existing = await _dao.findByCode(currency.code);

    if (existing != null && existing.decimals != currency.decimals) {
      throw CurrencyDecimalsMismatchException(
        code: currency.code,
        existingDecimals: existing.decimals,
        attemptedDecimals: currency.decimals,
      );
    }

    // Preserve stored sort_order when the caller did not set one.
    final effectiveSortOrder = currency.sortOrder ?? existing?.sortOrder;

    // `custom_name` is deliberately OMITTED from this companion. `upsert`
    // is the seed path; user renames flow through `updateCustomName`.
    // See Stream B §2.1 `_toCompanion` rule / §3.10.
    final companion = drift.CurrenciesCompanion(
      code: Value(currency.code),
      decimals: Value(currency.decimals),
      symbol: Value(currency.symbol),
      nameL10nKey: Value(currency.nameL10nKey),
      isToken: Value(currency.isToken),
      sortOrder: Value(effectiveSortOrder),
    );

    if (existing == null) {
      await _dao.insert(companion);
    } else {
      await _dao.updateRow(companion);
    }
  }

  @override
  Future<void> updateCustomName(String code, String? customName) async {
    final existing = await _dao.findByCode(code);
    if (existing == null) {
      throw CurrencyNotFoundException(code);
    }

    final normalized = (customName == null || customName.trim().isEmpty)
        ? null
        : customName;

    // Drift's `replace` does a full-row update; every column must be set
    // on the companion. Omitting a column would reset it to its default.
    // We copy every other field from the stored row and touch only
    // `custom_name`.
    await _dao.updateRow(
      drift.CurrenciesCompanion(
        code: Value(existing.code),
        decimals: Value(existing.decimals),
        symbol: Value(existing.symbol),
        nameL10nKey: Value(existing.nameL10nKey),
        customName: Value(normalized),
        isToken: Value(existing.isToken),
        sortOrder: Value(existing.sortOrder),
      ),
    );
  }
}
