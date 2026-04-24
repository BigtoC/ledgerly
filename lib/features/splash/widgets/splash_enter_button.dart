// Splash Enter button (plan §5 layer 4).
//
// Filled button at the bottom of the splash that navigates to `/home`.
// Route-level fade transition is owned by `app/router.dart` per PRD →
// Routing Structure ("Splash → Home transition uses a fade") — this
// widget just calls `context.go('/home')`.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SplashEnterButton extends StatelessWidget {
  const SplashEnterButton({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          minimumSize: const Size(200, 52),
          shape: const StadiumBorder(),
        ),
        onPressed: () => context.go('/home'),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }
}
