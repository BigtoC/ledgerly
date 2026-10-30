// CsvImportScreen widget tests, with a fake controller whose `build()`
// returns a fixed state and whose commands only record calls.
//
// Covers every state, the preview's balance note, the Import button,
// the tier 2b New badge, the account decision sheet (bottom sheet and
// 600dp dialog), the category type toggle, invalid rows without field
// values, the pop block while committing, and 2x text scale.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

import 'package:ledgerly/data/models/account.dart';
import 'package:ledgerly/data/models/account_type.dart';
import 'package:ledgerly/data/models/category.dart';
import 'package:ledgerly/data/models/csv_import.dart';
import 'package:ledgerly/data/models/currency.dart';
import 'package:ledgerly/features/settings/csv_import/csv_import_controller.dart';
import 'package:ledgerly/features/settings/csv_import/csv_import_matcher.dart';
import 'package:ledgerly/features/settings/csv_import/csv_import_screen.dart';
import 'package:ledgerly/features/settings/csv_import/csv_import_state.dart';
import 'package:ledgerly/l10n/app_localizations.dart';

class _FakeCsvImportController extends CsvImportController {
  _FakeCsvImportController(this._initial, this.calls);

  final CsvImportState _initial;
  final List<Object> calls;

  @override
  CsvImportState build() => _initial;

  @override
  Future<void> pickFile() async => calls.add('pickFile');

  @override
  void setAccountResolution(String csvValue, AccountResolution resolution) =>
      calls.add((csvValue, resolution));

  @override
  void setNewCategoryType(String csvValue, CategoryType type) =>
      calls.add((csvValue, type));

  @override
  Future<void> commit() async => calls.add('commit');

  @override
  void reset() => calls.add('reset');
}

const _hkd = Currency(code: 'HKD', decimals: 2);

const _cash = Account(id: 1, name: 'Cash', accountTypeId: 1, currency: _hkd);
const _archivedCard = Account(
  id: 3,
  name: 'Credit Card',
  accountTypeId: 1,
  currency: _hkd,
  isArchived: true,
);
const _investmentType = AccountType(
  id: 2,
  l10nKey: 'accountType.investment',
  icon: 'trending_up',
  color: 0,
);

const _food = Category(
  id: 10,
  icon: 'restaurant',
  color: 0,
  type: CategoryType.expense,
  l10nKey: 'category.food',
);
const _salary = Category(
  id: 11,
  icon: 'work',
  color: 0,
  type: CategoryType.income,
  l10nKey: 'category.income.salary',
);
const _otherIncome = Category(
  id: 12,
  icon: 'payments',
  color: 0,
  type: CategoryType.income,
  l10nKey: 'category.income.other',
);

const _cashMatch = CsvAccountMatch(
  csvValue: 'Cash',
  rowCount: 46,
  tier: CsvAccountTier.name,
  resolution: AccountResolution.existing(1),
  currencyCode: 'HKD',
  options: [_cash],
);
const _investmentMatch = CsvAccountMatch(
  csvValue: 'Investment',
  rowCount: 3,
  tier: CsvAccountTier.typeWithoutAccount,
  resolution: AccountResolution.createAccount(
    name: 'Investment',
    accountTypeId: 2,
    currencyCode: 'HKD',
  ),
  matchedType: _investmentType,
  currencyCode: 'HKD',
  options: [_cash],
);
const _cardMatch = CsvAccountMatch(
  csvValue: 'Credit Card',
  rowCount: 56,
  tier: CsvAccountTier.none,
  currencyCode: 'HKD',
  options: [_cash, _archivedCard],
);

const _foodEntry = CsvCategoryEntry(
  csvValue: '食物',
  rowCount: 26,
  resolution: CategoryResolution.existing(10),
  category: _food,
);
const _incomeEntry = CsvCategoryEntry(
  csvValue: '收入',
  rowCount: 10,
  resolution: CategoryResolution.incomeByNote(
    salaryCategoryId: 11,
    otherCategoryId: 12,
  ),
  salaryCategory: _salary,
  otherIncomeCategory: _otherIncome,
  salaryRowCount: 1,
);
const _repaymentEntry = CsvCategoryEntry(
  csvValue: '還款',
  rowCount: 3,
  resolution: CategoryResolution.create(name: '還款', type: CategoryType.expense),
);

