---
title: Main Screens
description: What each part of Ledgerly does.
sidebar:
  order: 2
---

## Splash screen and day counter

On launch, Ledgerly can show a standalone day counter before entering the main
app. This feature is independent of expense tracking: it counts the days since
a meaningful start date you choose, then displays the count in a sun-themed
visual layout.

- Use it to track a personal milestone, habit, relationship date, or any other
  date that matters to you.
- If the splash screen is enabled but no start date is set yet, Ledgerly asks
  you to choose one.
- A customizable display text appears below the day count. The default is
  `On {date} start using Ledgerly`, where `{date}` renders inline with a
  rainbow gradient. You can also use `{days}` to embed the current day count
  in your text.
- The display text supports multiple lines. If you delete `{date}` from your
  custom template, Ledgerly automatically shows the date in front of your text
  so the start date is never hidden.
- Tap the enter button on the splash screen to continue to `Home`.
- You can turn the splash screen off if you prefer opening directly to `Home`.

## Home

`Home` is your day-by-day overview.

- See the currently selected day's transactions.
- Review quick summary information for that day, grouped by currency.
- Move backward or forward between days.
- Start adding a new transaction from the main flow.
- A pending-approval section appears when recurring rules have generated
  upcoming entries waiting for you to confirm or skip.
- A search affordance lets you find historical transactions by memo,
  category, or amount across the full history.

## Add / Edit Transaction

Use the transaction form to record money movement.

Typical flow:

1. Choose whether the entry is an expense or income.
2. Enter the amount using the calculator-style keypad.
3. Pick an account.
4. Pick a category.
5. Optionally add a memo.
6. Save the transaction.

You can also open an existing transaction to edit it or duplicate it for quick
repeat entry.

## Analysis

`Analysis` visualizes how you spend.

- A pie chart breaks down expenses by category for the selected period.
- A daily bar chart shows day-over-day totals with smooth animations.
- Tap a pie slice or a legend row to drill into that category: the bar
  chart refilters and a per-slice list of matching transactions appears
  below the charts. Each row supports tap-to-edit and swipe-to-delete
  with a 4-second undo window.
- Multi-currency totals are converted using cached exchange rates; the
  app notifies you when it falls back to the last known rates older than
  about an hour.

## Recurring transactions

`Settings > Recurring` lets you set up rules that pre-fill upcoming
transactions on a cadence (daily, weekly, monthly, etc.). Generated
entries land in the pending section on `Home` for approval — nothing is
written to your books until you accept. Skipping an occurrence rejects
that single date with a 4-second undo window; the parent rule keeps
running.

## Shopping list

Quick-capture flow for groceries and errands. Add items as drafts in a
dedicated list, then convert each draft into a real transaction with the
amount and category locked in. Useful when you record purchases away
from the till and want to settle the books later.

## Accounts

Use `Settings > Manage Accounts` to organize where money is stored.

- Create additional accounts beyond the default cash account.
- Assign an account type and currency.
- Keep historical integrity: accounts that already have transactions are kept
  for record history instead of being casually removed.

## Categories

Use `Categories` to control how spending and income are classified.

- Start with seeded categories.
- Add your own custom categories.
- Rename categories to match your preferences.
- Archive used categories instead of deleting history-backed records.

## Settings

Use `Settings` to personalize the app.

- Change theme mode.
- Change app language.
- Choose the default currency.
- Choose the default account.
- Manage categories and accounts (with archive-instead-of-delete for
  history-backed records).
- Manage recurring transaction rules.
- Enable or disable the splash screen.
- Configure the splash day counter start date, the multi-line display
  text template (using `{date}` and `{days}` placeholders), and the
  enter button label.