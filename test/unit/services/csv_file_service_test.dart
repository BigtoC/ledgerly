import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/data/services/csv_file_service.dart';

void main() {
  late Directory root;
  late Directory cache;

  setUp(() {
    root = Directory.systemTemp.createTempSync('csv_file_service_test');
    cache = Directory('${root.path}/cache')..createSync();
  });

  tearDown(() => root.deleteSync(recursive: true));

  CsvFileService serviceFor(
    File? picked, {
    Future<Directory> Function()? temporaryDirectory,
  }) => CsvFileService(
    openFile: () async => picked == null ? null : XFile(picked.path),
    temporaryDirectory: temporaryDirectory ?? () async => cache,
  );

  test('returns null when the pick is cancelled', () async {
    expect(await serviceFor(null).pick(), isNull);
  });

  test('returns the name and bytes and deletes the cache copy', () async {
    final copy = File('${cache.path}/export.csv')..writeAsBytesSync([1, 2, 3]);

    final picked = await serviceFor(copy).pick();

    expect(picked!.name, 'export.csv');
    expect(picked.bytes, [1, 2, 3]);
    expect(copy.existsSync(), isFalse);
  });

  test('leaves a file outside the temporary directory alone', () async {
    final original = File('${root.path}/cache-sibling.csv')
      ..writeAsBytesSync([1]);

    await serviceFor(original).pick();

    expect(original.existsSync(), isTrue);
  });

  test('ignores a failure to delete the copy', () async {
    final copy = File('${cache.path}/export.csv')..writeAsBytesSync([1]);

    final picked = await serviceFor(
      copy,
      temporaryDirectory: () => throw const FileSystemException('no cache'),
    ).pick();

    expect(picked!.bytes, [1]);
  });

  test('a file over 5 MB throws and its cache copy is still deleted', () async {
    final copy = File('${cache.path}/big.csv')
      ..writeAsBytesSync(List.filled(CsvFileService.maxBytes + 1, 0x41));

    await expectLater(
      serviceFor(copy).pick(),
      throwsA(isA<CsvFileTooLargeException>()),
    );
    expect(copy.existsSync(), isFalse);
  });

  test('a file of exactly 5 MB is accepted', () async {
    final copy = File('${cache.path}/edge.csv')
      ..writeAsBytesSync(List.filled(CsvFileService.maxBytes, 0x41));

    final picked = await serviceFor(copy).pick();

    expect(picked!.bytes, hasLength(CsvFileService.maxBytes));
  });
}
