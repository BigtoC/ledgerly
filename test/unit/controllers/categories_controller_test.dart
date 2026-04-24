// CategoriesController unit tests (plan §3.3, §7).
//
// Covers:
//   - loading → data stream transitions.
//   - Per-row `CategoryRowAffordance` computation (archive for seeded,
//     archive for referenced custom, delete for unused custom).
//   - Seeded + unreferenced → Archive, not Delete (plan §12 risk #3).
//   - Archived rows are excluded from the state.
//   - Commands route to the repository and surface typed exceptions via
//     `AsyncError`.
//
// Repository is mocked via `mocktail`; no live DB.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:ledgerly/app/providers/repository_providers.dart';
import 'package:ledgerly/data/models/category.dart';
import 'package:ledgerly/data/repositories/category_repository.dart';
import 'package:ledgerly/features/categories/categories_controller.dart';
import 'package:ledgerly/features/categories/categories_state.dart';

class _MockCategoryRepository extends Mock implements CategoryRepository {}

Category _c({
  required int id,
  required CategoryType type,
  String? l10nKey,
  String? customName,
  int? sortOrder,
  bool isArchived = false,
}) => Category(
  id: id,
  icon: 'category',
  color: 0,
  type: type,
  l10nKey: l10nKey,
  customName: customName,
  sortOrder: sortOrder,
  isArchived: isArchived,
);

