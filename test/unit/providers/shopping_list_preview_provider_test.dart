import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:ledgerly/app/providers/repository_providers.dart';
import 'package:ledgerly/data/models/shopping_list_item.dart';
import 'package:ledgerly/data/repositories/shopping_list_repository.dart';
import 'package:ledgerly/features/shopping_list/shopping_list_providers.dart';

class _MockShoppingListRepository extends Mock
    implements ShoppingListRepository {}

ShoppingListItem _item({required int id, String? memo}) => ShoppingListItem(
  id: id,
  categoryId: 1,
  accountId: 1,
  memo: memo,
  draftDate: DateTime(2026, 5, 1),
  createdAt: DateTime(2026, 5, 1),
  updatedAt: DateTime(2026, 5, 1),
);

void main() {
  test(
    'shoppingListPreviewProvider uses limited preview rows and total-count stream',
    () async {
      final repo = _MockShoppingListRepository();
      when(() => repo.watchAll(limit: 3)).thenAnswer(
        (_) => Stream.value([
          _item(id: 4, memo: 'Fourth'),
          _item(id: 3, memo: 'Third'),
          _item(id: 2, memo: 'Second'),
        ]),
      );
      when(() => repo.watchCount()).thenAnswer((_) => Stream.value(4));

      final container = ProviderContainer(
        overrides: [shoppingListRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      final preview = await container.read(shoppingListPreviewProvider.future);

      expect(preview.preview.map((item) => item.memo), [
        'Fourth',
        'Third',
        'Second',
      ]);
      expect(preview.totalCount, 4);

      verify(() => repo.watchAll(limit: 3)).called(1);
      verify(() => repo.watchCount()).called(1);
      verifyNever(() => repo.watchAll());
    },
  );
}
