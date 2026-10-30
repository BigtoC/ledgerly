import 'dart:io';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart' as file_selector;
import 'package:path_provider/path_provider.dart';

/// The picked file is larger than [CsvFileService.maxBytes]. Defined here
/// because services may not import models; the CSV import use case
/// translates it into its own file error.
class CsvFileTooLargeException implements Exception {
  const CsvFileTooLargeException();
}

/// Picks a CSV file through the system picker and returns its bytes. Knows
/// nothing about the CSV format.
///
/// The platform pickers copy the chosen file: `file_selector_android` into
/// the app's cache directory, the iOS document picker into the app's
/// `tmp/`. That copy holds financial data, so [pick] deletes it after
/// reading. The file name is never logged.
class CsvFileService {
  CsvFileService({
    Future<file_selector.XFile?> Function()? openFile,
    Future<Directory> Function()? temporaryDirectory,
    Directory Function()? systemTemporaryDirectory,
  }) : _openFile = openFile ?? _openCsvFile,
       _temporaryDirectory = temporaryDirectory ?? getTemporaryDirectory,
       _systemTemporaryDirectory =
           systemTemporaryDirectory ?? (() => Directory.systemTemp);

  /// Largest file [pick] reads: 5 MB. A parse guard, not a memory guard:
  /// on Android the platform has already read the whole file.
  static const maxBytes = 5 * 1024 * 1024;

  static const _csvTypeGroup = file_selector.XTypeGroup(
    label: 'CSV',
    extensions: ['csv'],
    mimeTypes: [
      'text/csv',
      'text/comma-separated-values',
      'text/plain',
      'application/vnd.ms-excel',
    ],
    uniformTypeIdentifiers: [
      'public.comma-separated-values-text',
      'public.plain-text',
    ],
  );

  final Future<file_selector.XFile?> Function() _openFile;
  final Future<Directory> Function() _temporaryDirectory;
  final Directory Function() _systemTemporaryDirectory;

  static Future<file_selector.XFile?> _openCsvFile() =>
      file_selector.openFile(acceptedTypeGroups: const [_csvTypeGroup]);

  /// The chosen file's name and bytes, or null when the user cancels.
  ///
  /// Throws [CsvFileTooLargeException] when the file is over [maxBytes].
  Future<({String name, Uint8List bytes})?> pick() async {
    final file = await _openFile();
    if (file == null) return null;
    try {
      if (await file.length() > maxBytes) {
        throw const CsvFileTooLargeException();
      }
      return (name: file.name, bytes: await file.readAsBytes());
    } finally {
      await _deleteCacheCopy(file.path);
    }
  }

  /// Deletes [path] when it lies inside the temporary directory (Android's
  /// cache dir; `Library/Caches` on iOS) or the system temp directory (the
  /// app's `tmp/` on iOS), where the platform picker put its copy.
  /// Failures are ignored: the copy is the platform's, and a leftover cache
  /// file must not fail the import.
  Future<void> _deleteCacheCopy(String path) async {
    try {
      // Resolve links so `/var` and `/private/var` (iOS) compare equal.
      final roots = [
        await (await _temporaryDirectory()).resolveSymbolicLinks(),
        await _systemTemporaryDirectory().resolveSymbolicLinks(),
      ];
      final file = await File(path).resolveSymbolicLinks();
      if (roots.any((r) => file.startsWith('$r${Platform.pathSeparator}'))) {
        await File(file).delete();
      }
    } on Object {
      // Ignored; see above.
    }
  }
}
