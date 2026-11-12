#!/usr/bin/env bash
# Fails unless the riverpod_lint analysis-server plugin reports a deliberate
# violation. A riverpod_lint version that cannot resolve on the current Dart
# SDK is skipped silently (no error, no diagnostics), so a clean
# `dart analyze` does not prove the plugin ran.
set -euo pipefail

probe=lib/riverpod_lint_probe.dart
trap 'rm -f "$probe"' EXIT
cat >"$probe" <<'DART'
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RiverpodLintProbe extends Notifier<int> {
  int count = 0;

  @override
  int build() => count;
}
DART

if dart analyze "$probe" 2>&1 | grep -q avoid_public_notifier_properties; then
  echo 'riverpod_lint is running.'
else
  echo '::error::riverpod_lint did not report a deliberate violation, so the plugin is not running. Check the version under plugins: in analysis_options.yaml.'
  exit 1
fi
