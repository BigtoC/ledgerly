import 'dart:io';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/data/services/csv_file_service.dart';

void main() {
  late Directory root;
  late Directory cache;
  late Directory tmp;

  setUp(() {
    root = Directory.systemTemp.createTempSync('csv_file_service_test');
    cache = Directory('${root.path}/cache')..createSync();
    tmp = Directory('${root.path}/tmp')..createSync();
  });

  tearDown(() => root.deleteSync(recursive: true));

  CsvFileService serviceFor(
    File? picked, {
    Future<Directory> Function()? temporaryDirectory,
  }) => CsvFileService(
    openFile: () async => picked == null ? null : XFile(picked.path),
    temporaryDirectory: temporaryDirectory ?? () async => cache,
    systemTemporaryDirectory: () => tmp,
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

  test('deletes the iOS picker copy under the system temp dir', () async {
    final inbox = Directory('${tmp.path}/app-Inbox')..createSync();
    final copy = File('${inbox.path}/export.csv')..writeAsBytesSync([1]);

    await serviceFor(copy).pick();

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

  test('deletes the copy when reading it fails', () async {
    final copy = File('${cache.path}/export.csv')..writeAsBytesSync([1]);

    await expectLater(
      CsvFileService(
        openFile: () async => _UnreadableXFile(copy.path),
        temporaryDirectory: () async => cache,
        systemTemporaryDirectory: () => tmp,
      ).pick(),
      throwsA(isA<FileSystemException>()),
    );
    expect(copy.existsSync(), isFalse);
  });

  test('a file over 5 MB is returned and its cache copy deleted', () async {
    const size = 5 * 1024 * 1024 + 1;
    final copy = File('${cache.path}/big.csv')
      ..writeAsBytesSync(List.filled(size, 0x41));

    final picked = await serviceFor(copy).pick();

    expect(picked!.bytes, hasLength(size));
    expect(copy.existsSync(), isFalse);
  });
}

class _UnreadableXFile extends XFile {
  _UnreadableXFile(super.path);

  @override
  Future<Uint8List> readAsBytes() =>
      throw const FileSystemException('unreadable');
}
