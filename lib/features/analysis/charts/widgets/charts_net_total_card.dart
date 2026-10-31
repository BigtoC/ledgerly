// Small box above the Analysis chart: income minus expense for the
// period picked in the time picker. Green when positive, pink when
// negative, the plain text color at zero.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

import '../../../../core/utils/money_formatter.dart';
import '../../../../l10n/app_localizations.dart';
import '../charts_net_total_provider.dart';

@Dependencies([chartsNetTotal])
class ChartsNetTotalCard extends ConsumerWidget {
  const ChartsNetTotalCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final net = ref.watch(chartsNetTotalProvider);
    if (net == null) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final minor = net.netMinorUnits;
    final amount = minor == null
        ? '—'
        : MoneyFormatter.formatSigned(
            amountMinorUnits: minor,
            currency: net.currency,
            locale: locale,
          );
    // Light mode takes darker shades so the amount keeps WCAG AA contrast
    // on surfaceContainer.
    final isDark = theme.brightness == Brightness.dark;
    final color = switch (minor) {
      final m? when m > 0 =>
        isDark ? Colors.green.shade400 : Colors.green.shade900,
      final m? when m < 0 => isDark ? Colors.pinkAccent : Colors.pink.shade700,
      _ => theme.colorScheme.onSurface,
    };
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        // Stadium matches the SegmentedButtons above it.
        decoration: ShapeDecoration(
          color: theme.colorScheme.surfaceContainer,
          shape: const StadiumBorder(),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Only the amount shows; "Net" stays for screen readers.
            Semantics(
              label: '${l10n.chartsNetTotal} $amount',
              excludeSemantics: true,
              child: Text(
                amount,
                // Same size as the SegmentedButton labels (labelLarge).
                style: theme.textTheme.labelLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (net.excludedCurrencyCodes.isNotEmpty)
              Text(
                l10n.chartsExcludedCurrencies(
                  net.excludedCurrencyCodes.join(', '),
                ),
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }
}
