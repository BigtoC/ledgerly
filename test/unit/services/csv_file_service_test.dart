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

  group('save', () {
    /// Mimics the iOS plugin: writes `tmp/<fileName>`, then the user saves
    /// ([saved] true) or cancels.
    CsvFileService saverFor({
      required bool saved,
      List<String>? calls,
      bool isIOS = true,
    }) => CsvFileService(
      saveFile: ({required fileName, required bytes}) async {
        calls?.add(fileName);
        File('${tmp.path}/$fileName').writeAsBytesSync(bytes);
        return saved;
      },
      temporaryDirectory: () async => cache,
      systemTemporaryDirectory: () => tmp,
      isIOS: isIOS,
    );

    test('returns true and deletes the iOS temp copy once saved', () async {
      final calls = <String>[];

      final saved = await saverFor(
        saved: true,
        calls: calls,
      ).save('export.csv', Uint8List.fromList([1, 2]));

      expect(saved, isTrue);
      expect(calls, ['export.csv']);
      expect(File('${tmp.path}/export.csv').existsSync(), isFalse);
    });

    test('returns false and still deletes the copy when cancelled', () async {
      final saved = await saverFor(saved: false)
          .save('export.csv', Uint8List.fromList([1]));

      expect(saved, isFalse);
      expect(File('${tmp.path}/export.csv').existsSync(), isFalse);
    });

    test('keeps a file the user saved into temp on other platforms', () async {
      // On desktop the user may pick the temp dir itself; that file is the
      // export, not a plugin copy.
      final saved = await saverFor(
        saved: true,
        isIOS: false,
      ).save('export.csv', Uint8List.fromList([1]));

      expect(saved, isTrue);
      expect(File('${tmp.path}/export.csv').existsSync(), isTrue);
    });

    test('succeeds when no temp copy exists', () async {
      final service = CsvFileService(
        saveFile: ({required fileName, required bytes}) async => true,
        temporaryDirectory: () async => cache,
        systemTemporaryDirectory: () => tmp,
        isIOS: true,
      );

      expect(await service.save('export.csv', Uint8List(0)), isTrue);
    });

    test('deletes the copy when saving throws', () async {
      final service = CsvFileService(
        saveFile: ({required fileName, required bytes}) async {
          File('${tmp.path}/$fileName').writeAsBytesSync(bytes);
          throw const FileSystemException('save failed');
        },
        temporaryDirectory: () async => cache,
        systemTemporaryDirectory: () => tmp,
        isIOS: true,
      );

      await expectLater(
        service.save('export.csv', Uint8List.fromList([1])),
        throwsA(isA<FileSystemException>()),
      );
      expect(File('${tmp.path}/export.csv').existsSync(), isFalse);
    });
  });
}

class _UnreadableXFile extends XFile {
  _UnreadableXFile(super.path);

  @override
  Future<Uint8List> readAsBytes() =>
      throw const FileSystemException('unreadable');
}
