import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'repository_providers.dart';

part 'theme_provider.g.dart';

@Riverpod(keepAlive: true)
ThemeMode? initialThemeMode(Ref ref) => null;

@Riverpod(keepAlive: true)
Stream<ThemeMode> themeModeStream(Ref ref) =>
    ref.watch(userPreferencesRepositoryProvider).watchThemeMode();

@riverpod
ThemeMode themeMode(Ref ref) {
  final initial = ref.watch(initialThemeModeProvider) ?? ThemeMode.system;
  return ref.watch(themeModeStreamProvider).value ?? initial;
}
