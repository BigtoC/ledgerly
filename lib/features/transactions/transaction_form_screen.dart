// TODO(M5): Add/Edit Transaction per PRD -> Layout Primitives.
// Required widget tree:
//
//   Scaffold(resizeToAvoidBottomInset: false)
//     └─ SafeArea
//         └─ Column
//             ├─ Expanded → SingleChildScrollView (type toggle, amount
//             │             display, category, account, date, memo)
//             └─ CalculatorKeypad (fixed height)
//
// `resizeToAvoidBottomInset: false` is mandatory — see risk #6 and
// guardrail G11. The keypad must never be covered by the soft keyboard.
