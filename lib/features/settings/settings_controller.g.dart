// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$settingsControllerHash() =>
    r'5b0c2763b6704edf602690fe3c831328a2ede920';

/// See also [SettingsController].
@ProviderFor(SettingsController)
final settingsControllerProvider =
    AutoDisposeStreamNotifierProvider<
      SettingsController,
      SettingsState
    >.internal(
      SettingsController.new,
      name: r'settingsControllerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$settingsControllerHash,
      dependencies: <ProviderOrFamily>[userPreferencesRepositoryProvider],
      allTransitiveDependencies: <ProviderOrFamily>{
        userPreferencesRepositoryProvider,
        ...?userPreferencesRepositoryProvider.allTransitiveDependencies,
      },
    );

typedef _$SettingsController = AutoDisposeStreamNotifier<SettingsState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
