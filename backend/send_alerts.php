<?php
/**
 * Student Expense Manager - Automated Alerts & Notifications Dispatcher
 *
 * 100% Free resources:
 * 1. Free In-App notifications stored in database.
 * 2. Free Email notifications via PHP mail() or free Gmail / standard SMTP.
 * 3. Free SMS via Email-to-SMS gateways (e.g. number@vtext.com, number@txt.att.net, number@tmomail.net).
 * 4. Free Telegram Bot notifications.
 *
 * Can be run:
 * - Via browser or HTTP request: http://your-host/backend/send_alerts.php
 * - Via free cron service: https://cron-job.org (free forever, calls URL at user's preferred times)
 * - Directly from the database viewer or Flutter app
 */

declare(strict_types=1);

ob_start();
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

$config = file_exists(__DIR__ . '/config.php') ? require __DIR__ . '/config.php' : [];

function getPdo(array $c): PDO {
    $host = $c['db_host'] ?? '127.0.0.1';
    $dbname = $c['db_name'] ?? 'student_expense_manager';
    $user = $c['db_user'] ?? 'root';
    $pass = $c['db_password'] ?? '';
    $charset = $c['db_charset'] ?? 'utf8mb4';

    $dsn = "mysql:host={$host};dbname={$dbname};charset={$charset}";
    return new PDO($dsn, $user, $pass, [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        PDO::ATTR_EMULATE_PREPARES => false,
    ]);
}

/**
 * Free Lightweight SMTP client using standard PHP sockets (no composer needed).
 * Works with Gmail (smtp.gmail.com:587) with a free App Password or any SMTP server.
 */
function sendSmtpMail(array $c, string $to, string $subject, string $body): bool {
    $host = $c['smtp_host'] ?? 'smtp.gmail.com';
    $port = (int)($c['smtp_port'] ?? 587);
    $user = $c['smtp_username'] ?? '';
    $pass = $c['smtp_password'] ?? '';
    $from = $c['email_from'] ?? ($user ?: 'no-reply@studentexpensemanager.local');
    $fromName = $c['email_from_name'] ?? 'Student Expense Manager';

    if (empty($user) || empty($pass)) {
        // Fall back to standard PHP mail()
        $headers = "From: {$fromName} <{$from}>\r\nReply-To: {$from}\r\nContent-Type: text/html; charset=UTF-8\r\n";
        return @mail($to, $subject, $body, $headers);
    }

    $timeout = 10;
    $socket = @fsockopen($host, $port, $errno, $errstr, $timeout);
    if (!$socket) {
        error_log("SMTP connection failed: $errstr ($errno)");
        return false;
    }

    $read = function() use ($socket) {
        $data = '';
        while ($line = fgets($socket, 515)) {
            $data .= $line;
            if (isset($line[3]) && $line[3] === ' ') break;
        }
        return $data;
    };
    $write = function(string $cmd) use ($socket) {
        fputs($socket, $cmd . "\r\n");
    };

    $read();
    $write("EHLO " . gethostname());
    $read();

    if ($port === 587) {
        $write("STARTTLS");
        $res = $read();
        if (strpos($res, '220') === false) {
            fclose($socket);
            return false;
        }
        stream_socket_enable_crypto($socket, true, STREAM_CRYPTO_METHOD_TLSv1_2_CLIENT);
        $write("EHLO " . gethostname());
        $read();
    }

    $write("AUTH LOGIN");
    $read();
    $write(base64_encode($user));
    $read();
    $write(base64_encode($pass));
    $authRes = $read();
    if (strpos($authRes, '235') === false) {
        fclose($socket);
        error_log("SMTP authentication failed: " . $authRes);
        return false;
    }

    $write("MAIL FROM: <{$from}>");
    $read();
    $write("RCPT TO: <{$to}>");
    $read();
    $write("DATA");
    $read();

    $content  = "From: {$fromName} <{$from}>\r\n";
    $content .= "To: <{$to}>\r\n";
    $content .= "Subject: {$subject}\r\n";
    $content .= "MIME-Version: 1.0\r\n";
    $content .= "Content-Type: text/html; charset=UTF-8\r\n\r\n";
    $content .= $body . "\r\n.\r\n";

    $write($content);
    $read();
    $write("QUIT");
    $read();
    fclose($socket);
    return true;
}