CsvImportPreview _preview({
  List<CsvAccountMatch> accounts = const [
    _cashMatch,
    _investmentMatch,
    _cardMatch,
  ],
  List<CsvCategoryEntry> categories = const [
    _foodEntry,
    _incomeEntry,
    _repaymentEntry,
  ],
  List<CsvRowError> errors = const [
    CsvRowError(lineNumber: 7, reason: CsvRowErrorReason.invalidAmount),
    CsvRowError(
      lineNumber: 9,
      reason: CsvRowErrorReason.unknownCurrency,
      currencyCode: 'XYZ',
    ),
  ],
  int importCount = 105,
  int duplicateCount = 2,
  bool canCommit = false,
}) {
  return CsvImportPreview(
    fileName: 'fortune.csv',
    importCount: importCount,
    firstRecordedAt: importCount == 0 ? null : DateTime(2022, 7, 16, 18, 28),
    lastRecordedAt: importCount == 0 ? null : DateTime(2026, 10, 30, 10, 39),
    errors: errors,
    accounts: accounts,
    categories: categories,
    duplicateCount: duplicateCount,
    canCommit: canCommit,
  );
}

@Dependencies([CsvImportController])
Future<List<Object>> _pump(
  WidgetTester tester,
  CsvImportState state, {
  double textScale = 1.0,
  Size size = const Size(400, 800),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final calls = <Object>[];
  final container = ProviderContainer(
    overrides: [
      csvImportControllerProvider.overrideWith(
        () => _FakeCsvImportController(state, calls),
      ),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      // A fresh app per call, so one test can pump several states.
      key: UniqueKey(),
      container: container,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        // A root page under the screen, so pop behaviour is observable.
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const CsvImportScreen(),
                  ),
                ),
                child: const Text('OPEN'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('OPEN'));
  // Not pumpAndSettle: the loading and committing spinners never settle.
  await _settleRoute(tester);
  return calls;
}

Future<void> _settleRoute(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
}

Finder _confirmButton() => find.byKey(const ValueKey('csvImportConfirmButton'));

FilledButton _confirmWidget(WidgetTester tester) =>
    tester.widget<FilledButton>(_confirmButton());

@Dependencies([CsvImportController])
Future<void> _scrollTo(
  WidgetTester tester,
  Finder finder, {
  double delta = 200,
}) async {
  await tester.scrollUntilVisible(
    finder,
    delta,
    scrollable: find
        .descendant(
          of: find.byType(CsvImportScreen),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}

@Dependencies([CsvImportController])
void main() {
  group('states', () {
    testWidgets('CI01: idle shows the intro, privacy note and picker button', (
      tester,
    ) async {
      final calls = await _pump(tester, const CsvImportState.idle());

      expect(find.text('Import from CSV'), findsOneWidget);
      expect(
        find.text('Import transactions exported from Fortune City.'),
        findsOneWidget,
      );
      expect(
        find.text('The file is read on this device only. Nothing is uploaded.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Choose CSV file'));
      await tester.pump();
      expect(calls, ['pickFile']);
    });

    testWidgets('CI02: loading shows a spinner and the reading label', (
      tester,
    ) async {
      final calls = <Object>[];
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final container = ProviderContainer(
        overrides: [
          csvImportControllerProvider.overrideWith(
            () =>
                _FakeCsvImportController(const CsvImportState.loading(), calls),
          ),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: CsvImportScreen(),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Reading file…'), findsOneWidget);
    });

    testWidgets('CI03: each file failure shows its message and a retry', (
      tester,
    ) async {
      final cases = <CsvImportState, String>{
        const CsvImportState.failure(CsvFileErrorKind.tooLarge):
            'This file is larger than 5 MB.',
        const CsvImportState.failure(CsvFileErrorKind.notUtf8):
            'This file is not UTF-8 text.',
        const CsvImportState.failure(CsvFileErrorKind.empty):
            'This file has no transactions.',
        const CsvImportState.failure(
          CsvFileErrorKind.missingColumns,
          missingColumns: ['Amount', 'Currency'],
        ): 'Missing columns: Amount, Currency',
        const CsvImportState.failure(CsvFileErrorKind.tooManyRows):
            'This file has more than 10000 rows.',
        const CsvImportState.failure(CsvFileErrorKind.parse):
            'This file could not be read as CSV.',
        const CsvImportState.failure(CsvFileErrorKind.readFailed):
            'This file could not be read.',
        const CsvImportState.failure(CsvFileErrorKind.commitFailed):
            'Import failed. Nothing was imported.',
      };
      for (final MapEntry(key: state, value: message) in cases.entries) {
        final calls = await _pump(tester, state);
        expect(find.text(message), findsOneWidget, reason: '$state');
        await tester.tap(find.text('Choose another file'));
        await tester.pump();
        expect(calls, ['pickFile'], reason: '$state');
      }
    });

    testWidgets('CI04: committing shows a spinner and blocks pop', (
      tester,
    ) async {
      await _pump(tester, const CsvImportState.committing());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Importing…'), findsOneWidget);

      await tester.binding.handlePopRoute();
      await _settleRoute(tester);
      expect(find.byType(CsvImportScreen), findsOneWidget);
    });

    testWidgets('CI05: preview allows pop', (tester) async {
      await _pump(tester, _preview());

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(CsvImportScreen), findsNothing);
    });

    testWidgets('CI06: done shows the result and Done pops to the caller', (
      tester,
    ) async {
      await _pump(
        tester,
        const CsvImportState.done(
          result: CsvImportResult(
            importedCount: 105,
            duplicateCount: 2,
            createdAccountCount: 2,
            createdCategoryCount: 3,
            currencyCodes: {'HKD'},
          ),
          invalidRowCount: 4,
        ),
      );

      expect(find.text('Import complete'), findsOneWidget);
      expect(find.text('Imported 105 transactions'), findsOneWidget);
      expect(
        find.text('Skipped 2 duplicates and 4 invalid rows'),
        findsOneWidget,
      );
      expect(find.text('Created 2 accounts and 3 categories'), findsOneWidget);

      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(find.byType(CsvImportScreen), findsNothing);
    });
  });

  group('preview', () {
    testWidgets('CI07: header, balance note, duplicates and account entries', (
      tester,
    ) async {
      await _pump(tester, _preview());

      expect(find.text('fortune.csv'), findsOneWidget);
      expect(find.text('105 transactions'), findsOneWidget);
      expect(find.text('Jul 16, 2022 – Oct 30, 2026'), findsOneWidget);
      expect(
        find.text(
          'Imported transactions change the balances of the accounts they '
          'go into.',
        ),
        findsOneWidget,
      );
      expect(find.text('Accounts'), findsOneWidget);
      expect(find.text('Cash'), findsAtLeastNWidgets(1));

      await _scrollTo(
        tester,
        find.text('2 rows already exist and will be skipped'),
      );
      expect(
        find.text('2 rows already exist and will be skipped'),
        findsOneWidget,
      );
    });

    testWidgets('CI08: tier 2b shows New and is not marked as pending; '
        'tier 3 needs a decision', (tester) async {
      await _pump(tester, _preview());

      final investment = find.byKey(
        const ValueKey('csvImportAccount:Investment'),
      );
      expect(
        find.descendant(of: investment, matching: find.text('New')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: investment,
          matching: find.text('Create account "Investment" (Investment)'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: investment,
          matching: find.text('Choose where these go'),
        ),
        findsNothing,
      );

      final card = find.byKey(const ValueKey('csvImportAccount:Credit Card'));
      expect(
        find.descendant(of: card, matching: find.text('Choose where these go')),
        findsOneWidget,
      );
    });

    testWidgets('CI09: Import is disabled while a decision is pending', (
      tester,
    ) async {
      await _pump(tester, _preview());

      expect(find.text('Import 105 transactions'), findsOneWidget);
      expect(_confirmWidget(tester).onPressed, isNull);
    });

    testWidgets('CI10: Import is enabled and commits when canCommit', (
      tester,
    ) async {
      final calls = await _pump(tester, _preview(canCommit: true));

      expect(_confirmWidget(tester).onPressed, isNotNull);
      await tester.tap(_confirmButton());
      await tester.pump();
      expect(calls, ['commit']);
    });

    testWidgets('CI11: 0 rows to import shows "Nothing new to import"', (
      tester,
    ) async {
      await _pump(
        tester,
        _preview(
          importCount: 0,
          duplicateCount: 105,
          accounts: const [],
          categories: const [],
          errors: const [],
        ),
      );

      expect(
        find.descendant(
          of: _confirmButton(),
          matching: find.text('Nothing new to import'),
        ),
        findsOneWidget,
      );
      expect(_confirmWidget(tester).onPressed, isNull);
    });

    testWidgets('CI12: categories split into existing and created', (
      tester,
    ) async {
      await _pump(tester, _preview());

      await _scrollTo(tester, find.text('Will use existing'));
      expect(find.text('Categories'), findsOneWidget);
      expect(find.text('Will use existing'), findsOneWidget);
      final food = find.byKey(const ValueKey('csvImportCategory:食物'));
      await _scrollTo(tester, food);
      expect(
        find.descendant(of: food, matching: find.textContaining('Food')),
        findsOneWidget,
      );
      final income = find.byKey(const ValueKey('csvImportCategory:收入'));
      await _scrollTo(tester, income);
      expect(
        find.descendant(
          of: income,
          matching: find.text('Salary · 1 transaction'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: income,
          matching: find.text('Other Income · 9 transactions'),
        ),
        findsOneWidget,
      );
      await _scrollTo(tester, find.text('Will be created'));
      expect(find.text('Will be created'), findsOneWidget);
    });

    testWidgets('CI13: the type toggle calls setNewCategoryType', (
      tester,
    ) async {
      final calls = await _pump(tester, _preview());

      final toggle = find.byKey(const ValueKey('csvImportCategoryType:還款'));
      await _scrollTo(tester, toggle);
      await tester.tap(
        find.descendant(of: toggle, matching: find.text('Income')),
      );
      await tester.pump();
      expect(calls, [('還款', CategoryType.income)]);
    });

    testWidgets('CI14: invalid rows show line and reason, no field values', (
      tester,
    ) async {
      await _pump(tester, _preview());

      final header = find.text('2 invalid rows will be skipped');
      await _scrollTo(tester, header);
      expect(find.text('Line 7: invalid amount'), findsNothing);
      await tester.tap(header);
      await tester.pumpAndSettle();

      await _scrollTo(tester, find.text('Line 9: unknown currency XYZ'));
      expect(find.text('Line 7: invalid amount'), findsOneWidget);
      expect(find.text('Line 9: unknown currency XYZ'), findsOneWidget);
    });
  });

  group('decision sheet', () {
    testWidgets('CI15: tier 3 offers existing accounts and create type + '
        'account, with archived same-name accounts labelled', (tester) async {
      final calls = await _pump(tester, _preview());

      await tester.tap(
        find.byKey(const ValueKey('csvImportAccount:Credit Card')),
      );
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.text('Use an existing account'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('csvImportSheetAccount:1')),
        findsOneWidget,
      );
      expect(find.text('Credit Card (archived)'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('csvImportSheetCreateAccount')),
        findsNothing,
      );
      final createBoth = find.byKey(
        const ValueKey('csvImportSheetCreateTypeAndAccount'),
      );
      expect(
        find.descendant(
          of: createBoth,
          matching: find.text('Create account type and account "Credit Card"'),
        ),
        findsOneWidget,
      );

      await tester.tap(createBoth);
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsNothing);
      expect(calls, [
        (
          'Credit Card',
          const AccountResolution.createTypeAndAccount(
            name: 'Credit Card',
            currencyCode: 'HKD',
          ),
        ),
      ]);
    });

    testWidgets('CI16: tier 2b offers all three options with option 2 '
        'selected', (tester) async {
      final calls = await _pump(tester, _preview());

      await tester.tap(
        find.byKey(const ValueKey('csvImportAccount:Investment')),
      );
      await tester.pumpAndSettle();

      ListTile tile(String key) => tester.widget<ListTile>(
        find.descendant(
          of: find.byKey(ValueKey(key)),
          matching: find.byType(ListTile),
        ),
      );
      expect(tile('csvImportSheetAccount:1').selected, isFalse);
      expect(tile('csvImportSheetCreateAccount').selected, isTrue);
      expect(tile('csvImportSheetCreateTypeAndAccount').selected, isFalse);

      await tester.tap(find.byKey(const ValueKey('csvImportSheetAccount:1')));
      await tester.pumpAndSettle();
      expect(calls, [('Investment', const AccountResolution.existing(1))]);
    });

    testWidgets('CI17: dismissing the sheet changes nothing', (tester) async {
      final calls = await _pump(tester, _preview());

      await tester.tap(
        find.byKey(const ValueKey('csvImportAccount:Credit Card')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();
      expect(calls, isEmpty);
    });

    testWidgets('CI18: at 600dp the sheet is a dialog', (tester) async {
      await _pump(tester, _preview(), size: const Size(800, 1000));

      await tester.tap(
        find.byKey(const ValueKey('csvImportAccount:Credit Card')),
      );
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsNothing);
      expect(find.byType(Dialog), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(Dialog),
          matching: find.byKey(
            const ValueKey('csvImportSheetCreateTypeAndAccount'),
          ),
        ),
        findsOneWidget,
      );
    });
  });

  group('2x text scale', () {
    testWidgets('CI19: idle, preview, sheet and done survive 2x', (
      tester,
    ) async {
      await _pump(tester, const CsvImportState.idle(), textScale: 2);
      expect(tester.takeException(), isNull);

      await _pump(tester, _preview(), textScale: 2);
      expect(tester.takeException(), isNull);
      final toggle = find.byKey(const ValueKey('csvImportCategoryType:還款'));
      await _scrollTo(tester, toggle);
      expect(tester.takeException(), isNull);
      await _scrollTo(
        tester,
        find.byKey(const ValueKey('csvImportAccount:Credit Card')),
        delta: -200,
      );
      await tester.tap(
        find.byKey(const ValueKey('csvImportAccount:Credit Card')),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await _pump(
        tester,
        const CsvImportState.done(
          result: CsvImportResult(
            importedCount: 105,
            duplicateCount: 0,
            createdAccountCount: 2,
            createdCategoryCount: 3,
            currencyCodes: {'HKD'},
          ),
          invalidRowCount: 0,
        ),
        textScale: 2,
      );
      expect(tester.takeException(), isNull);
    });
  });
}
