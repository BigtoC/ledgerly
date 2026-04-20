// Migration harness skeleton.
//
// M0 commits this file as a stub so Phase 2 inherits the harness without
// retrofitting. It is activated in M3 once `AppDatabase` and the v1 schema
// snapshot exist.
//
// Final shape (per PRD -> Migration Strategy and Testing Strategy):
//
//   test('v1 schema is stable', ...)
//   test('onUpgrade v1 -> v2 preserves data on empty DB', ...)
//   test('onUpgrade v1 -> v2 preserves data on seeded DB', ...)
//
// Each case boots `drift_dev`'s generated schema for a given version,
// applies the real `MigrationStrategy.onUpgrade`, and asserts row-level
// invariants. Snapshots live in /drift_schemas/.

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('migrations', () {
    test('TODO(M3): activate against drift_schemas/drift_schema_v1.json',
        () {
      // Intentionally left as a placeholder so CI runs zero assertions
      // until the harness is activated. Remove this `skip:` and wire the
      // full test once AppDatabase + the v1 snapshot land in M1.
    }, skip: 'Activated in M3 with the first repository tests.');
  });
}
