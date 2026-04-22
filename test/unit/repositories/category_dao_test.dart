import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/data/database/app_database.dart';

void main() {
  group('CategoryDao schema', () {
    late AppDatabase database;

    setUp(() {
      database = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await database.close();
    });

    test('categories table stays flat without a parent hierarchy', () async {
      final columns = await database
          .customSelect('PRAGMA table_info(categories)')
          .get();
      final columnNames = columns
          .map((row) => row.read<String>('name'))
          .toSet();

      expect(columnNames, isNot(contains('parent_id')));

      final indexes = await database
          .customSelect('PRAGMA index_list(categories)')
          .get();
      final indexNames = indexes.map((row) => row.read<String>('name')).toSet();

      expect(indexNames, isNot(contains('categories_parent_idx')));
    });
  });
}
