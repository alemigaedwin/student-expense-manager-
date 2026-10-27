# Student Expense Manager

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

```
lib/
  models/        Plain Dart data classes (Transaction, Category, Budget, ...)
  services/      AppState, server API client, device settings, seed data
  utils/         Colors and formatting helpers
  widgets/       Shared UI pieces (summary strip, transaction tile, ...)
  screens/       One folder per feature area (home, transactions, budget, ...)
  main.dart      App entry point
```

Hive stores only the local session token and device preferences. Transactions,
accounts, categories, budgets, notes, reminders and profile settings are read
from and written to the authenticated MySQL account.

## Getting started

1. **Install Flutter** (stable channel) and open **Android Studio** with the
   Flutter/Dart plugins installed.
2. Unzip this project, then open the folder in Android Studio
   (`File > Open`), or from a terminal:

   ```bash
   cd student_expense_manager
   flutter pub get
   ```

3. If Android Studio reports a Gradle or platform-folder mismatch (this can
   happen if your installed Flutter/Gradle/AGP versions differ from the ones
   this project was authored against), the safest fix is to let Flutter
   regenerate the platform folders for your exact SDK version — this will
   **not** touch `lib/` or `pubspec.yaml`:

   ```bash
   flutter create .
   flutter pub get
   ```

4. Run it:

   ```bash
   flutter run -d chrome     # web
   flutter run                # connected Android device / emulator
   ```

   Or just press the green ▶ Run button in Android Studio and pick a device
   (Chrome is listed as a device target once you run `flutter config
   --enable-web`, which is on by default in modern Flutter).

## Notes / things you may want to extend

- **PDF/Excel report export** supports selected date ranges and month ranges.
  Excel exports include the matching transaction rows and totals.
- **Backup/Restore** exports a full JSON snapshot via the share sheet;
  restoring from a picked file can be added with `file_picker` following the
  same pattern used for bill attachments.
- **Camera/Gallery/PDF bill attachments** use `image_picker` and
  `file_picker`; camera and storage permissions are already declared in
  `android/app/src/main/AndroidManifest.xml`.
- Category and payment-method lists are seeded with sensible defaults on
  first launch (see `lib/services/default_data.dart`) and are fully
  editable/extendable in-app via "Add New".
- Multiple **Accounts** (books) are supported so a student could keep e.g. a
  personal book and a club/society book side by side.

## Design

Dark theme with a blue accent, green for income, red for expense and orange
for transfers — matching the reference screenshots. All colors live in
`lib/utils/app_colors.dart` if you want to reskin it.


## Screenshot-matched Add Income / Add Expense update
The transaction entry screens were updated from the supplied reference document:
- dark reference layout with separate Income/Expense amount field
- illustrated category icons and custom-category icon picker
- bottom-sheet Category picker with search and Add New
- bottom-sheet Payment Method picker with Bank/Card/Cash/Others + Add New
- Add Bills Camera/Gallery/PDF menu
- Add Items quantity/unit/rate dialog
- date and time controls plus the three-button bottom action bar


# MySQL + PHP backend (phpMyAdmin)

This version includes a PHP/MySQL backend under `backend/`. The same signed-in
account can be opened from a browser and an Android phone when both clients can
reach the API. The server is the source of truth; a network connection is
required to view or save account records.

## 1. Install the database in phpMyAdmin

1. Start **Apache** and **MySQL** in XAMPP (or the equivalent services in WAMP).
2. Open your phpMyAdmin address, for example:
   `http://localhost/phpmyadmin/`
3. Open **Import**.
4. Select `backend/student_expense_manager.sql`.
5. Click **Import**.
6. A database named `student_expense_manager` will be created.
7. You can then manage it from:
   `http://localhost/phpmyadmin/index.php?route=/server/databases`

The SQL creates these tables:

- `users` and `sessions` — secure account/password hashes and API sessions.
- `password_reset_tokens` — expiring, single-use email reset codes.
- `accounts` — student books/wallets.
- `categories` — income/expense categories and custom icons.
- `payment_methods` — cash, bank, card and custom methods.
- `transactions` — income, expenses and transfers.
- `transaction_items` — item/quantity/unit/rate breakdowns.
- `transaction_bills` — receipt/bill attachment paths.
- `budgets` and `overall_budgets` — category and overall budgets.
- `notes` — notebook entries.
- `reminders` — recurring transactions.
- `user_settings` — theme, selected account, widget preferences and recent categories.
- `notification_preferences` and `notifications` — delivery choices, alert history and status.

