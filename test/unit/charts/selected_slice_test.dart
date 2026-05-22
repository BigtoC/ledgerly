import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/features/analysis/charts/selected_slice.dart';

void main() {
  group('SelectedSlice equality', () {
    test('two SelectedCategorySlice with same fields are equal', () {
      const a = SelectedSlice.category(7, currencyCode: 'USD');
      const b = SelectedSlice.category(7, currencyCode: 'USD');
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('SelectedCategorySlice with different currencyCode is not equal', () {
      const a = SelectedSlice.category(7, currencyCode: 'USD');
      const b = SelectedSlice.category(7, currencyCode: 'EUR');
      expect(a, isNot(equals(b)));
    });

    test('SelectedCategorySlice with null currencyCode differs from set', () {
      const a = SelectedSlice.category(7);
      const b = SelectedSlice.category(7, currencyCode: 'USD');
      expect(a, isNot(equals(b)));
    });

    test('SelectedAccountSlice equality', () {
      const a = SelectedSlice.account(3);
      const b = SelectedSlice.account(3);
      expect(a, equals(b));
    });

    test('SelectedCurrencySlice equality', () {
      const a = SelectedSlice.currency('JPY');
      const b = SelectedSlice.currency('JPY');
      expect(a, equals(b));
      const c = SelectedSlice.currency('USD');
      expect(a, isNot(equals(c)));
    });

    test('cross-variant inequality', () {
      const cat = SelectedSlice.category(1);
      const acc = SelectedSlice.account(1);
      const cur = SelectedSlice.currency('USD');
      expect(cat, isNot(equals(acc)));
      expect(cat, isNot(equals(cur)));
      expect(acc, isNot(equals(cur)));
    });
  });
}
