import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'repository_providers.dart';

part 'theme_provider.g.dart';

// `dependencies: const []` marks this as scope-overridable; bootstrap.dart
// overrides it with the eagerly-read persisted theme so the first frame
// renders in the user's preferred mode without flicker.
@Riverpod(keepAlive: true, dependencies: [])
ThemeMode? initialThemeMode(Ref ref) => null;

@Riverpod(keepAlive: true, dependencies: [userPreferencesRepository])
Stream<ThemeMode> themeModeStream(Ref ref) =>
    ref.watch(userPreferencesRepositoryProvider).watchThemeMode();

@Riverpod(dependencies: [initialThemeMode, themeModeStream])
ThemeMode themeMode(Ref ref) {
  final initial = ref.watch(initialThemeModeProvider) ?? ThemeMode.system;
  return ref.watch(themeModeStreamProvider).value ?? initial;
}
