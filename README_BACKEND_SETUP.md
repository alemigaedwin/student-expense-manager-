# Student Expense Manager — XAMPP + phpMyAdmin setup

This build uses Flutter for the app, PHP for the API, and MySQL/MariaDB for the database. Registration creates a database account and returns the user to Login. The main application opens only after the API accepts the email and password.

## 1. Put the project in XAMPP

Extract the ZIP so that these files exist:

`C:\\xampp\\htdocs\\student_expense_manager_backend\\student_expense_manager\\backend\\api.php`

`C:\\xampp\\htdocs\\student_expense_manager_backend\\student_expense_manager\\backend\\config.php`

Do not move `backend` outside the `student_expense_manager` folder unless you also change the API URL in `lib/services/backend_service.dart`.

## 2. Start XAMPP

1. Open XAMPP Control Panel.
2. Start **Apache** and **MySQL**.
3. Visit `http://localhost/student_expense_manager_backend/student_expense_manager/backend/api.php?action=ping`.
4. A successful response is JSON containing `"success":true` and `"database":"connected"`. If it says server error, check the database settings below and Apache/PHP logs.

## 3. Import the database

1. Open `http://localhost/phpmyadmin`.
2. Select **Import**.
3. Choose `backend/student_expense_manager.sql` from the extracted project.
4. Click **Import** / **Go**.
5. Confirm that the `student_expense_manager` database appears and contains tables such as `users`, `sessions`, `password_reset_tokens`, `transactions`, `budgets`, `categories`, and `accounts`.

## 4. Check the PHP database configuration

Create `backend/config.php` by copying `backend/config.example.php`. For a normal local XAMPP installation, set:

- `db_host`: `127.0.0.1`
- `db_name`: `student_expense_manager`
- `db_user`: `root`
- `db_password`: empty string if your local XAMPP root account has no password

If you set a MySQL root password, enter it as `db_password`. Never publish a real database password.

## 5. Run on a computer browser (Edge/Chrome)

The default web API address is:

`http://localhost/student_expense_manager_backend/student_expense_manager/backend/api.php`

Open the Flutter project folder `student_expense_manager` in Android Studio, then run:

```bash
flutter pub get
flutter run -d edge
```

Use `http://localhost/...` in the browser only when Apache/MySQL are running on the same computer.

## 6. Run on Android

- **Android emulator:** the app uses `10.0.2.2` to reach the host computer. Start Apache/MySQL first, then run the Android emulator from Android Studio.
- **Physical Android phone:** connect the phone and computer to the same Wi-Fi network. Find the computer's local IPv4 address using `ipconfig`, then run Flutter with the API URL set to that address, for example:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.10/student_expense_manager_backend/student_expense_manager/backend/api.php
```

Replace `192.168.1.10` with your computer's actual IPv4 address. Allow Apache through Windows Firewall on a trusted private network if prompted. The phone must be able to reach the computer on the Apache port. Do not use `localhost` for a physical phone; that would point to the phone itself.

## 7. Confirm the registration/login/database flow

1. Open the app and choose **Create account**.
2. Enter a name, unique email, and password with at least 6 characters.
3. After a successful registration, the app returns to the Login screen; it does not sign in automatically.
4. Log in using the same email and password. Only a successful API login opens the main application.
5. In phpMyAdmin, open `student_expense_manager` → `users`; the new user should appear. Passwords are stored as hashes, not plain text.
6. Add an income or expense, budget, category, note, or reminder. The app reads and writes account records directly through the authenticated API. Check the corresponding database tables, especially `transactions`, `budgets`, `categories`, `notes`, and `reminders`.

## Notes and troubleshooting

- Keep Apache and MySQL running while using the app. Login and account data require a reachable server; transaction records are not stored in an offline device/browser cache.
- If an email already exists, use that account to log in or register with a different email.
- For a phone, check the Windows Firewall and use the PC's IPv4 address in `API_BASE_URL`.
- The app API is configured for local development over HTTP. For deployment outside a trusted local network, use HTTPS, restrict CORS, and use a dedicated MySQL user with only the required permissions rather than the XAMPP root account.
- Receipts are uploaded to the database (see section 10). Bills attached before this update were saved only as device file paths; they show as "Old attachment (not stored)" and must be re-attached to be kept.


## 8. Daily email/SMS reminders and balance alerts

The SQL file now includes `notification_preferences` and `notifications`. If your database was imported before these tables were added, open phpMyAdmin, select `student_expense_manager`, choose **Import**, and import the updated `backend/student_expense_manager.sql` (the statements use `CREATE TABLE IF NOT EXISTS`). Back up the database first.

The in-app bell opens notification history and a current balance summary. The daily sender is `backend/daily_notifications.php`. Schedule it once each day using Windows Task Scheduler (for example, run `C:\xampp\php\php.exe C:\xampp\htdocs\student_expense_manager_backend\student_expense_manager\backend\daily_notifications.php`). The script is CLI-only and must not be exposed as a public URL.

Email delivery uses PHP `mail()`, which normally requires SMTP to be configured in XAMPP's `php.ini` and `sendmail.ini`; test delivery to a real inbox before relying on reminders or password reset codes. SMS delivery uses Twilio and requires `twilio_account_sid`, `twilio_auth_token`, and `twilio_from_number` in `backend/config.php`, plus an enabled Twilio account and valid recipient phone numbers in international format (for Uganda, e.g. `+2567...`). Never share these credentials publicly. SMS is recorded as `not_configured` until credentials are provided.

## 9. Reports

Open **Reports**, choose a start date and end date, press **This month**, or use **Choose month** for any month. Choose whether the report covers the current account or all of the user's accounts. PDF and Excel exports use the selected server-backed transactions. Excel includes transaction date, transaction ID, account name, type, category, amount, notes, item details, receipt attachment paths, and income/expense/net totals. Receipt paths are references; the actual files are not embedded in the spreadsheet unless they are separately uploaded to a server.

## 10. Receipt uploads (stored in the database)

**Upgrading an existing database:** back it up, then import the updated `backend/student_expense_manager.sql` in phpMyAdmin. It only adds the new `receipts` table (`CREATE TABLE IF NOT EXISTS`), so existing data is untouched. Also copy the Apache rules from the updated `backend/.htaccess` (they pass the login token to PHP).

**Required MySQL setting:** receipts are stored as `LONGBLOB`, so MySQL must accept packets at least as large as one receipt. In XAMPP open `C:\xampp\mysql\bin\my.ini`, set `max_allowed_packet=16M` under `[mysqld]`, then restart MySQL. Without it, uploads of larger files fail with a "max_allowed_packet" message.

**How it works**
- On **Add Income/Expense**, tap **Add Bills** and choose Camera, Gallery, or PDF. The file uploads immediately (the button shows *Uploading...*) and appears as a chip. Tap a chip to view it; tap **x** to remove it.
- Photos are downscaled on the phone (max 1600 px). Allowed types: JPG, PNG, WEBP, PDF. Limits: 4 MB per file, 5 per transaction, 200 MB per user (change in `config.php`: `max_receipt_bytes`, `user_receipt_quota_bytes`).
- The server checks the real file type from the file's bytes, and only the owner of a receipt can download or delete it.
- Table `receipts` holds the file; `transaction_bills.bill_path` holds the reference `receipt:<id>`. Receipts appear under each transaction in lists, and the Excel report lists their file names.
- Uploads never attached to a saved transaction are deleted automatically (when you leave the screen, or after one day). Removing a receipt from a saved transaction, or permanently deleting the transaction, deletes the file.
