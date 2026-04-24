// Shared typed exceptions thrown from the repository layer.
//
// Ownership: this module is owned by M3 Stream B and consumed by
// Streams A, B, and C (see `docs/plans/m3-repositories-seed/` plans).
// Stream-A-only category exceptions stay local to `category_repository.dart`
// unless later reused across streams.
//
// Only errors that cross stream boundaries belong here:
//   - `CurrencyNotFoundException`         — Transaction + Account + Currency
//   - `CurrencyDecimalsMismatchException` — Currency (write-path safety rail)
//   - `AccountTypeNotFoundException`      — AccountType (write-path FK miss)
//   - `AccountTypeInUseException`         — AccountType (G6 archive-instead)
//   - `AccountInUseException`             — Account (G6 archive-instead)
//
// All exceptions are `const`-constructible so callers can materialize them
// at compile time. `toString()` is `'<runtimeType>: <message>'`, matching
// the `sealed class RepositoryException` template in Stream B plan §1.4.

/// Base for every typed repository exception. Never thrown directly —
/// subclasses carry the specific failure.
abstract class RepositoryException implements Exception {
  const RepositoryException(this.message);

  /// Human-readable description. Intended for developer logs and test
  /// assertions; user-facing copy is assembled by controllers from the
  /// subclass fields.
  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// `currencies` row for the requested code does not exist.
///
/// **Thrown on write paths only** — `AccountRepository.save`,
/// `AccountTypeRepository.save` / `upsertSeeded`, and
/// `TransactionRepository.save` pre-check the FK before inserting.
/// Read-path `_toDomain` helpers use a `!` non-null assert instead
/// (unreachable under `foreign_keys = ON` + write-side pre-check).
/// Aligns with Stream A §12 Q4 / Stream B §12 Q3.
class CurrencyNotFoundException extends RepositoryException {
  const CurrencyNotFoundException(this.code)
    : super('Currency not registered: $code');

  /// The currency code that was not registered in the `currencies` table.
  final String code;
}

/// Attempt to upsert a currency whose `decimals` disagrees with the row
/// already stored for this code.
///
/// Guards against token metadata changing decimal width across Ankr
/// revisions, which would silently invalidate every stored amount in
/// that currency. See Stream B §3.8.
class CurrencyDecimalsMismatchException extends RepositoryException {
  const CurrencyDecimalsMismatchException({
    required this.code,
    required this.existingDecimals,
    required this.attemptedDecimals,
  }) : super(
         'Currency $code already registered with $existingDecimals '
         'decimals; refusing to overwrite with $attemptedDecimals.',
       );

  /// The currency code whose decimals would have changed.
  final String code;

  /// Decimal width currently stored in the DB.
  final int existingDecimals;

  /// Decimal width the caller tried to write.
  final int attemptedDecimals;
}

/// `account_types` row for the given id does not exist.
class AccountTypeNotFoundException extends RepositoryException {
  const AccountTypeNotFoundException(this.id)
    : super('Account type not found: $id');

  /// The account type id that was not found.
  final int id;
}

/// Hard-delete of an `account_types` row blocked by a referencing
/// `accounts` row. Caller should archive instead.
class AccountTypeInUseException extends RepositoryException {
  const AccountTypeInUseException(this.id)
    : super('Account type $id is in use and cannot be deleted.');

  /// The account type id whose deletion is blocked.
  final int id;
}

/// Hard-delete of an `accounts` row blocked by a referencing
/// `transactions` row. Caller should archive instead.
class AccountInUseException extends RepositoryException {
  const AccountInUseException(this.id)
    : super('Account $id is in use and cannot be deleted.');

  /// The account id whose deletion is blocked.
  final int id;
}

/// Transaction currency does not match the referenced account currency.
class TransactionAccountCurrencyMismatchException extends RepositoryException {
  const TransactionAccountCurrencyMismatchException({
    required this.accountId,
    required this.accountCurrencyCode,
    required this.transactionCurrencyCode,
  }) : super(
         'Transaction currency $transactionCurrencyCode must match '
         'account $accountId currency $accountCurrencyCode.',
       );

  final int accountId;
  final String accountCurrencyCode;
  final String transactionCurrencyCode;
}
