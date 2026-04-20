// go_router configuration.
//
// TODO(M4): Implement the route tree from PRD → Routing Structure:
//   - StatefulShellRoute for Home / Accounts / Settings (preserve per-tab
//     navigation state).
//   - Root redirect: reads `splash_enabled` from user_preferences; when
//     false the splash route is never visited (guardrail G10).
//   - Add/Edit Transaction as a modal push (MaterialPage / CupertinoPage)
//     so the calculator keypad has full vertical space.
//   - Splash -> Home uses a fade CustomTransitionPage to preserve the
//     hnotes-style reveal.
