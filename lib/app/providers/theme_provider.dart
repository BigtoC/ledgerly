import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'repository_providers.dart';

part 'theme_provider.g.dart';

@Riverpod(keepAlive: true)
Stream<ThemeMode> _themeModeStream(Ref ref) =>
    ref.watch(userPreferencesRepositoryProvider).watchThemeMode();

@riverpod
ThemeMode themeMode(Ref ref) =>
    ref.watch(_themeModeStreamProvider).value ?? ThemeMode.system;
