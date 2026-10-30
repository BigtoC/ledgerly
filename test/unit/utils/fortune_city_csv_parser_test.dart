import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/core/utils/fortune_city_csv_parser.dart';
import 'package:ledgerly/data/models/csv_import.dart';

const _header = 'Account,Category,Amount,Currency,Recorded At,note,Account ID';

FortuneCityCsvParseResult _parse(String text) =>
    parseFortuneCityCsv(Uint8List.fromList(utf8.encode(text)));

Matcher _fileError(CsvFileErrorKind kind) =>
    throwsA(isA<CsvFileException>().having((e) => e.kind, 'kind', kind));

void main() {
  group('sample export (test/data/import_fortune_city_data.csv)', () {
    late FortuneCityCsvParseResult result;
    late List<String> fixtureLines;

    setUpAll(() {
      final file = File('test/data/import_fortune_city_data.csv');
      fixtureLines = file.readAsLinesSync();
      result = parseFortuneCityCsv(file.readAsBytesSync());
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

    test('line numbers follow the file', () {
      expect(result.rows.last.line, 106);
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
        () => parseFortuneCityCsv(Uint8List.fromList([0x41, 0xFF, 0xFE, 0x0A])),
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
      expect(
        () => parseFortuneCityCsv(bytes),
        _fileError(CsvFileErrorKind.parse),
      );
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
}