function sendEmailAlert(array $c, string $to, string $subject, string $htmlBody): bool {
    $driver = strtolower($c['mail_driver'] ?? 'smtp');
    if ($driver === 'smtp' && !empty($c['smtp_username'])) {
        return sendSmtpMail($c, $to, $subject, $htmlBody);
    }
    $from = $c['email_from'] ?? 'no-reply@studentexpensemanager.local';
    $fromName = $c['email_from_name'] ?? 'Student Expense Manager';
    $headers = "From: {$fromName} <{$from}>\r\nReply-To: {$from}\r\nMIME-Version: 1.0\r\nContent-Type: text/html; charset=UTF-8\r\n";
    return @mail($to, $subject, $htmlBody, $headers);
}

/**
 * Free SMS delivery via Email-to-SMS gateway.
 * Most mobile networks worldwide map a free SMS address to user phone numbers.
 */
function sendSmsAlert(array $c, string $phone, string $carrierGateway, string $message): bool {
    $cleanPhone = preg_replace('/[^0-9]/', '', $phone);
    if (!empty($carrierGateway)) {
        $to = "{$cleanPhone}@{$carrierGateway}";
        $from = $c['email_from'] ?? 'no-reply@studentexpensemanager.local';
        $headers = "From: {$from}\r\nContent-Type: text/plain; charset=UTF-8\r\n";
        return @mail($to, 'Alert', $message, $headers);
    }
    // Fallback: If Twilio credentials exist in config.php
    if (!empty($c['twilio_account_sid']) && !empty($c['twilio_auth_token']) && !empty($c['twilio_from_number'])) {
        $sid = $c['twilio_account_sid'];
        $token = $c['twilio_auth_token'];
        $from = $c['twilio_from_number'];
        $url = "https://api.twilio.com/2010-04-01/Accounts/{$sid}/Messages.json";
        $data = http_build_query(['From' => $from, 'To' => $phone, 'Body' => $message]);
        $ctx = stream_context_create([
            'http' => [
                'method' => 'POST',
                'header' => "Authorization: Basic " . base64_encode("{$sid}:{$token}") . "\r\nContent-Type: application/x-www-form-urlencoded\r\n",
                'content' => $data,
                'timeout' => 8,
            ]
        ]);
        $res = @file_get_contents($url, false, $ctx);
        return $res !== false;
    }
    return false;
}

/**
 * Free Telegram message delivery
 */
function sendTelegramAlert(array $c, string $chatId, string $message): bool {
    $token = $c['telegram_bot_token'] ?? '';
    if (empty($token) || empty($chatId)) return false;
    $url = "https://api.telegram.org/bot{$token}/sendMessage";
    $postData = json_encode(['chat_id' => $chatId, 'text' => $message, 'parse_mode' => 'HTML']);
    $ctx = stream_context_create([
        'http' => [
            'method' => 'POST',
            'header' => "Content-Type: application/json\r\n",
            'content' => $postData,
            'timeout' => 8,
        ]
    ]);
    $res = @file_get_contents($url, false, $ctx);
    return $res !== false;
}

