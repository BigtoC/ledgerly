// Settings screen (plan §3.1, §5).
//
// Layout: `CustomScrollView` with one `SliverToBoxAdapter` per section.
// Sections (order):
//   1. Appearance — theme segmented control + language selector.
//   2. General — default account, default currency, manage categories.
//   3. Splash — splash settings subsection (plan §6).
//
// The screen is purely a projection of `settingsControllerProvider` — it
// never reads repositories directly, and no data transformation happens
// in `build()` (PRD → Controller Contract).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

import '../../app/providers/app_update_provider.dart';
import '../../app/providers/default_currency_provider.dart';
import '../../app/providers/repository_providers.dart';
import '../../core/constants.dart';
import '../../l10n/app_localizations.dart';
import '../accounts/accounts_controller.dart';
import 'settings_controller.dart';
import 'settings_providers.dart';
import 'settings_state.dart';
import 'widgets/manage_accounts_tile.dart';
import 'widgets/default_currency_tile.dart';
import 'widgets/language_selector.dart';
import 'widgets/manage_categories_tile.dart';
import 'widgets/new_version_badge.dart';
import 'widgets/settings_section.dart';
import 'widgets/splash_settings_section.dart';
import 'widgets/theme_mode_selector.dart';

@Dependencies([
  SettingsController,
  AccountsController,
  exchangeRates,
  initialDefaultCurrency,
  defaultCurrency,
])
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(settingsControllerProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navSettings)),
      body: switch (state) {
        AsyncData<SettingsState>(value: final SettingsData data) =>
          _SettingsBody(data: data),
        AsyncData<SettingsState>(value: SettingsError()) ||
        AsyncError() => const _ErrorSurface(),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

@Dependencies([
  SettingsController,
  AccountsController,
  exchangeRates,
  initialDefaultCurrency,
  defaultCurrency,
])
class _SettingsBody extends ConsumerWidget {
  const _SettingsBody({required this.data});

  final SettingsData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final packageInfo = ref.watch(packageInfoProvider);
    final updateUrl = ref.watch(availableAppUpdateProvider);
    const EdgeInsets cardPadding = EdgeInsets.symmetric(
      horizontal: homePageCardHorizontalPadding - 16,
    );
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: cardPadding,
          sliver: SliverToBoxAdapter(
            child: SettingsSection(
              title: l10n.settingsSectionAppearance,
              children: [
                ThemeModeSelector(value: data.themeMode),
                LanguageSelector(value: data.locale),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: cardPadding,
          sliver: SliverToBoxAdapter(
            child: SettingsSection(
              title: l10n.settingsSectionGeneral,
              children: [
                const ManageAccountsTile(),
                DefaultCurrencyTile(defaultCurrency: data.defaultCurrency),
                const ManageCategoriesTile(),
                ListTile(
                  key: const ValueKey('settingsRecurringTile'),
                  title: Text(l10n.settingsRecurringTile),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/settings/recurring'),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: cardPadding,
          sliver: SliverToBoxAdapter(
            child: SplashSettingsSection(
              splashEnabled: data.splashEnabled,
              splashStartDate: data.splashStartDate,
              splashDisplayText: data.splashDisplayText,
              splashButtonLabel: data.splashButtonLabel,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 24, bottom: 32),
            child: Center(
              // Wrap, not Row: the badge drops to its own line at 2x text
              // scale instead of overflowing.
              child: Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  GestureDetector(
                    onTap: () => context.push('/settings/about'),
                    child: Text(
                      packageInfo
                              .whenData(
                                (info) =>
                                    'v${info.version}+${info.buildNumber}',
                              )
                              .value ??
                          '',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  if (updateUrl != null) NewVersionBadge(url: updateUrl),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorSurface extends StatelessWidget {
  const _ErrorSurface();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(l10n.errorSnackbarGeneric),
      ),
    );
  }
}