## 2. Install the PHP API

Copy the entire `backend` folder into your XAMPP web root and rename it:

```text
C:\xampp\htdocs\student_expense_manager_api\
```

The folder should contain:

```text
student_expense_manager_api/
  api.php
  config.php
  config.example.php
  student_expense_manager.sql
  .htaccess
```

Copy `config.example.php` to `config.php` and set the database connection:

```text
host: 127.0.0.1
database: student_expense_manager
username: root
password: (empty)
```

If your MySQL root account has a password, edit `config.php` and set
`db_password`.

Before using Flutter, test the PHP endpoint in a browser:

```text
http://localhost/student_expense_manager_api/api.php?action=ping
```

A successful response should be JSON. If your Apache setup does not allow
that route, open `api.php` without the action and check the Apache/PHP logs.

## 3. Flutter dependencies

From the project folder:

```bash
flutter clean
flutter pub get
```

The `http` package connects to the PHP API. Hive is used only for device-level
session and interface preferences; it is not a cache for account records.

## 4. Browser testing

With Apache/MySQL running:

```bash
flutter run -d chrome
```

The web build defaults to:

```text
http://localhost/student_expense_manager_api/api.php
```

If your PHP folder has another name, use:

```bash
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost/YOUR_FOLDER/api.php
```

## 5. Android emulator

For the Android Studio emulator, `localhost` means the emulator itself, not
your Windows PC. This build therefore defaults to:

```text
http://10.0.2.2/student_expense_manager_api/api.php
```

Run:

```bash
flutter run -d emulator
```

or select the Android emulator from Android Studio.

The manifest allows clear-text HTTP for local development. For deployment,
use HTTPS and remove/disable clear-text HTTP.

## 6. Physical Android phone

The phone and the computer running XAMPP must be on the same network.

Find the computer's IPv4 address, for example:

```text
ipconfig
```

If the computer address is `192.168.1.20`, run:

```bash
flutter run -d <your-phone-id> --dart-define=API_BASE_URL=http://192.168.1.20/student_expense_manager_api/api.php
```

If Windows Firewall blocks Apache, allow Apache/httpd through the private
network firewall. Also confirm the API opens from the phone browser:

```text
http://192.168.1.20/student_expense_manager_api/api.php?action=ping
```

## 7. How synchronization works

- Account data requires a reachable backend; local record copies are not kept.
- Registration and login use the PHP API when the server is available.
- The API stores passwords with PHP `password_hash()` and returns a token for
  subsequent authenticated requests.
- Transaction changes wait for the server response before the form reports
  success. A failed save is rolled back in the UI and shows an error.
- Account state is pulled from the database after login and session validation.

## 8. Important development limitation

For production, deploy the PHP API behind HTTPS, use a dedicated MySQL user
instead of `root`, and restrict CORS to your application origins. Email and SMS
delivery also require server-side mail configuration and Twilio credentials;
never place these credentials in the Flutter app.

## 9. Recommended Android Studio workflow

1. Open the extracted `student_expense_manager` folder in Android Studio.
2. Start XAMPP Apache + MySQL.
3. Import the SQL file in phpMyAdmin.
4. Copy the backend folder to `htdocs`.
5. Run `flutter clean`.
6. Run `flutter pub get`.
7. Select Chrome for browser testing or an Android emulator/phone for Android
   testing.
8. Create a new account.
9. Add income, expenses, transfers, budgets, notes and reminders.
10. Refresh/login on another client to verify that the same backend account
    data is available.



## Important synchronization troubleshooting

If the server returns HTTP 500, check the PHP error log and confirm
`backend/config.php` points to the imported database. A transaction is not
reported as saved until the API accepts it. Data is not written to a local
offline cache.

For browser testing, use the same machine as XAMPP and set `API_BASE_URL` if your folder differs. For Android Emulator use `10.0.2.2`; for a physical phone use the computer's LAN IP. Plain HTTP is suitable only for local development; use HTTPS before deploying publicly.
