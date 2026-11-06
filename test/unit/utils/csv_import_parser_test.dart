import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/core/utils/csv_import_parser.dart';
import 'package:ledgerly/core/utils/transactions_csv.dart';
import 'package:ledgerly/domain/models/category.dart';
import 'package:ledgerly/domain/models/csv_import.dart';
import 'package:ledgerly/domain/models/currency.dart';
import 'package:ledgerly/domain/models/transaction.dart';

const _header = 'Account,Category,Amount,Currency,Recorded At,note,Account ID';

CsvParseResult _parse(String text) =>
    parseImportCsv(Uint8List.fromList(utf8.encode(text)));

Matcher _fileError(CsvFileErrorKind kind) =>
    throwsA(isA<CsvFileException>().having((e) => e.kind, 'kind', kind));

void main() {
  group('sample export (test/data/import_fortune_city_data.csv)', () {
    late CsvParseResult result;
    late List<String> fixtureLines;

    setUpAll(() {
      final file = File('test/data/import_fortune_city_data.csv');
      fixtureLines = file.readAsLinesSync();
      result = parseImportCsv(file.readAsBytesSync());
    });

    test('parses 105 rows with no errors', () {
      expect(result.rows, hasLength(105));
      expect(result.errors, isEmpty);
    });

    test('account counts', () {
      final counts = <String, int>{};
      for (final row in result.rows) {
        counts[row.account] = (counts[row.account] ?? 0) + 1;
      }
      expect(counts, {'Cash': 46, 'Credit Card': 56, 'Investment': 3});
    });

    test('14 distinct categories, all HKD', () {
      expect(result.rows.map((r) => r.category).toSet(), hasLength(14));
      expect(result.rows.map((r) => r.currencyCode).toSet(), {'HKD'});
    });

    test('dates span 2022/07/16 18:28 to 2026/10/30 10:39 in local time', () {
      final dates = result.rows.map((r) => r.recordedAt).toList()..sort();
      expect(dates.first, DateTime(2022, 7, 16, 18, 28));
      expect(dates.last, DateTime(2026, 10, 30, 10, 39));
      expect(dates.first.isUtc, isFalse);
    });

    test('first data row matches the fixture', () {
      final fields = fixtureLines[1].split(',');
      final dateMatch = RegExp(r'^(\d+)/(\d+)/(\d+) (\d+):(\d+)$')
          .firstMatch(fields[4])!;
      final parts = [for (var i = 1; i <= 5; i++) int.parse(dateMatch[i]!)];
      expect(
        result.rows.first,
        ParsedCsvRow(
          line: 2,
          account: fields[0],
          category: fields[1],
          amountText: fields[2],
          currencyCode: fields[3],
          recordedAt: DateTime(
            parts[0],
            parts[1],
            parts[2],
            parts[3],
            parts[4],
          ),
          memo: fields[5],
        ),
      );
    });
  });

  group('encoding and line endings', () {
    test('a leading BOM does not break the header', () {
      final result = _parse('﻿$_header\nCash,食物,42,HKD,2026/1/5 9:05,午餐,0\n');
      expect(result.rows.single.account, 'Cash');
      expect(result.errors, isEmpty);
    });

    test('CRLF and lone CR line endings', () {
      final crlf = _parse(
        '$_header\r\nCash,食物,42,HKD,2026/1/5 9:05,午餐,0\r\n'
        'Cash,交通,10,HKD,2026/1/5 9:06,,0\r\n',
      );
      expect(crlf.rows, hasLength(2));
      expect(crlf.rows.first.memo, '午餐');
      expect(crlf.rows.last.line, 3);

      final cr = _parse('$_header\rCash,食物,42,HKD,2026/1/5 9:05,午餐,0\r');
      expect(cr.rows.single.memo, '午餐');
    });

    test('invalid UTF-8 is a file error', () {
      expect(
        () => parseImportCsv(Uint8List.fromList([0x41, 0xFF, 0xFE, 0x0A])),
        _fileError(CsvFileErrorKind.notUtf8),
      );
    });
  });

  group('quoting and line numbers', () {
    test('quoted memo with a comma, "" and a newline', () {
      final result = _parse(
        '$_header\n'
        'Cash,食物,42,HKD,2026/1/5 9:05,"lunch, ""set""\nB",0\n'
        'Cash,食物,42,HKD,2026/02/30 9:05,x,0\n',
      );
      expect(result.rows.single.memo, 'lunch, "set"\nB');
      expect(result.rows.single.line, 2);
      expect(result.errors, [
        const CsvRowError(lineNumber: 4, reason: CsvRowErrorReason.invalidDate),
      ]);
    });

    test('an all-empty line is skipped but still counted', () {
      final result = _parse(
        '$_header\n'
        'Cash,食物,42,HKD,2026/1/5 9:05,a,0\n'
        '\n'
        ',,,,,,\n'
        'Cash,食物,42,HKD,2026/1/5 25:00,b,0\n',
      );
      expect(result.rows, hasLength(1));
      expect(result.errors, [
        const CsvRowError(lineNumber: 5, reason: CsvRowErrorReason.invalidDate),
      ]);
    });

    test('an unterminated quote in a memo is a parse error', () {
      final bytes = File('test/data/import_fortune_city_unterminated_quote.csv')
          .readAsBytesSync();
      expect(() => parseImportCsv(bytes), _fileError(CsvFileErrorKind.parse));
    });

    test('a space after a closing quote is a parse error', () {
      expect(
        () => _parse(
          '$_header\n'
          'Cash,食物,42,HKD,2026/1/5 9:05,"a" ,0\n'
          'Cash,食物,42,HKD,2026/1/5 9:05,c,0\n'
          'Cash,食物,42,HKD,2026/1/5 9:05,"q",0\n',
        ),
        _fileError(CsvFileErrorKind.parse),
      );
    });

    test('a letter after a closing quote is a parse error', () {
      expect(
        () => _parse(
          '$_header\n'
          'Cash,食物,42,HKD,2026/1/5 9:05,"a"x,0\n'
          'Cash,食物,42,HKD,2026/1/5 9:05,c,0\n'
          'Cash,食物,42,HKD,2026/1/5 9:05,"q",0\n',
        ),
        _fileError(CsvFileErrorKind.parse),
      );
    });

    test('an escaped "" just before the closing quote', () {
      final result = _parse(
        '$_header\n'
        'Cash,食物,42,HKD,2026/1/5 9:05,"say ""hi""",0\n'
        'Cash,食物,42,HKD,2026/1/5 9:05,"b"',
      );
      expect(result.rows.map((r) => r.memo), ['say "hi"', 'b']);
    });

    test('a quote inside an unquoted field is a literal', () {
      final result = _parse(
        '$_header\n'
        'Cash,食物,42,HKD,2026/1/5 9:05,12" pizza,0\n'
        'Cash,食物,42,HKD,2026/1/5 9:05,c,0\n',
      );
      expect(result.rows.map((r) => r.memo), ['12" pizza', 'c']);
    });
  });

  group('header', () {
    test('reordered and extra columns', () {
      final result = _parse(
        'Recorded At,Extra,Currency, Amount ,Category,Account,note\n'
        '2026/1/5 9:05,zzz,hkd,42,食物,Cash,午餐\n',
      );
      final row = result.rows.single;
      expect(row.account, 'Cash');
      expect(row.category, '食物');
      expect(row.amountText, '42');
      expect(row.currencyCode, 'HKD');
      expect(row.recordedAt, DateTime(2026, 1, 5, 9, 5));
      expect(row.memo, '午餐');
    });

    test('missing note column gives a null memo', () {
      final result = _parse(
        'Account,Category,Amount,Currency,Recorded At\n'
        'Cash,食物,42,HKD,2026/1/5 9:05\n',
      );
      expect(result.rows.single.memo, isNull);
    });

    test('blank and whitespace-only memos become null; others are kept', () {
      final result = _parse(
        '$_header\n'
        'Cash,食物,42,HKD,2026/1/5 9:05,,0\n'
        'Cash,食物,42,HKD,2026/1/5 9:05,   ,0\n'
        'Cash,食物,42,HKD,2026/1/5 9:05, =1+1 ,0\n',
      );
      expect(result.rows.map((r) => r.memo), [null, null, ' =1+1 ']);
    });

    test('missing Amount is a file error naming the column', () {
      expect(
        () => _parse(
          'Account,Category,Currency,Recorded At\nCash,食物,HKD,2026/1/5 9:05\n',
        ),
        throwsA(
          isA<CsvFileException>()
              .having((e) => e.kind, 'kind', CsvFileErrorKind.missingColumns)
              .having((e) => e.missingColumns, 'missingColumns', ['Amount']),
        ),
      );
    });

    test('header matching is case-sensitive', () {
      expect(
        () => _parse(
          'account,Category,Amount,Currency,Recorded At\n'
          'Cash,食物,42,HKD,2026/1/5 9:05\n',
        ),
        _fileError(CsvFileErrorKind.missingColumns),
      );
    });

    test('header only is empty', () {
      expect(() => _parse('$_header\n'), _fileError(CsvFileErrorKind.empty));
      expect(
        () => _parse('$_header\n\n,,,,,,\n'),
        _fileError(CsvFileErrorKind.empty),
      );
    });

    test('an empty file is empty', () {
      expect(() => _parse(''), _fileError(CsvFileErrorKind.empty));
      expect(() => _parse('\n'), _fileError(CsvFileErrorKind.empty));
    });
  });

  test('a file over 10,000 data rows is accepted in full', () {
    final csv = [
      _header,
      for (var i = 0; i < 10001; i++) 'Cash,食物,1,HKD,2026/1/5 9:05,,0',
    ].join('\n');
    expect(_parse(csv).rows, hasLength(10001));
  });

  group('row validation', () {
    CsvRowErrorReason? reasonFor(String line) {
      final result = _parse('$_header\n$line\n');
      return result.errors.isEmpty ? null : result.errors.single.reason;
    }

    test('dates', () {
      expect(reasonFor('Cash,食物,1,HKD,2026/1/5 9:05,,0'), isNull);
      expect(reasonFor('Cash,食物,1,HKD,2026/01/05 09:05:30,,0'), isNull);
      expect(
        reasonFor('Cash,食物,1,HKD,2026/02/30 9:05,,0'),
        CsvRowErrorReason.invalidDate,
      );
      expect(
        reasonFor('Cash,食物,1,HKD,2026/1/5 25:00,,0'),
        CsvRowErrorReason.invalidDate,
      );
      expect(
        reasonFor('Cash,食物,1,HKD,2026-01-05 09:05,,0'),
        CsvRowErrorReason.invalidDate,
      );
      expect(
        reasonFor('Cash,食物,1,HKD,2026/1/5 9:05:60,,0'),
        CsvRowErrorReason.invalidDate,
      );
    });

    test('seconds are kept', () {
      final result = _parse('$_header\nCash,食物,1,HKD,2026/1/5 9:05:30,,0\n');
      expect(result.rows.single.recordedAt, DateTime(2026, 1, 5, 9, 5, 30));
    });

    test('short row is columnCount', () {
      expect(reasonFor('Cash,食物,1,HKD'), CsvRowErrorReason.columnCount);
    });

    test('row without the optional trailing note is valid', () {
      final result = _parse(
        'Account,Category,Amount,Currency,Recorded At,note\n'
        'Cash,食物,1,HKD,2026/1/5 9:05\n',
      );
      expect(result.rows.single.memo, isNull);
    });

    test('blank account and category', () {
      expect(
        reasonFor('  ,食物,1,HKD,2026/1/5 9:05,,0'),
        CsvRowErrorReason.emptyAccount,
      );
      expect(
        reasonFor('Cash, ,1,HKD,2026/1/5 9:05,,0'),
        CsvRowErrorReason.emptyCategory,
      );
    });

    test('account, category, amount and currency are trimmed', () {
      final row = _parse(
        '$_header\n Credit Card , 食物 , 1.5 , hkd ,2026/1/5 9:05,,0\n',
      ).rows.single;
      expect(row.account, 'Credit Card');
      expect(row.category, '食物');
      expect(row.amountText, '1.5');
      expect(row.currencyCode, 'HKD');
    });

    test('amount and currency are not validated by the parser', () {
      final result = _parse('$_header\nCash,食物,abc,ZZZ,2026/1/5 9:05,,0\n');
      expect(result.errors, isEmpty);
      expect(result.rows.single.amountText, 'abc');
      expect(result.rows.single.currencyCode, 'ZZZ');
    });
  });

  group('Ledgerly export', () {
    const ledgerlyHeader =
        'id,date,type,amount,currency,category,account,memo,'
        'created_at,updated_at';

    CsvRowErrorReason? reasonFor(String line) {
      final result = _parse('$ledgerlyHeader\n$line\n');
      return result.errors.isEmpty ? null : result.errors.single.reason;
    }

    test('round-trips the encoder output, formula escapes removed', () {
      const eth = Currency(code: 'ETH', decimals: 18);
      final bytes = encodeTransactionsCsv(
        [
          Transaction(
            id: 7,
            uuid: '6f1d4a52-1c3b-4e8a-9f00-2b7c5d6e7f80',
            amountMinorUnits: 1234,
            currency: const Currency(code: 'HKD', decimals: 2),
            categoryId: 1,
            accountId: 1,
            memo: '=SUM(A1), "lunch"\nwith team',
            date: DateTime(2026, 10, 29),
            createdAt: DateTime(2026, 10, 30, 14, 31, 5),
            updatedAt: DateTime(2026, 10, 31, 9),
          ),
          Transaction(
            id: 8,
            amountMinorUnits: 1500000000000000001,
            currency: eth,
            categoryId: 2,
            accountId: 2,
            date: DateTime(2026, 11, 1),
            createdAt: DateTime(2026, 11, 1, 8),
            updatedAt: DateTime(2026, 11, 1, 8),
          ),
        ],
        categories: const {
          1: (name: '-Fees', type: CategoryType.expense),
          2: (name: 'Salary', type: CategoryType.income),
        },
        accountNames: const {1: '@Wallet', 2: 'Bank, HK'},
      );

      final result = parseImportCsv(bytes);

      expect(result.errors, isEmpty);
      expect(result.rows, [
        ParsedCsvRow(
          line: 2,
          account: '@Wallet',
          category: '-Fees',
          amountText: '12.34',
          currencyCode: 'HKD',
          recordedAt: DateTime(2026, 10, 30, 14, 31, 5),
          memo: '=SUM(A1), "lunch"\nwith team',
          type: CategoryType.expense,
          date: DateTime(2026, 10, 29),
          uuid: '6f1d4a52-1c3b-4e8a-9f00-2b7c5d6e7f80',
        ),
        ParsedCsvRow(
          line: 4,
          account: 'Bank, HK',
          category: 'Salary',
          amountText: '1.500000000000000001',
          currencyCode: 'ETH',
          recordedAt: DateTime(2026, 11, 1, 8),
          type: CategoryType.income,
          date: DateTime(2026, 11, 1),
        ),
      ]);
    });

    test('date keeps its written day; created_at keeps its instant', () {
      final row = _parse(
        '$ledgerlyHeader\n'
        '1,2026-10-30T00:00:00+14:00,expense,1,HKD,Food,Cash,,'
        '2026-10-30T09:15:00-03:30,2026-10-30T09:15:00-03:30\n',
      ).rows.single;
      expect(row.date, DateTime(2026, 10, 30));
      expect(row.recordedAt, DateTime.utc(2026, 10, 30, 12, 45).toLocal());
      expect(row.recordedAt.isUtc, isFalse);
    });

    test('id, memo and updated_at are optional; empty memo is null', () {
      final row = _parse(
        'date,type,amount,currency,category,account,created_at\n'
        '2026-10-30T00:00:00+08:00,income,5,HKD,Gift,Cash,'
        '2026-10-30T10:00:00+08:00\n',
      ).rows.single;
      expect(row.memo, isNull);
      expect(row.type, CategoryType.income);
      expect(row.uuid, isNull);
    });

    test('a Fortune City file never reads an id column', () {
      final row = _parse(
        '$_header,id\n'
        'Cash,食物,1,HKD,2026/10/30 10:00,,0,'
        '6f1d4a52-1c3b-4e8a-9f00-2b7c5d6e7f80\n',
      ).rows.single;
      expect(row.uuid, isNull);
    });

    test('a UUID id is read, lower-cased; any other id reads as none', () {
      const rest =
          ',2026-10-30T00:00:00+08:00,expense,1,HKD,Food,Cash,,'
          '2026-10-30T10:00:00+08:00,2026-10-30T10:00:00+08:00';
      final rows = _parse(
        [
          ledgerlyHeader,
          ' 6f1d4a52-1c3b-4e8a-9f00-2b7c5d6e7f80 $rest',
          '6F1D4A52-1C3B-4E8A-9F00-2B7C5D6E7F81$rest',
          '42$rest',
          rest,
          '6f1d4a52-1c3b-4e8a-9f00-2b7c5d6e7f8$rest',
          'x6f1d4a52-1c3b-4e8a-9f00-2b7c5d6e7f80$rest',
        ].join('\n'),
      ).rows;
      expect(rows.map((r) => r.uuid), [
        '6f1d4a52-1c3b-4e8a-9f00-2b7c5d6e7f80',
        '6f1d4a52-1c3b-4e8a-9f00-2b7c5d6e7f81',
        null,
        null,
        null,
        null,
      ]);
    });

    test('invalid type, dates, account and category', () {
      const date = '2026-10-30T00:00:00+08:00';
      expect(reasonFor('1,$date,expense,1,HKD,Food,Cash,,$date,$date'), isNull);
      expect(
        reasonFor('1,$date,transfer,1,HKD,Food,Cash,,$date,$date'),
        CsvRowErrorReason.invalidType,
      );
      expect(
        reasonFor('1,2026-02-30,expense,1,HKD,Food,Cash,,$date,$date'),
        CsvRowErrorReason.invalidDate,
      );
      expect(
        reasonFor('1,$date,expense,1,HKD,Food,Cash,,yesterday,$date'),
        CsvRowErrorReason.invalidDate,
      );
      expect(
        reasonFor('1,$date,expense,1,HKD,Food, ,,$date,$date'),
        CsvRowErrorReason.emptyAccount,
      );
      expect(
        reasonFor('1,$date,expense,1,HKD,,Cash,,$date,$date'),
        CsvRowErrorReason.emptyCategory,
      );
    });

    test('a damaged Ledgerly header names its own missing columns', () {
      expect(
        () => _parse(
          'id,date,type,amount,currency,category,account,memo\n'
          '1,2026-10-30,expense,1,HKD,Food,Cash,\n',
        ),
        throwsA(
          isA<CsvFileException>().having(
            (e) => e.missingColumns,
            'missingColumns',
            ['created_at'],
          ),
        ),
      );
    });
  });
}