try {
    $pdo = getPdo($config);

    // Auto-migrate schema: ensure columns exist in notification_preferences
    try {
        $cols = $pdo->query("SHOW COLUMNS FROM notification_preferences")->fetchAll(PDO::FETCH_COLUMN);
        if (!in_array('reminder_time', $cols, true)) {
            $pdo->exec("ALTER TABLE notification_preferences ADD COLUMN reminder_time VARCHAR(10) NOT NULL DEFAULT '20:00'");
        }
        if (!in_array('carrier_gateway', $cols, true)) {
            $pdo->exec("ALTER TABLE notification_preferences ADD COLUMN carrier_gateway VARCHAR(60) NULL");
        }
        if (!in_array('telegram_chat_id', $cols, true)) {
            $pdo->exec("ALTER TABLE notification_preferences ADD COLUMN telegram_chat_id VARCHAR(50) NULL");
        }
    } catch (Throwable $e) {}

    $action = $_GET['action'] ?? $_POST['action'] ?? 'run_all';
    $targetUid = $_GET['user_id'] ?? $_POST['user_id'] ?? null;
    $currentTime = date('H:i');
    $today = date('Y-m-d');

    $sql = "SELECT u.id, u.full_name, u.email,
                   COALESCE(p.phone_number, '') AS phone_number,
                   COALESCE(p.email_enabled, 1) AS email_enabled,
                   COALESCE(p.sms_enabled, 0) AS sms_enabled,
                   COALESCE(p.daily_reminder_enabled, 1) AS daily_reminder_enabled,
                   COALESCE(p.balance_alert_enabled, 1) AS balance_alert_enabled,
                   COALESCE(p.low_balance_threshold, 0) AS low_balance_threshold,
                   COALESCE(p.reminder_time, '20:00') AS reminder_time,
                   COALESCE(p.carrier_gateway, '') AS carrier_gateway,
                   COALESCE(p.telegram_chat_id, '') AS telegram_chat_id
            FROM users u
            LEFT JOIN notification_preferences p ON p.user_id = u.id";

    if ($targetUid) {
        $stmt = $pdo->prepare($sql . " WHERE u.id = ?");
        $stmt->execute([$targetUid]);
    } else {
        $stmt = $pdo->query($sql);
    }

    $users = $stmt->fetchAll();
    $dispatched = [];

    $insNotice = $pdo->prepare("INSERT INTO notifications(user_id, notification_type, title, message, channel, delivery_status, notification_date)
                                VALUES(?, ?, ?, ?, ?, ?, ?)
                                ON DUPLICATE KEY UPDATE delivery_status=VALUES(delivery_status)");

    foreach ($users as $u) {
        $uid = $u['id'];
        $name = htmlspecialchars($u['full_name']);
        $email = $u['email'];
        $phone = $u['phone_number'];
        $reminderTime = $u['reminder_time'];
        $gateway = $u['carrier_gateway'];
        $telegramId = $u['telegram_chat_id'];

        // 1. Calculate user balance & transaction summary
        $sumStmt = $pdo->prepare("SELECT
            COALESCE(SUM(CASE WHEN type=0 AND is_deleted=0 THEN amount ELSE 0 END), 0) AS income,
            COALESCE(SUM(CASE WHEN type=1 AND is_deleted=0 THEN amount ELSE 0 END), 0) AS expense
            FROM transactions WHERE user_id = ?");
        $sumStmt->execute([$uid]);
        $summary = $sumStmt->fetch();
        $income = (float)$summary['income'];
        $expense = (float)$summary['expense'];
        $balance = $income - $expense;

        // 2. Low Balance Alert Check
        if ($u['balanceAlertEnabled'] || $u['balance_alert_enabled']) {
            $threshold = (float)$u['low_balance_threshold'];
            if ($balance <= $threshold) {
                // Check if already sent today
                $check = $pdo->prepare("SELECT id FROM notifications WHERE user_id=? AND notification_type='balance_alert' AND notification_date=?");
                $check->execute([$uid, $today]);
                if (!$check->fetch()) {
                    $title = "⚠️ Student Low Balance Warning";
                    $msg = "Hi {$name}, your student balance is currently " . number_format($balance, 2) . ", which is at or below your safety threshold of " . number_format($threshold, 2) . ". Consider checking your upcoming expenses!";
                    $html = "<div style='font-family:sans-serif;padding:16px;background:#fff3cd;color:#856404;border-radius:8px;'>
                                <h2>⚠️ Student Expense Alert</h2>
                                <p>Hi <strong>{$name}</strong>,</p>
                                <p>Your recorded balance is currently <strong>" . number_format($balance, 2) . "</strong>.</p>
                                <p>This has reached your limit threshold of <strong>" . number_format($threshold, 2) . "</strong>.</p>
                                <p>Open your <em>Student Expense Manager</em> app to review your budget.</p>
                             </div>";

                    $insNotice->execute([$uid, 'balance_alert', $title, $msg, 'in_app', 'sent', $today]);

                    if (!empty($u['email_enabled'])) {
                        $sent = sendEmailAlert($config, $email, $title, $html);
                        if ($sent) $insNotice->execute([$uid, 'balance_alert', $title, $msg, 'email', 'sent', $today]);
                    }
                    if (!empty($u['sms_enabled']) && !empty($phone)) {
                        $sentSms = sendSmsAlert($config, $phone, $gateway, $msg);
                        if ($sentSms) $insNotice->execute([$uid, 'balance_alert', $title, $msg, 'sms', 'sent', $today]);
                    }
                    if (!empty($telegramId)) {
                        sendTelegramAlert($config, $telegramId, "<b>{$title}</b>\n{$msg}");
                    }
                    $dispatched[] = ['user' => $name, 'type' => 'balance_alert', 'balance' => $balance];
                }
            }
        }

        // 3. Daily Reminder Check (Fires at user-specified time)
        // If run_all or time matches or force trigger
        $shouldTriggerDaily = ($action === 'force_daily' || $action === 'test') ||
                              ($u['daily_reminder_enabled'] && substr($currentTime, 0, 5) === substr($reminderTime, 0, 5));

        if ($shouldTriggerDaily && ($u['daily_reminder_enabled'] || $action === 'force_daily' || $action === 'test')) {
            $check = $pdo->prepare("SELECT id FROM notifications WHERE user_id=? AND notification_type='daily_reminder' AND notification_date=?");
            $check->execute([$uid, $today]);
            if (!$check->fetch() || $action === 'test') {
                $title = "📚 Student Expense Manager Reminder";
                $msg = "Hi {$name}, remember to record your campus expenses, meals, and pocket money for today! Keeping track daily keeps your budget in control.";
                $html = "<div style='font-family:sans-serif;padding:16px;background:#e8f4fd;color:#0c5460;border-radius:8px;'>
                            <h2>📚 Daily Expense Check-In</h2>
                            <p>Hi <strong>{$name}</strong>,</p>
                            <p>It's your scheduled check-in time (<strong>{$reminderTime}</strong>)!</p>
                            <p>Don't forget to record today's transport, canteen meals, books, or allowance.</p>
                            <p>Current balance: <strong>" . number_format($balance, 2) . "</strong></p>
                            <p><em>Student Expense Manager - Smart Money for Smart Students</em></p>
                         </div>";

                $insNotice->execute([$uid, 'daily_reminder', $title, $msg, 'in_app', 'sent', $today]);

                if (!empty($u['email_enabled'])) {
                    $sent = sendEmailAlert($config, $email, $title, $html);
                    if ($sent) $insNotice->execute([$uid, 'daily_reminder', $title, $msg, 'email', 'sent', $today]);
                }
                if (!empty($u['sms_enabled']) && !empty($phone)) {
                    $sentSms = sendSmsAlert($config, $phone, $gateway, $msg);
                    if ($sentSms) $insNotice->execute([$uid, 'daily_reminder', $title, $msg, 'sms', 'sent', $today]);
                }
                if (!empty($telegramId)) {
                    sendTelegramAlert($config, $telegramId, "<b>{$title}</b>\n{$msg}");
                }
                $dispatched[] = ['user' => $name, 'type' => 'daily_reminder', 'time' => $reminderTime];
            }
        }
    }

    echo json_encode([
        'success' => true,
        'message' => 'Alerts processed successfully.',
        'server_time' => date('Y-m-d H:i:s'),
        'users_checked' => count($users),
        'dispatched_count' => count($dispatched),
        'dispatched' => $dispatched,
    ], JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES);

} catch (Throwable $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'error' => $e->getMessage(),
    ]);
}
