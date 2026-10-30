// Unit tests for `CsvExportUseCase`: range → rows → CSV bytes → save
// dialog, with mocked repositories and a fake file service.

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:ledgerly/data/models/account.dart';
import 'package:ledgerly/data/models/category.dart';
import 'package:ledgerly/data/models/currency.dart';
import 'package:ledgerly/data/models/transaction.dart';
import 'package:ledgerly/data/repositories/account_repository.dart';
import 'package:ledgerly/data/repositories/category_repository.dart';
import 'package:ledgerly/data/repositories/transaction_repository.dart';
import 'package:ledgerly/data/services/csv_file_service.dart';
import 'package:ledgerly/data/use_cases/csv_export_use_case.dart';

class _FakeCsvFileService implements CsvFileService {
  _FakeCsvFileService({this.saved = true});

  final bool saved;
  final saves = <({String fileName, Uint8List bytes})>[];

  @override
  Future<({String name, Uint8List bytes})?> pick() =>
      throw UnimplementedError();

  @override
  Future<bool> save(String fileName, Uint8List bytes) async {
    saves.add((fileName: fileName, bytes: bytes));
    return saved;
  }
}

class _MockTransactionRepository extends Mock
    implements TransactionRepository {}

class _MockCategoryRepository extends Mock implements CategoryRepository {}

class _MockAccountRepository extends Mock implements AccountRepository {}

const _hkd = Currency(code: 'HKD', decimals: 2);

const _food = Category(
  id: 1,
  icon: 'restaurant',
  color: 0,
  type: CategoryType.expense,
  l10nKey: 'category.food',
);
const _archivedSalary = Category(
  id: 2,
  icon: 'work',
  color: 0,
  type: CategoryType.income,
  customName: 'Old salary',
  isArchived: true,
);
const _cash = Account(id: 1, name: 'Cash', accountTypeId: 1, currency: _hkd);

Transaction _tx(int id, {int categoryId = 1}) => Transaction(
  id: id,
  amountMinorUnits: 1050,
  currency: _hkd,
  categoryId: categoryId,
  accountId: 1,
  memo: 'm$id',
  date: DateTime(2026, 3, 4, 12),
  createdAt: DateTime(2026, 3, 4, 12),
  updatedAt: DateTime(2026, 3, 4, 12),
);

void main() {
  late _MockTransactionRepository txRepo;
  late _MockCategoryRepository categoryRepo;
  late _MockAccountRepository accountRepo;

  setUp(() {
    txRepo = _MockTransactionRepository();
    categoryRepo = _MockCategoryRepository();
    accountRepo = _MockAccountRepository();
    when(() => categoryRepo.watchAll(includeArchived: true))
        .thenAnswer((_) => Stream.value([_food, _archivedSalary]));
    when(() => accountRepo.watchAll(includeArchived: true))
        .thenAnswer((_) => Stream.value([_cash]));
    when(() => txRepo.getInDateRange(any(), any()))
        .thenAnswer((_) async => [_tx(1), _tx(2, categoryId: 2)]);
  });

  CsvExportUseCase useCaseWith(CsvFileService service) => CsvExportUseCase(
    fileService: service,
    transactionRepo: txRepo,
    categoryRepo: categoryRepo,
    accountRepo: accountRepo,
  );

  String nameOf(Category c) => c.customName ?? 'Food';

  test('getDateBounds forwards the repository bounds', () async {
    final bounds = (first: DateTime(2024, 1, 2), last: DateTime(2026, 3, 4));
    when(() => txRepo.getDateBounds()).thenAnswer((_) async => bounds);

    expect(await useCaseWith(_FakeCsvFileService()).getDateBounds(), bounds);
  });

  test('exports whole local days, named by the range', () async {
    final service = _FakeCsvFileService();

    final count = await useCaseWith(service).export(
      firstDay: DateTime(2024, 1, 2, 15),
      lastDay: DateTime(2026, 3, 4, 9),
      categoryName: nameOf,
    );

    expect(count, 2);
    verify(
      () => txRepo.getInDateRange(DateTime(2024, 1, 2), DateTime(2026, 3, 5)),
    ).called(1);
    expect(
      service.saves.single.fileName,
      'ledgerly_transactions_2024-01-02_2026-03-04.csv',
    );
    final lines = utf8
        .decode(service.saves.single.bytes.sublist(3))
        .split('\r\n');
    expect(lines, hasLength(3));
    expect(lines[1], contains(',expense,10.50,HKD,Food,Cash,m1,'));
    // Archived categories still resolve.
    expect(lines[2], contains(',income,10.50,HKD,Old salary,Cash,m2,'));
  });

  test('returns null when the save dialog is cancelled', () async {
    final count = await useCaseWith(_FakeCsvFileService(saved: false)).export(
      firstDay: DateTime(2026, 3, 4),
      lastDay: DateTime(2026, 3, 4),
      categoryName: nameOf,
    );

    expect(count, isNull);
  });

  test(
    'returns 0 without opening the save dialog for an empty range',
    () async {
      when(() => txRepo.getInDateRange(any(), any()))
          .thenAnswer((_) async => const []);
      final service = _FakeCsvFileService();

      final count = await useCaseWith(service).export(
        firstDay: DateTime(2026, 3, 4),
        lastDay: DateTime(2026, 3, 4),
        categoryName: nameOf,
      );

      expect(count, 0);
      expect(service.saves, isEmpty);
    },
  );

  test('reads names only after the transactions', () async {
    // Every category and account a transaction uses already exists when
    // the transactions are read, and used rows are archived, never
    // deleted, so reading names afterwards always resolves them.
    final transactions = Completer<List<Transaction>>();
    when(() => txRepo.getInDateRange(any(), any()))
        .thenAnswer((_) => transactions.future);

    final export = useCaseWith(_FakeCsvFileService()).export(
      firstDay: DateTime(2026, 3, 4),
      lastDay: DateTime(2026, 3, 4),
      categoryName: nameOf,
    );
    await Future<void>.delayed(Duration.zero);
    verifyNever(() => categoryRepo.watchAll(includeArchived: true));
    verifyNever(() => accountRepo.watchAll(includeArchived: true));

    transactions.complete([_tx(1)]);
    expect(await export, 1);
  });
}
