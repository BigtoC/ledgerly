// test/unit/architecture/layer_boundaries_test.dart
//
// Enforces PRD.md -> Layer Boundaries. The rules and the baseline of
// known violations live in `import_analysis_options.yaml` at the repo
// root; this test is the only thing that reads them.
//
// Semantics:
//   - Every `lib/**/*.dart` file is checked, except generated
//     `*.g.dart` / `*.freezed.dart` parts (parts cannot hold directives).
//   - A rule applies to a file when `search_file_path_reg_exp` matches the
//     file's repo-relative path (`lib/features/home/home_screen.dart`).
//   - Every `import` and `export` URI in that file (both branches of a
//     conditional import) is normalised first: relative URIs are resolved
//     against the file and rewritten to `package:ledgerly/...`; `package:`
//     and `dart:` URIs are used as written. A URI matching any
//     `not_allow_import_reg_exps` entry and no `ignore_import_reg_exps`
//     entry is a violation. An `export` URI is also checked against the
//     rule's optional `not_allow_export_reg_exps`, so a file cannot hand
//     its importers what their own rules forbid.
//   - `part` / `part of` are not dependency edges and are skipped.
//   - A violation listed under `baseline:` is tolerated. A baseline entry
//     that no longer occurs fails the test, so the list only shrinks.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';

const _rulesFile = 'import_analysis_options.yaml';
const _packageName = 'ledgerly';
const _thisFile = 'test/unit/architecture/layer_boundaries_test.dart';