void main() {
  setUpAll(() {
    registerFallbackValue(
      const Category(id: 0, icon: 'category', color: 0, type: CategoryType.expense),
    );
  });

  group('CategoriesController', () {
    late _MockCategoryRepository repo;
    late StreamController<List<Category>> rowsCtrl;

    setUp(() {
      repo = _MockCategoryRepository();
      rowsCtrl = StreamController<List<Category>>.broadcast();
      when(
        () => repo.watchAll(includeArchived: false),
      ).thenAnswer((_) => rowsCtrl.stream);
      when(() => repo.isReferenced(any())).thenAnswer((_) async => false);
    });

    tearDown(() async {
      await rowsCtrl.close();
    });

    ProviderContainer makeContainer() {
      return ProviderContainer(
        overrides: [categoryRepositoryProvider.overrideWithValue(repo)],
      );
    }

    Future<CategoriesState> waitForData(ProviderContainer c) async {
      for (var i = 0; i < 100; i++) {
        final s = c.read(categoriesControllerProvider);
        if (s is AsyncData<CategoriesState> && s.value is CategoriesData) {
          return s.value;
        }
        await Future<void>.delayed(Duration.zero);
      }
      throw StateError('CategoriesController never produced data');
    }

    test('C01: starts in loading and transitions to data on first emit', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      container.listen(categoriesControllerProvider, (_, _) {});

      expect(
        container.read(categoriesControllerProvider),
        isA<AsyncLoading<CategoriesState>>(),
      );

      await Future<void>.delayed(Duration.zero);
      rowsCtrl.add([
        _c(id: 1, type: CategoryType.expense, customName: 'Food'),
        _c(id: 2, type: CategoryType.income, customName: 'Salary'),
      ]);

      final state = await waitForData(container) as CategoriesData;
      expect(state.expense, hasLength(1));
      expect(state.income, hasLength(1));
      expect(state.expense.single.category.customName, 'Food');
      expect(state.income.single.category.customName, 'Salary');
    });

    test('C02: seeded row shows Archive affordance regardless of usage', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      container.listen(categoriesControllerProvider, (_, _) {});
      await Future<void>.delayed(Duration.zero);

      // Seeded + unreferenced must still be Archive (risk #3).
      when(() => repo.isReferenced(1)).thenAnswer((_) async => false);

      rowsCtrl.add([
        _c(id: 1, type: CategoryType.expense, l10nKey: 'category.food'),
      ]);
      final state = await waitForData(container) as CategoriesData;
      expect(state.expense.single.affordance, CategoryRowAffordance.archive);
    });

    test('C03: custom unreferenced row shows Delete', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      container.listen(categoriesControllerProvider, (_, _) {});
      await Future<void>.delayed(Duration.zero);

      when(() => repo.isReferenced(5)).thenAnswer((_) async => false);
      rowsCtrl.add([
        _c(id: 5, type: CategoryType.expense, customName: 'Groceries'),
      ]);
      final state = await waitForData(container) as CategoriesData;
      expect(state.expense.single.affordance, CategoryRowAffordance.delete);
    });

    test('C04: custom referenced row shows Archive', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      container.listen(categoriesControllerProvider, (_, _) {});
      await Future<void>.delayed(Duration.zero);

      when(() => repo.isReferenced(7)).thenAnswer((_) async => true);
      rowsCtrl.add([
        _c(id: 7, type: CategoryType.expense, customName: 'Hobby'),
      ]);
      final state = await waitForData(container) as CategoriesData;
      expect(state.expense.single.affordance, CategoryRowAffordance.archive);
    });

    test('C05: archived rows are excluded', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      container.listen(categoriesControllerProvider, (_, _) {});
      await Future<void>.delayed(Duration.zero);

      // Even though `watchAll(includeArchived: false)` should filter at
      // the repo layer, the controller defensively skips `isArchived`
      // rows too so stale emissions don't leak past archive flows.
      rowsCtrl.add([
        _c(
          id: 1,
          type: CategoryType.expense,
          customName: 'A',
          isArchived: true,
        ),
        _c(id: 2, type: CategoryType.expense, customName: 'B'),
      ]);
      final state = await waitForData(container) as CategoriesData;
      expect(state.expense.map((v) => v.category.id), [2]);
    });

    test('C06: expense/income rows are grouped into the matching section', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      container.listen(categoriesControllerProvider, (_, _) {});
      await Future<void>.delayed(Duration.zero);

      rowsCtrl.add([
        _c(id: 1, type: CategoryType.expense, customName: 'A'),
        _c(id: 2, type: CategoryType.income, customName: 'B'),
        _c(id: 3, type: CategoryType.expense, customName: 'C'),
      ]);
      final state = await waitForData(container) as CategoriesData;
      expect(state.expense.map((v) => v.category.id), [1, 3]);
      expect(state.income.map((v) => v.category.id), [2]);
    });

    test('C07: sort by sortOrder asc, nulls last, then display name', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      container.listen(categoriesControllerProvider, (_, _) {});
      await Future<void>.delayed(Duration.zero);

      rowsCtrl.add([
        _c(id: 1, type: CategoryType.expense, customName: 'Zebra'),
        _c(
          id: 2,
          type: CategoryType.expense,
          customName: 'Beta',
          sortOrder: 1,
        ),
        _c(
          id: 3,
          type: CategoryType.expense,
          customName: 'Alpha',
          sortOrder: 0,
        ),
      ]);
      final state = await waitForData(container) as CategoriesData;
      expect(state.expense.map((v) => v.category.id), [3, 2, 1]);
    });

    test('C08: createCategory delegates to repo.save with id=0', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      container.listen(categoriesControllerProvider, (_, _) {});
      await Future<void>.delayed(Duration.zero);
      rowsCtrl.add(const []);
      await waitForData(container);

      final draft = _c(
        id: 99,
        type: CategoryType.expense,
        customName: 'New',
      );
      final saved = draft.copyWith(id: 42);
      when(() => repo.save(any())).thenAnswer((_) async => saved);

      final result = await container
          .read(categoriesControllerProvider.notifier)
          .createCategory(draft);

      expect(result.id, 42);
      final captured =
          verify(() => repo.save(captureAny())).captured.single as Category;
      expect(captured.id, 0);
      expect(captured.customName, 'New');
    });

    test('C09: renameCategory delegates to repo.rename', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      container.listen(categoriesControllerProvider, (_, _) {});
      await Future<void>.delayed(Duration.zero);
      rowsCtrl.add(const []);
      await waitForData(container);

      final after = _c(
        id: 7,
        type: CategoryType.expense,
        customName: 'X',
      );
      when(() => repo.rename(7, 'X')).thenAnswer((_) async => after);

      final result = await container
          .read(categoriesControllerProvider.notifier)
          .renameCategory(7, 'X');
      expect(result.customName, 'X');
      verify(() => repo.rename(7, 'X')).called(1);
    });

    test('C10: archiveCategory delegates to repo.archive', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      container.listen(categoriesControllerProvider, (_, _) {});
      await Future<void>.delayed(Duration.zero);
      rowsCtrl.add(const []);
      await waitForData(container);

      final archived = _c(
        id: 3,
        type: CategoryType.expense,
        customName: 'Y',
        isArchived: true,
      );
      when(() => repo.archive(3)).thenAnswer((_) async => archived);

      final result = await container
          .read(categoriesControllerProvider.notifier)
          .archiveCategory(3);
      expect(result.isArchived, isTrue);
      verify(() => repo.archive(3)).called(1);
    });

    test('C11: undoArchive writes isArchived=false via save', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      container.listen(categoriesControllerProvider, (_, _) {});
      await Future<void>.delayed(Duration.zero);
      rowsCtrl.add(const []);
      await waitForData(container);

      final stored = _c(
        id: 4,
        type: CategoryType.expense,
        customName: 'Z',
        isArchived: true,
      );
      when(() => repo.getById(4)).thenAnswer((_) async => stored);
      when(
        () => repo.save(any()),
      ).thenAnswer((_) async => stored.copyWith(isArchived: false));

      await container
          .read(categoriesControllerProvider.notifier)
          .undoArchive(4);

      final captured =
          verify(() => repo.save(captureAny())).captured.single as Category;
      expect(captured.id, 4);
      expect(captured.isArchived, isFalse);
    });

    test('C12: deleteCategory surfaces CategoryInUseException', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      container.listen(categoriesControllerProvider, (_, _) {});
      await Future<void>.delayed(Duration.zero);
      rowsCtrl.add(const []);
      await waitForData(container);

      when(
        () => repo.delete(11),
      ).thenThrow(const CategoryInUseException(11));

      expect(
        () => container
            .read(categoriesControllerProvider.notifier)
            .deleteCategory(11),
        throwsA(isA<CategoryInUseException>()),
      );
    });

    test('C13: createCategory surfaces CategoryTypeLockedException', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      container.listen(categoriesControllerProvider, (_, _) {});
      await Future<void>.delayed(Duration.zero);
      rowsCtrl.add(const []);
      await waitForData(container);

      when(
        () => repo.save(any()),
      ).thenThrow(const CategoryTypeLockedException(1));

      expect(
        () => container
            .read(categoriesControllerProvider.notifier)
            .createCategory(
              _c(id: 1, type: CategoryType.income, customName: 'X'),
            ),
        throwsA(isA<CategoryTypeLockedException>()),
      );
    });

    test('C14: reorder writes sortOrder per list index', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      container.listen(categoriesControllerProvider, (_, _) {});
      await Future<void>.delayed(Duration.zero);
      rowsCtrl.add(const []);
      await waitForData(container);

      final a = _c(
        id: 10,
        type: CategoryType.expense,
        customName: 'A',
      );
      final b = _c(
        id: 20,
        type: CategoryType.expense,
        customName: 'B',
      );
      when(() => repo.getById(10)).thenAnswer((_) async => a);
      when(() => repo.getById(20)).thenAnswer((_) async => b);
      when(() => repo.save(any())).thenAnswer(
        (inv) async => inv.positionalArguments.first as Category,
      );

      await container
          .read(categoriesControllerProvider.notifier)
          .reorder([20, 10]);

      final captures = verify(() => repo.save(captureAny())).captured;
      expect(captures, hasLength(2));
      final first = captures[0] as Category;
      final second = captures[1] as Category;
      expect(first.id, 20);
      expect(first.sortOrder, 0);
      expect(second.id, 10);
      expect(second.sortOrder, 1);
    });

    test('C15: updateIconColor preserves other fields', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      container.listen(categoriesControllerProvider, (_, _) {});
      await Future<void>.delayed(Duration.zero);
      rowsCtrl.add(const []);
      await waitForData(container);

      final existing = _c(
        id: 50,
        type: CategoryType.expense,
        customName: 'Name',
      );
      when(() => repo.getById(50)).thenAnswer((_) async => existing);
      when(() => repo.save(any())).thenAnswer(
        (inv) async => inv.positionalArguments.first as Category,
      );

      await container
          .read(categoriesControllerProvider.notifier)
          .updateIconColor(id: 50, icon: 'home', color: 3);

      final captured =
          verify(() => repo.save(captureAny())).captured.single as Category;
      expect(captured.id, 50);
      expect(captured.icon, 'home');
      expect(captured.color, 3);
      expect(captured.customName, 'Name');
      expect(captured.type, CategoryType.expense);
    });
  });
}
