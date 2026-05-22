import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/data/models/currency.dart';
import 'package:ledgerly/data/models/transaction.dart';
import 'package:ledgerly/features/analysis/charts/slice_drilldown_data.dart';

void main() {
  test('SliceDrilldownData stores rows + pendingDeleteId', () {
    final usd = const Currency(code: 'USD', decimals: 2);
    final tx = Transaction(
      id: 1,
      amountMinorUnits: 100,
      currency: usd,
      categoryId: 1,
      accountId: 1,
      date: DateTime(2026, 5, 18),
      createdAt: DateTime(2026, 5, 18),
      updatedAt: DateTime(2026, 5, 18),
    );
    final data = SliceDrilldownData(rows: [tx]);
    expect(data.rows, hasLength(1));
    expect(data.pendingDeleteId, isNull);
  });

  test('copyWith updates pendingDeleteId without dropping rows', () {
    final usd = const Currency(code: 'USD', decimals: 2);
    final tx = Transaction(
      id: 7,
      amountMinorUnits: 700,
      currency: usd,
      categoryId: 1,
      accountId: 1,
      date: DateTime(2026, 5, 18),
      createdAt: DateTime(2026, 5, 18),
      updatedAt: DateTime(2026, 5, 18),
    );
    final data = SliceDrilldownData(rows: [tx]);
    final pending = data.copyWith(pendingDeleteId: 7);

    expect(pending.pendingDeleteId, 7);
    expect(pending.rows.single.id, 7);
  });
}
