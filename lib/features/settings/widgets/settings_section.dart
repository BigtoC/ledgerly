// Reusable settings section scaffolding (plan §3.1).
//
// Renders a section header above a card container that holds child rows.
// Card styling mirrors the home-page summary strip for visual consistency.

import 'package:flutter/material.dart';

import '../../../core/constants.dart';
import '../../../core/utils/box_shadow.dart';

class SettingsSection extends StatelessWidget {
  const SettingsSection({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: homePageCardHorizontalPadding - 24,
        vertical: 8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 8),
            child: Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          Material(
            color: theme.colorScheme.surfaceContainer,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(homePageCardBorderRadius),
            ),
            shadowColor: buildBoxShadow(homePageCardBorderRadius).color,
            elevation: 3,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}
