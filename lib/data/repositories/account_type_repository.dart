// `AccountTypeRepository` — SSOT for `account_types` rows.
//
// See `docs/plans/m3-repositories-seed/stream-b-account-currency.md`
// for the full specification. Drift data classes never leave this file.
//
// Invariants enforced here (and only here):
//   - Seeded-row identity is the `l10nKey`; `save` / `rename` never
//     mutate `l10nKey` on an existing row (G7 — PRD.md 336-337).
//   - Archive-instead-of-delete when at least one `accounts` row
//     references this type (G6 — PRD.md 339).
//   - `defaultCurrency.code` must exist in `currencies` on every write
//     path — the repository throws a typed
//     [CurrencyNotFoundException] before Drift's SQL layer surfaces an
//     opaque `SqliteException` (G2 — PRD.md 348).
//   - `icon` is a string key, `color` is a palette index. Never
//     `IconData`, never ARGB (G8 — PRD.md 340).

import 'package:drift/drift.dart' show Value;

import '../database/app_database.dart' as drift;
import '../database/daos/account_type_dao.dart';
import '../models/account_type.dart';
import '../models/currency.dart';
import 'currency_repository.dart';
import 'repository_exceptions.dart';

/// SSOT for `account_types`. Owns every write path to the Drift
/// `account_types` table. Drift data classes never leave this file.
abstract class AccountTypeRepository {
  /// Emits all known account types. `includeArchived` defaults to
  /// `false` (picker-safe); settings / admin screens pass `true`.
  /// Ordered by `sort_order NULLS LAST, id ASC`.
  Stream<List<AccountType>> watchAll({bool includeArchived = false});

  /// One-shot read by PK. Returns null when the id is absent.
  Future<AccountType?> getById(int id);

  /// One-shot read by seeded-row identity `l10nKey`. Returns null
  /// when no row carries that key.
  Future<AccountType?> getByL10nKey(String l10nKey);

  /// Insert when `accountType.id == 0`, otherwise update.
  /// Returns the row id.
  ///
  /// Validates `defaultCurrency.code` against `currencies` on every
  /// write path and throws [CurrencyNotFoundException] on miss.
  ///
  /// On update, the stored `l10nKey` is preserved — seed-identity
  /// changes go through [upsertSeeded] and user renames go through
  /// [rename]. Stream B §3.4 / §12 Q4 (re-read and preserve).
  Future<int> save(AccountType accountType);

  /// Seed-only insert-or-update keyed by [l10nKey]. Used by Stream C's
  /// first-run seed so seeded account-type writes stay idempotent while
  /// user-facing writes continue to flow through [save]. Returns the
  /// row id.
  ///
  /// Signature frozen by Stream C §7.1 / §12 Q5 (2026-04-22) — named
  /// parameters, not an `AccountType` value object, because the seed
  /// never surfaces `customName` / `isArchived` / `id`.
  ///
  /// - `icon` is an icon-registry string key (G8).
  /// - `color` is a palette index into the append-only `color_palette`
  ///   list (G8).
  /// - `defaultCurrency` must reference a row in `currencies`; the
  ///   repository pre-checks via [CurrencyRepository.getByCode] and
  ///   throws [CurrencyNotFoundException] on miss.
  /// - On update, preserves any `customName` and `isArchived` already
  ///   on the stored row; only the seeded fields are rewritten.
  Future<int> upsertSeeded({
    required String l10nKey,
    required String icon,
    required int color,
    required Currency defaultCurrency,
    required int sortOrder,
  });

  /// Update only the `custom_name` column for the given id. Every
  /// other column — especially `l10nKey` — is preserved.
  ///
  /// - `customName == null` clears the override; callers render the
  ///   localized label from `l10nKey`.
  /// - Empty / whitespace-only strings normalize to `null`.
  /// - Throws [AccountTypeNotFoundException] when [id] has no row.
  Future<void> updateCustomName(int id, String? customName);

