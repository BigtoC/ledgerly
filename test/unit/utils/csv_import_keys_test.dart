import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/core/utils/csv_import_keys.dart';

void main() {
  group('normalizeImportKey', () {
    test('trims and folds Latin case', () {
      expect(normalizeImportKey('  Credit Card \n'), 'credit card');
    });

    test('compares CJK exactly', () {
      expect(normalizeImportKey(' 薪資 '), '薪資');
      expect(normalizeImportKey('薪资'), isNot(normalizeImportKey('薪資')));
    });
  });

  group('isSalaryNote', () {
    final notes = {'salary', '薪资'};

    test('matches a memo after normalizing it', () {
      expect(isSalaryNote(' SALARY ', notes), isTrue);
      expect(isSalaryNote('薪资', notes), isTrue);
    });

    test('a null or other memo is not a salary note', () {
      expect(isSalaryNote(null, notes), isFalse);
      expect(isSalaryNote('bonus', notes), isFalse);
    });
  });
}