void main() {
  group('directive scanner', () {
    test('finds imports and exports across comments and multi-line forms', () {
      const source = '''
// header comment with import 'package:nope/a.dart';
/* block /* nested */ comment */
library;

import 'package:a/a.dart' show A, B;
import "package:b/b.dart"
    as b;
export '../c.dart' hide C;
import 'd.dart' if (dart.library.io) 'e.dart';
part 'f.g.dart';

@riverpod
class Foo {
  final s = """
import 'package:late/late.dart';
""";
}
''';
      final found = _scanDirectives(source)
          .map((d) => '${d.line}:${d.uri}')
          .toList();
      expect(found, [
        '5:package:a/a.dart',
        '6:package:b/b.dart',
        '8:../c.dart',
        '9:d.dart',
        '9:e.dart',
      ]);
    });

    test('resolves relative URIs to package:ledgerly paths', () {
      expect(
        _normalise('lib/features/home/home_screen.dart', '../../data/x.dart'),
        'package:ledgerly/data/x.dart',
      );
      expect(
        _normalise('lib/features/home/home_screen.dart', 'widgets/y.dart'),
        'package:ledgerly/features/home/widgets/y.dart',
      );
      expect(
        _normalise('lib/a.dart', 'package:drift/drift.dart'),
        'package:drift/drift.dart',
      );
      expect(
        _normalise('lib/a.dart', 'package:ledgerly/features/../data/x.dart'),
        'package:ledgerly/data/x.dart',
      );
    });

    test('tells import directives from export directives', () {
      const source = '''
import 'a.dart';
export 'b.dart' show B;
export 'c.dart' if (dart.library.io) 'd.dart';
import 'e.dart' if (dart.library.io) 'f.dart';
''';
      final found = _scanDirectives(source)
          .map((d) => '${d.isExport ? 'export' : 'import'} ${d.uri}')
          .toList();
      expect(found, [
        'import a.dart',
        'export b.dart',
        'export c.dart',
        'export d.dart',
        'import e.dart',
        'import f.dart',
      ]);
    });
  });

  group('rules in $_rulesFile', () {
    final config = _Config.load(File(_rulesFile).readAsStringSync());

    /// Whether any rule that applies to [path] forbids [uri] (as written)
    /// in an `import`, or in an `export` when [export] is true.
    bool forbidden(String path, String uri, {bool export = false}) {
      final normalised = _normalise(path, uri);
      return config.rules
          .where((r) => r.appliesTo(path))
          .any((r) => r.forbids(normalised, export: export));
    }

    // One file per feature rule.
    const screen = 'lib/features/home/home_screen.dart';
    const widget =
        'lib/features/transactions/widgets/account_picker_sheet.dart';
    const state = 'lib/features/home/home_state.dart';
    const otherFeatureFile = 'lib/features/analysis/charts/selected_slice.dart';
    const controller = 'lib/features/home/home_controller.dart';
    const featureProviders = 'lib/features/home/home_providers.dart';
    const featureFiles = [
      screen,
      widget,
      state,
      otherFeatureFile,
      controller,
      featureProviders,
    ];

    const repositoryProviders =
        'package:ledgerly/app/providers/repository_providers.dart';
    const serviceProviders =
        'package:ledgerly/app/providers/service_providers.dart';

    test('widget, state and other feature files may not import the '
        'repository or service providers', () {
      for (final path in [screen, widget, state, otherFeatureFile]) {
        expect(forbidden(path, repositoryProviders), isTrue, reason: path);
        expect(forbidden(path, serviceProviders), isTrue, reason: path);
      }
      // Relative imports are resolved before matching.
      expect(
        forbidden(widget, '../../../app/providers/repository_providers.dart'),
        isTrue,
      );
    });

    test('controllers and feature providers may import the repository '
        'providers but not the service providers', () {
      for (final path in [controller, featureProviders]) {
        expect(forbidden(path, repositoryProviders), isFalse, reason: path);
        expect(forbidden(path, serviceProviders), isTrue, reason: path);
      }
    });

    test('feature files may not import the database provider', () {
      // `ref.read(appDatabaseProvider)` would hand over `AppDatabase`
      // without an import of data/database/.
      for (final path in featureFiles) {
        expect(
          forbidden(
            path,
            'package:ledgerly/app/providers/app_database_provider.dart',
          ),
          isTrue,
          reason: path,
        );
      }
    });

    test('feature files may not import platform or I/O plugins', () {
      const plugins = [
        'package:package_info_plus/package_info_plus.dart',
        'package:dio/dio.dart',
        'package:file_picker/file_picker.dart',
        'package:file_selector/file_selector.dart',
        'package:path_provider/path_provider.dart',
      ];
      for (final path in featureFiles) {
        for (final plugin in plugins) {
          expect(forbidden(path, plugin), isTrue, reason: '$path -> $plugin');
        }
      }
    });

    test('feature files may import the app-level value providers', () {
      for (final path in featureFiles) {
        for (final uri in [
          'package:ledgerly/app/providers/exchange_rates_provider.dart',
          'package:ledgerly/app/providers/app_version_provider.dart',
        ]) {
          expect(forbidden(path, uri), isFalse, reason: '$path -> $uri');
        }
      }
    });

    test('no feature file may re-export the repository or service '
        'providers or data internals', () {
      const reexported = [
        repositoryProviders,
        serviceProviders,
        'package:ledgerly/data/repositories/account_repository.dart',
        'package:ledgerly/data/services/exchange_rate_service.dart',
        'package:ledgerly/data/database/app_database.dart',
      ];
      for (final path in featureFiles) {
        for (final uri in reexported) {
          expect(
            forbidden(path, uri, export: true),
            isTrue,
            reason: '$path -> $uri',
          );
        }
      }
      // Relative exports are resolved before matching.
      expect(
        forbidden(
          'lib/features/transactions/transactions_providers.dart',
          '../../app/providers/repository_providers.dart',
          export: true,
        ),
        isTrue,
      );
    });
  });

  test('lib/ respects the layer-boundary rules in $_rulesFile', () {
    final config = _Config.load(File(_rulesFile).readAsStringSync());
    final files =
        Directory('lib')
            .listSync(recursive: true, followLinks: false)
            .whereType<File>()
            .map((f) => f.path.replaceAll(r'\', '/'))
            .where(
              (p) =>
                  p.endsWith('.dart') &&
                  !p.endsWith('.g.dart') &&
                  !p.endsWith('.freezed.dart'),
            )
            .toList()
          ..sort();
    expect(files, isNotEmpty, reason: 'no Dart files found under lib/');

    final violations = <_Violation>[];
    final problems = <String>[];
    for (final path in files) {
      final rules = config.rules.where((r) => r.appliesTo(path)).toList();
      if (rules.isEmpty) continue;
      final source = File(path).readAsStringSync();
      final directives = _scanDirectives(source);
      final unscanned = _leftoverDirective(source, directives);
      if (unscanned != null) {
        problems.add(
          '$path:$unscanned: directive after the scanned header; the '
          'scanner in $_thisFile could not parse this file',
        );
      }
      for (final d in directives) {
        final uri = _normalise(path, d.uri);
        for (final rule in rules) {
          if (rule.forbids(uri, export: d.isExport)) {
            violations.add(_Violation(rule.name, path, d.line, d.uri, uri));
          }
        }
      }
    }

    final seen = violations.map((v) => v.key).toSet();
    for (final v in violations) {
      if (!config.baseline.contains(v.key)) problems.add(v.describe());
    }
    for (final key in config.baseline) {
      if (!seen.contains(key)) {
        problems.add(
          'stale baseline entry in $_rulesFile (the violation is gone, '
          'delete the entry): $key',
        );
      }
    }

    if (problems.isNotEmpty) {
      fail(
        '${problems.length} layer-boundary problem(s). Rules: $_rulesFile '
        '(PRD.md -> Layer Boundaries).\n  ${problems.join('\n  ')}',
      );
    }
  });
}

class _Rule {
  _Rule(
    this.name,
    this.searchFilePath,
    this.notAllowed,
    this.notAllowedExports,
    this.ignored,
  );

  final String name;
  final RegExp searchFilePath;
  final List<RegExp> notAllowed;

  /// Checked against `export` URIs only, on top of [notAllowed].
  final List<RegExp> notAllowedExports;
  final List<RegExp> ignored;

  bool appliesTo(String path) => searchFilePath.hasMatch(path);

  bool forbids(String uri, {required bool export}) =>
      (notAllowed.any((r) => r.hasMatch(uri)) ||
          (export && notAllowedExports.any((r) => r.hasMatch(uri)))) &&
      !ignored.any((r) => r.hasMatch(uri));
}

class _Config {
  _Config(this.rules, this.baseline);

  final List<_Rule> rules;

  /// `rule | file | import` keys, see [_Violation.key].
  final Set<String> baseline;

  static const _ruleKeys = {
    'search_file_path_reg_exp',
    'not_allow_import_reg_exps',
    'ignore_import_reg_exps',
    'not_allow_export_reg_exps',
  };
  static const _baselineKeys = {'rule', 'file', 'import'};

  static _Config load(String yaml) {
    final doc = loadYaml(yaml) as YamlMap;
    final rules = <_Rule>[];
    for (final entry in (doc['rules'] as YamlMap).entries) {
      final name = entry.key as String;
      final body = entry.value as YamlMap;
      final unknown = body.keys.toSet().difference(_ruleKeys);
      if (unknown.isNotEmpty) {
        throw FormatException('$_rulesFile: rule $name has unknown $unknown');
      }
      List<RegExp> regExps(String key) => [
        for (final p in (body[key] as YamlList?) ?? const <Object>[])
          RegExp(p as String),
      ];
      rules.add(
        _Rule(
          name,
          RegExp(body['search_file_path_reg_exp'] as String),
          regExps('not_allow_import_reg_exps'),
          regExps('not_allow_export_reg_exps'),
          regExps('ignore_import_reg_exps'),
        ),
      );
    }

    final names = rules.map((r) => r.name).toSet();
    final baseline = <String>{};
    for (final item in (doc['baseline'] as YamlList?) ?? const <Object>[]) {
      final map = item as YamlMap;
      if (!map.keys.toSet().containsAll(_baselineKeys) ||
          map.length != _baselineKeys.length) {
        throw FormatException(
          '$_rulesFile: baseline entry needs exactly $_baselineKeys: $map',
        );
      }
      if (!names.contains(map['rule'])) {
        throw FormatException('$_rulesFile: unknown baseline rule: $map');
      }
      baseline.add(_key(map['rule'], map['file'], map['import']));
    }
    return _Config(rules, baseline);
  }
}

String _key(Object? rule, Object? file, Object? uri) => '$rule | $file | $uri';

class _Violation {
  _Violation(this.rule, this.file, this.line, this.written, this.uri);

  final String rule;
  final String file;
  final int line;
  final String written;
  final String uri;

  String get key => _key(rule, file, uri);

  String describe() {
    final shown = written == uri ? uri : "'$written' (= $uri)";
    return '$file:$line -> $shown violates $rule';
  }
}

/// Resolves [uri] as written in the file at [path] (`lib/...`) to the form
/// the rules match against.
String _normalise(String path, String uri) {
  // Dart removes `..` segments from package: URIs before loading them, so
  // do the same here; otherwise `package:ledgerly/features/../data/...`
  // would slip past every `^package:ledgerly/<layer>/` pattern.
  if (uri.startsWith('package:')) {
    return Uri.parse(uri).normalizePath().toString();
  }
  if (uri.contains(':')) return uri;
  final resolved = Uri.parse('file:///$path').resolve(uri).path.substring(1);
  return resolved.startsWith('lib/')
      ? 'package:$_packageName/${resolved.substring(4)}'
      : resolved;
}

class _Directive {
  _Directive(this.line, this.uri, {required this.isExport});

  final int line;
  final String uri;

  /// Whether this came from an `export` directive rather than an `import`.
  final bool isExport;
}

/// Reads the directive header of a Dart file: `library`, `import`,
/// `export`, `part`, `part of`, and annotations, up to the first
/// declaration. Dart only allows directives there, so the rest of the file
/// is never parsed. Returns import/export URIs with their 1-based line and
/// whether the directive was an `export`.
List<_Directive> _scanDirectives(String source) {
  final s = _Cursor(source);
  final result = <_Directive>[];
  while (true) {
    s.skipTrivia();
    if (s.done) break;
    if (s.peek == '@') {
      s.skipAnnotation();
      continue;
    }
    final line = s.line;
    final word = s.readWord();
    if (!const {'library', 'import', 'export', 'part'}.contains(word)) break;
    final uris = s.readStatementStrings();
    if (word == 'import' || word == 'export') {
      result.addAll(
        uris.map((u) => _Directive(line, u, isExport: word == 'export')),
      );
    }
  }
  return result;
}

/// Returns the line of an `import`/`export` that starts a line after the
/// header [_scanDirectives] read, or null. Guards against the scanner
/// stopping early and silently missing imports.
int? _leftoverDirective(String source, List<_Directive> scanned) {
  final lastLine = scanned.isEmpty ? 0 : scanned.last.line;
  final lines = source.split('\n');
  final directive = RegExp(r'''^(import|export)\s+['"]''');
  for (var i = lastLine; i < lines.length; i++) {
    if (directive.hasMatch(lines[i]) && !scanned.any((d) => d.line == i + 1)) {
      return i + 1;
    }
  }
  return null;
}

class _Cursor {
  _Cursor(this.src);

  final String src;
  int pos = 0;
  int line = 1;

  bool get done => pos >= src.length;
  String get peek => src[pos];
  bool _at(String s) => src.startsWith(s, pos);

  void _advance([int n = 1]) {
    for (var i = 0; i < n && !done; i++) {
      if (src[pos] == '\n') line++;
      pos++;
    }
  }

  void skipTrivia() {
    while (!done) {
      if (peek.trim().isEmpty) {
        _advance();
      } else if (_at('//') || (pos == 0 && _at('#!'))) {
        while (!done && peek != '\n') {
          _advance();
        }
      } else if (_at('/*')) {
        var depth = 0;
        do {
          if (_at('/*')) {
            depth++;
            _advance(2);
          } else if (_at('*/')) {
            depth--;
            _advance(2);
          } else {
            _advance();
          }
        } while (!done && depth > 0);
      } else {
        return;
      }
    }
  }

  String readWord() {
    final start = pos;
    while (!done && RegExp(r'[\w$.]').hasMatch(peek)) {
      _advance();
    }
    return src.substring(start, pos);
  }

  void skipAnnotation() {
    _advance(); // '@'
    readWord();
    skipTrivia();
    if (done || peek != '(') return;
    var depth = 0;
    do {
      if (peek == "'" || peek == '"') {
        _readString();
        continue;
      }
      if (peek == '(') depth++;
      if (peek == ')') depth--;
      _advance();
    } while (!done && depth > 0);
  }

  /// Consumes up to and including the next top-level `;`, returning the
  /// string literals seen on the way.
  List<String> readStatementStrings() {
    final strings = <String>[];
    while (!done) {
      skipTrivia();
      if (done) break;
      if (peek == ';') {
        _advance();
        break;
      }
      if (peek == "'" || peek == '"') {
        strings.add(_readString());
      } else {
        _advance();
      }
    }
    return strings;
  }

  String _readString() {
    final quote = _at("'''") || _at('"""') ? src.substring(pos, pos + 3) : peek;
    _advance(quote.length);
    final start = pos;
    while (!done && !_at(quote)) {
      _advance(peek == r'\' ? 2 : 1);
    }
    final value = src.substring(start, pos);
    _advance(quote.length);
    return value;
  }
}