  /// Convenience rename — mirrors [updateCustomName] but rejects null /
  /// empty inputs with a type error at the call site. Kept for
  /// parity with `CategoryRepository.rename` and the plan's §3.3
  /// template.
  Future<void> rename({required int id, required String customName});

  /// Marks the row archived. Archiving does NOT cascade to accounts
  /// of this type (PRD 358).
  Future<void> archive(int id);

  /// Hard-delete. Only succeeds when no `accounts` row references
  /// this type. Otherwise throws [AccountTypeInUseException] — callers
  /// are expected to call [archive] instead. PRD 339 + guardrail G6.
  Future<void> delete(int id);

  /// Cheap existence probe. Returns true when any `accounts` row
  /// references this type, regardless of `is_archived`.
  Future<bool> isReferenced(int id);
}

/// Concrete Drift-backed implementation of [AccountTypeRepository].
final class DriftAccountTypeRepository implements AccountTypeRepository {
  DriftAccountTypeRepository(this._db, this._currencies);

  final drift.AppDatabase _db;
  final CurrencyRepository _currencies;

  AccountTypeDao get _dao => _db.accountTypeDao;

  // ---------- Reads ----------

  @override
  Stream<List<AccountType>> watchAll({bool includeArchived = false}) {
    // §12 Q6: branch at the DAO boundary — skip archived-row currency
    // lookups when the caller does not want them.
    final rowsStream = includeArchived ? _dao.watchAll() : _dao.watchActive();
    return rowsStream.asyncMap((rows) async {
      final codes = rows
          .map((r) => r.defaultCurrency)
          .whereType<String>()
          .toSet();
      final byCode = <String, Currency>{};
      for (final code in codes) {
        final c = await _currencies.getByCode(code);
        // Non-null under `foreign_keys = ON` + write-side pre-check;
        // see §2.2 / §12 Q3.
        byCode[code] = c!;
      }
      return rows.map((r) => _rowToDomain(r, byCode)).toList(growable: false);
    });
  }

  @override
  Future<AccountType?> getById(int id) async {
    final row = await _dao.findById(id);
    if (row == null) return null;
    return _toDomain(row);
  }

  @override
  Future<AccountType?> getByL10nKey(String l10nKey) async {
    final row = await _dao.findByL10nKey(l10nKey);
    if (row == null) return null;
    return _toDomain(row);
  }

  // ---------- Writes ----------

  @override
  Future<int> save(AccountType accountType) async {
    // Write-path FK pre-check — throws typed
    // `CurrencyNotFoundException` before Drift surfaces a SqliteError.
    if (accountType.defaultCurrency != null) {
      final c = await _currencies.getByCode(accountType.defaultCurrency!.code);
      if (c == null) {
        throw CurrencyNotFoundException(accountType.defaultCurrency!.code);
      }
    }

    if (accountType.id == 0) {
      // Insert — caller-supplied `l10nKey` is authoritative.
      return _dao.insert(_toCompanion(accountType));
    }

    // Update — re-read stored row to preserve identity (§12 Q4 Option B).
    final existing = await _dao.findById(accountType.id);
    if (existing == null) {
      throw AccountTypeNotFoundException(accountType.id);
    }
    await _dao.updateRow(
      drift.AccountTypesCompanion(
        id: Value(accountType.id),
        // Stored l10nKey wins; caller-supplied value is ignored on update.
        l10nKey: Value(existing.l10nKey),
        customName: Value(accountType.customName),
        defaultCurrency: Value(accountType.defaultCurrency?.code),
        icon: Value(accountType.icon),
        color: Value(accountType.color),
        sortOrder: Value(
          accountType.sortOrder == 0 ? null : accountType.sortOrder,
        ),
        isArchived: Value(accountType.isArchived),
      ),
    );
    return accountType.id;
  }

