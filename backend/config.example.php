<?php
// Copy this file to config.php and change these values for your XAMPP/WAMP setup.
// Keep config.php private and do not commit it to a public repository.
return [
    'db_host' => '127.0.0.1',
    'db_name' => 'student_expense_manager',
    'db_user' => 'root',
    'db_password' => '',
    'db_charset' => 'utf8mb4',
    'session_days' => 30,
    // PHP mail() must be configured on the server for email delivery.
    'email_from' => 'no-reply@example.com',
    // Leave blank until a Twilio account is configured in your server's
    // private config.php. Never place real credentials in this example file.
    'twilio_account_sid' => '',
    'twilio_auth_token' => '',
    'twilio_from_number' => '',
    // Receipt uploads (stored in the `receipts` table).
    'max_receipt_bytes' => 4194304,          // 4 MB per file
    'user_receipt_quota_bytes' => 209715200, // 200 MB per user
];
