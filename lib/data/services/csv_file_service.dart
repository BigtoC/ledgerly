import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:file_selector/file_selector.dart' as file_selector;
import 'package:path_provider/path_provider.dart';

/// Saves bytes through the system save dialog. Returns false when the
/// user cancels.
typedef SaveFile = Future<bool> Function({
  required String fileName,
  required Uint8List bytes,
});

/// Picks a CSV file through the system picker and returns its bytes, and
/// saves one through the system save dialog. Knows nothing about the CSV
/// format.
///
/// The platform pickers copy the chosen file: `file_selector_android` into
/// the app's cache directory, the iOS document picker into the app's
/// `tmp/`. Saving on iOS also leaves a copy in `tmp/` (`file_picker`
/// writes the bytes there before showing the dialog). Those copies hold
/// financial data, so [pick] and [save] delete them. File names are never
/// logged.
class CsvFileService {
  CsvFileService({
    Future<file_selector.XFile?> Function()? openFile,
    SaveFile? saveFile,
    Future<Directory> Function()? temporaryDirectory,
    Directory Function()? systemTemporaryDirectory,
  }) : _openFile = openFile ?? _openCsvFile,
       _saveFile = saveFile ?? _saveCsvFile,
       _temporaryDirectory = temporaryDirectory ?? getTemporaryDirectory,
       _systemTemporaryDirectory =
           systemTemporaryDirectory ?? (() => Directory.systemTemp);

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
  final SaveFile _saveFile;
  final Future<Directory> Function() _temporaryDirectory;
  final Directory Function() _systemTemporaryDirectory;

  static Future<file_selector.XFile?> _openCsvFile() =>
      file_selector.openFile(acceptedTypeGroups: const [_csvTypeGroup]);

  /// The public Downloads folder as a Storage Access Framework document,
  /// where the Android save dialog opens. iOS ignores it.
  static const _androidDownloads =
      'content://com.android.externalstorage.documents/document/primary%3ADownload';

  static Future<bool> _saveCsvFile({
    required String fileName,
    required Uint8List bytes,
  }) async =>
      await FilePicker.saveFile(
        fileName: fileName,
        bytes: bytes,
        mimeType: 'text/csv',
        initialDirectory: _androidDownloads,
      ) !=
      null;

  /// Shows the system save dialog for [bytes] named [fileName]. Returns
  /// false when the user cancels.
  Future<bool> save(String fileName, Uint8List bytes) async {
    try {
      return await _saveFile(fileName: fileName, bytes: bytes);
    } finally {
      await _deleteCacheCopy(
        '${_systemTemporaryDirectory().path}${Platform.pathSeparator}$fileName',
      );
    }
  }

  /// The chosen file's name and bytes, or null when the user cancels.
  Future<({String name, Uint8List bytes})?> pick() async {
    final file = await _openFile();
    if (file == null) return null;
    try {
      return (name: file.name, bytes: await file.readAsBytes());
    } finally {
      await _deleteCacheCopy(file.path);
    }
  }

  /// Deletes [path] when it lies inside the temporary directory (Android's
  /// cache dir; `Library/Caches` on iOS) or the system temp directory (the
  /// app's `tmp/` on iOS), where the platform picker put its copy.
  /// Failures, including a missing copy, are ignored: the copy is the
  /// platform's, and a leftover cache file must not fail the import or
  /// export.
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