  @override
  Future<int> upsertSeeded({
    required String l10nKey,
    required String icon,
    required int color,
    required Currency defaultCurrency,
    required int sortOrder,
  }) async {
    // Write-path FK pre-check — AT22.
    final resolved = await _currencies.getByCode(defaultCurrency.code);
    if (resolved == null) {
      throw CurrencyNotFoundException(defaultCurrency.code);
    }

    final existing = await _dao.findByL10nKey(l10nKey);
    if (existing == null) {
      // Insert path.
      return _dao.insert(
        drift.AccountTypesCompanion.insert(
          l10nKey: Value(l10nKey),
          icon: icon,
          color: color,
          defaultCurrency: Value(defaultCurrency.code),
          sortOrder: Value(sortOrder),
        ),
      );
    }

    // Update seeded fields, preserve user-owned `customName` and
    // `isArchived` on the stored row.
    await _dao.updateRow(
      drift.AccountTypesCompanion(
        id: Value(existing.id),
        l10nKey: Value(l10nKey),
        customName: Value(existing.customName),
        defaultCurrency: Value(defaultCurrency.code),
        icon: Value(icon),
        color: Value(color),
        sortOrder: Value(sortOrder),
        isArchived: Value(existing.isArchived),
      ),
    );
    return existing.id;
  }

  @override
  Future<void> updateCustomName(int id, String? customName) async {
    final existing = await _dao.findById(id);
    if (existing == null) {
      throw AccountTypeNotFoundException(id);
    }

    final normalized = (customName == null || customName.trim().isEmpty)
        ? null
        : customName;

    await _dao.updateRow(
      drift.AccountTypesCompanion(
        id: Value(id),
        l10nKey: Value(existing.l10nKey),
        customName: Value(normalized),
        defaultCurrency: Value(existing.defaultCurrency),
        icon: Value(existing.icon),
        color: Value(existing.color),
        sortOrder: Value(existing.sortOrder),
        isArchived: Value(existing.isArchived),
      ),
    );
  }

  @override
  Future<void> rename({required int id, required String customName}) async {
    // Delegates to `updateCustomName` — same preservation template.
    await updateCustomName(id, customName);
  }

  @override
  Future<void> archive(int id) async {
    await _dao.archive(id);
  }

  @override
  Future<void> delete(int id) async {
    final inUse = await _dao.hasReferencingAccounts(id);
    if (inUse) {
      throw AccountTypeInUseException(id);
    }
    await _dao.deleteById(id);
  }

  @override
  Future<bool> isReferenced(int id) {
    return _dao.hasReferencingAccounts(id);
  }

  // ---------- Private mapping ----------

  Future<AccountType> _toDomain(drift.AccountTypeRow row) async {
    final defaultCurrency = row.defaultCurrency == null
        ? null
        // Non-null under `foreign_keys = ON` + write-side pre-check;
        // see §2.2 / §12 Q3.
        : (await _currencies.getByCode(row.defaultCurrency!))!;
    return AccountType(
      id: row.id,
      l10nKey: row.l10nKey,
      customName: row.customName,
      defaultCurrency: defaultCurrency,
      icon: row.icon,
      color: row.color,
      sortOrder: row.sortOrder ?? 0,
      isArchived: row.isArchived,
    );
  }

  AccountType _rowToDomain(
    drift.AccountTypeRow row,
    Map<String, Currency> byCode,
  ) {
    return AccountType(
      id: row.id,
      l10nKey: row.l10nKey,
      customName: row.customName,
      defaultCurrency: row.defaultCurrency == null
          ? null
          : byCode[row.defaultCurrency!]!,
      icon: row.icon,
      color: row.color,
      sortOrder: row.sortOrder ?? 0,
      isArchived: row.isArchived,
    );
  }

  drift.AccountTypesCompanion _toCompanion(AccountType t) {
    return drift.AccountTypesCompanion(
      id: t.id == 0 ? const Value.absent() : Value(t.id),
      l10nKey: Value(t.l10nKey),
      customName: Value(t.customName),
      defaultCurrency: Value(t.defaultCurrency?.code),
      icon: Value(t.icon),
      color: Value(t.color),
      sortOrder: Value(t.sortOrder == 0 ? null : t.sortOrder),
      isArchived: Value(t.isArchived),
    );
  }
}
