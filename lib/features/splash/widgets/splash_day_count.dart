// Splash day count (plan §5 layer 2, PRD → Splash Visual Design + Accessibility).
//
// Huge white, bold numeric count with a secondary "days" label below.
// Text scaler clamps at 1.5× per PRD → Layout Primitives → Constraint rule:
// at 2× system scale, this widget caps at 1.5× so the numeral keeps its
// relative size while the surrounding flexible text scales normally.

import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

class SplashDayCount extends StatelessWidget {
  const SplashDayCount({
    required this.count,
    required this.startDate,
    super.key,
  });

  final int count;
  final DateTime startDate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final baseScaler = MediaQuery.textScalerOf(context);
    final clamped = baseScaler.clamp(maxScaleFactor: 1.5);
    return Semantics(
      label: '$count ${l10n.splashDayCountLabel}',
      container: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$count',
            textScaler: clamped,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 90,
              fontWeight: FontWeight.w800,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.splashDayCountLabel,
            textScaler: clamped,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w500,
              letterSpacing: 2.0,
            ),
          ),
        ],
      ),
    );
  }
}
