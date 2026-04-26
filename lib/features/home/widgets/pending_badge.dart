// Pending-transactions badge — Wave 3 §4.1.
//
// MVP: count is always 0 per Wave 0 §2.3 (no Phase 2 pending pipeline).
// Renders nothing when count is 0; renders a small dot + label when
// count is non-zero so Phase 2 can flip the count without re-wiring
// the widget tree. The host (e.g. day-nav header) decides where to
// place it.

import 'package:flutter/material.dart';

class PendingBadge extends StatelessWidget {
  const PendingBadge({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          color: scheme.onTertiaryContainer,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
