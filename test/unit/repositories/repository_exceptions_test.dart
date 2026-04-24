// Unit tests for `repository_exceptions.dart` — the shared repository-layer
// error hierarchy defined by M3 Stream B §1.4.
//
// These assertions lock the public surface that Streams A, B, and C all
// import. Keep them strict; anything they permit becomes cross-stream API.

import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/data/repositories/repository_exceptions.dart';
import 'package:ledgerly/data/repositories/user_preferences_repository.dart';

void main() {
  group('RepositoryException (sealed base)', () {
    test('is an Exception subtype', () {
      const exception = CurrencyNotFoundException('USD');
      expect(exception, isA<Exception>());
      expect(exception, isA<RepositoryException>());
    });

    test('toString() is "<runtimeType>: <message>"', () {
      const exception = CurrencyNotFoundException('USD');
      expect(
        exception.toString(),
        'CurrencyNotFoundException: Currency not registered: USD',
      );
    });

    test('message is exposed on the base class', () {
      const RepositoryException exception = CurrencyNotFoundException('USD');
      expect(exception.message, 'Currency not registered: USD');
    });
  });

  group('CurrencyNotFoundException', () {
    test('carries the offending code and a human-readable message', () {
      const exception = CurrencyNotFoundException('XYZ');
      expect(exception.code, 'XYZ');
      expect(exception.message, 'Currency not registered: XYZ');
    });

    test('is const-constructible', () {
      const a = CurrencyNotFoundException('USD');
      const b = CurrencyNotFoundException('USD');
      expect(identical(a, b), isTrue);
    });
  });

  group('CurrencyDecimalsMismatchException', () {
    test('carries code + existing + attempted decimal widths', () {
      const exception = CurrencyDecimalsMismatchException(
        code: 'USD',
        existingDecimals: 2,
        attemptedDecimals: 4,
      );
      expect(exception.code, 'USD');
      expect(exception.existingDecimals, 2);
      expect(exception.attemptedDecimals, 4);
      expect(
        exception.message,
        'Currency USD already registered with 2 decimals; '
        'refusing to overwrite with 4.',
      );
    });

    test('extends RepositoryException', () {
      const exception = CurrencyDecimalsMismatchException(
        code: 'USD',
        existingDecimals: 2,
        attemptedDecimals: 4,
      );
      expect(exception, isA<RepositoryException>());
    });
  });

  group('AccountTypeNotFoundException', () {
    test('carries the id and a human-readable message', () {
      const exception = AccountTypeNotFoundException(42);
      expect(exception.id, 42);
      expect(exception.message, 'Account type not found: 42');
    });

    test('extends RepositoryException', () {
      const exception = AccountTypeNotFoundException(1);
      expect(exception, isA<RepositoryException>());
    });
  });

  group('AccountTypeInUseException', () {
    test('carries the id and explains the in-use failure', () {
      const exception = AccountTypeInUseException(7);
      expect(exception.id, 7);
      expect(
        exception.message,
        'Account type 7 is in use and cannot be deleted.',
      );
    });

    test('extends RepositoryException', () {
      const exception = AccountTypeInUseException(7);
      expect(exception, isA<RepositoryException>());
    });
  });

  group('AccountInUseException', () {
    test('carries the id and explains the in-use failure', () {
      const exception = AccountInUseException(3);
      expect(exception.id, 3);
      expect(exception.message, 'Account 3 is in use and cannot be deleted.');
    });

    test('extends RepositoryException', () {
      const exception = AccountInUseException(3);
      expect(exception, isA<RepositoryException>());
    });
  });

  group('TransactionAccountCurrencyMismatchException', () {
    test('carries account id and both currency codes', () {
      const exception = TransactionAccountCurrencyMismatchException(
        accountId: 7,
        accountCurrencyCode: 'USD',
        transactionCurrencyCode: 'JPY',
      );

      expect(exception.accountId, 7);
      expect(exception.accountCurrencyCode, 'USD');
      expect(exception.transactionCurrencyCode, 'JPY');
      expect(
        exception.message,
        'Transaction currency JPY must match account 7 currency USD.',
      );
    });

    test('extends RepositoryException', () {
      const exception = TransactionAccountCurrencyMismatchException(
        accountId: 7,
        accountCurrencyCode: 'USD',
        transactionCurrencyCode: 'JPY',
      );
      expect(exception, isA<RepositoryException>());
    });
  });

  group('PreferenceDecodeException', () {
    test('extends RepositoryException', () {
      final exception = PreferenceDecodeException(
        'theme_mode',
        '"purple"',
        ArgumentError('bad value'),
      );

      expect(exception, isA<RepositoryException>());
    });

    test('retains key/rawValue/cause and shared toString shape', () {
      final exception = PreferenceDecodeException(
        'default_currency',
        '123',
        const FormatException('wrong type'),
      );

      expect(exception.key, 'default_currency');
      expect(exception.rawValue, '123');
      expect(exception.cause, isA<FormatException>());
      expect(
        exception.toString(),
        'PreferenceDecodeException: '
        'user_preferences[default_currency] corrupted: '
        'FormatException: wrong type',
      );
    });
  });
}
