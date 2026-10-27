# Student Expense Manager

Help students to manage their income.

A Flutter app for tracking student income, expenses, transfers, budgets,
notes and reminders. Runs on Android, iOS and the web from one codebase.
Authenticated account records are stored in the PHP/MySQL backend; the app
does not keep transaction or profile records in a local database.

## Feature checklist (mirrors the reference screenshots)

- **Home** tab: Add Income / Add Expense / Transfer / Transactions tiles,
  date-range selector, Income/Expense/Balance summary with previous balance,
  Recent Transactions, Payment Method balances, Monthly Expense bar chart,
  Trend line chart — every widget can be toggled on/off from the right drawer.
- **Add Income / Add Expense**: amount, category picker (with icon grid +
  "Add New" custom category), payment method picker (with "Add New"), notes,
  **Add Items** (item / quantity / unit / rate breakdown with running total),
  **Add Bills** (Camera / Gallery / PDF attachment), date & time pickers.
- **Transactions**: All / Daily / Weekly / Monthly / Yearly and custom date
  filters, category and type filters, amount/date/category sorting, search,
  running totals, and server-confirmed add/edit/delete actions.
- **Transfer**: move money between payment methods.
- **Calendar** tab: month grid with each day's expense total; tap a day to
  see its transactions.
- **Notebook** tab: to-do/notes list with Completed/Pending/Total footer.
- **Budget**: Monthly/Weekly/Yearly tabs, per-category budgets with a
  progress bar, remaining amount and "remaining per day", overall budget cap,
  import budgets from last period, PDF/Excel-style report export.
- **Reminders**: recurring transactions (Once/Daily/Weekly/Monthly/Yearly)
  with a one-tap "record now" action.
- **Notifications**: database-backed notification history, daily email/SMS
  check-ins and low-balance alerts (after server mail/Twilio setup).
- **Account**: multiple books/wallets, switchable from the top bar.
- **Settings / Backup & Restore / Deleted Transactions / Help**: full left
  and right drawers matching the reference menus.

## Project structure
