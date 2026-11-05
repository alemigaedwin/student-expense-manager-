<?php
/**
 * Student Expense Manager - Live Database Viewer & Admin Dashboard
 * Allows students and administrators to inspect all synchronized records,
 * transactions, budgets, accounts, and alerts directly in any browser.
 */

declare(strict_types=1);

$config = file_exists(__DIR__ . '/config.php') ? require __DIR__ . '/config.php' : [];

$host = $config['db_host'] ?? '127.0.0.1';
$dbname = $config['db_name'] ?? 'student_expense_manager';
$user = $config['db_user'] ?? 'root';
$pass = $config['db_password'] ?? '';
$charset = $config['db_charset'] ?? 'utf8mb4';

$connected = false;
$error = null;
$pdo = null;

try {
    $dsn = "mysql:host={$host};dbname={$dbname};charset={$charset}";
    $pdo = new PDO($dsn, $user, $pass, [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
    ]);
    $connected = true;
} catch (Throwable $e) {
    $error = $e->getMessage();
}

$tab = $_GET['tab'] ?? 'transactions';
$search = trim($_GET['search'] ?? '');

$stats = ['users' => 0, 'transactions' => 0, 'income' => 0.0, 'expense' => 0.0, 'balance' => 0.0, 'alerts' => 0];
$usersList = [];
$transactionsList = [];
$budgetsList = [];
$notificationsList = [];

if ($connected && $pdo) {
    try {
        $stats['users'] = (int)$pdo->query("SELECT COUNT(*) FROM users")->fetchColumn();
        $stats['transactions'] = (int)$pdo->query("SELECT COUNT(*) FROM transactions WHERE is_deleted=0")->fetchColumn();
        $stats['alerts'] = (int)$pdo->query("SELECT COUNT(*) FROM notifications")->fetchColumn();

        $incStmt = $pdo->query("SELECT COALESCE(SUM(amount), 0) FROM transactions WHERE type=0 AND is_deleted=0");
        $stats['income'] = (float)$incStmt->fetchColumn();

        $expStmt = $pdo->query("SELECT COALESCE(SUM(amount), 0) FROM transactions WHERE type=1 AND is_deleted=0");
        $stats['expense'] = (float)$expStmt->fetchColumn();

        $stats['balance'] = $stats['income'] - $stats['expense'];

        // Load Users
        $usersList = $pdo->query("SELECT u.id, u.full_name, u.email, u.created_at,
                                         COALESCE(p.phone_number, '-') AS phone,
                                         COALESCE(p.reminder_time, '20:00') AS reminder_time,
                                         (SELECT COUNT(*) FROM transactions t WHERE t.user_id=u.id AND t.is_deleted=0) AS tx_count
                                  FROM users u
                                  LEFT JOIN notification_preferences p ON p.user_id=u.id
                                  ORDER BY u.created_at DESC")->fetchAll();

        // Load Transactions
        $txQuery = "SELECT t.id, t.type, t.amount, t.notes, t.transaction_date, t.is_deleted,
                           u.full_name AS student_name, u.email,
                           COALESCE(c.name, 'General') AS category_name,
                           COALESCE(pm.name, 'Cash') AS payment_method
                    FROM transactions t
                    JOIN users u ON u.id = t.user_id
                    LEFT JOIN categories c ON c.id = t.category_id
                    LEFT JOIN payment_methods pm ON pm.id = t.payment_method_id
                    WHERE t.is_deleted = 0";
        if ($search !== '') {
            $txQuery .= " AND (u.full_name LIKE :s OR t.notes LIKE :s OR c.name LIKE :s)";
            $stmt = $pdo->prepare($txQuery . " ORDER BY t.transaction_date DESC LIMIT 100");
            $stmt->execute([':s' => "%$search%"]);
            $transactionsList = $stmt->fetchAll();
        } else {
            $transactionsList = $pdo->query($txQuery . " ORDER BY t.transaction_date DESC LIMIT 100")->fetchAll();
        }

        // Load Budgets
        $budgetsList = $pdo->query("SELECT b.id, b.amount, b.period, b.period_start,
                                           u.full_name AS student_name,
                                           COALESCE(c.name, 'Overall') AS category_name
                                    FROM budgets b
                                    JOIN users u ON u.id = b.user_id
                                    LEFT JOIN categories c ON c.id = b.category_id
                                    ORDER BY b.created_at DESC LIMIT 50")->fetchAll();

        // Load Notifications
        $notificationsList = $pdo->query("SELECT n.id, n.notification_type, n.title, n.message, n.channel, n.delivery_status, n.created_at,
                                                 u.full_name AS student_name
                                          FROM notifications n
                                          JOIN users u ON u.id = n.user_id
                                          ORDER BY n.created_at DESC LIMIT 50")->fetchAll();

    } catch (Throwable $e) {
        $error = "Query error: " . $e->getMessage();
    }
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Student Expense Manager - Live Database Viewer</title>
    <style>
        :root {
            --primary: #2563eb;
            --primary-dark: #1d4ed8;
            --income: #10b981;
            --expense: #ef4444;
            --bg: #f8fafc;
            --surface: #ffffff;
            --text: #0f172a;
            --text-muted: #64748b;
            --border: #e2e8f0;
        }
        * { box-sizing: border-box; margin: 0; padding: 0; }
        body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; background: var(--bg); color: var(--text); line-height: 1.5; padding: 24px; }
        .container { max-width: 1200px; margin: 0 auto; }
        header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 24px; flex-wrap: wrap; gap: 16px; background: var(--surface); padding: 20px 24px; border-radius: 14px; box-shadow: 0 1px 3px rgba(0,0,0,0.05); }
        .logo-area { display: flex; align-items: center; gap: 12px; }
        .logo-area h1 { font-size: 22px; font-weight: 800; color: #1e293b; }
        .logo-area span { font-size: 13px; color: var(--text-muted); }
        .badge { display: inline-flex; align-items: center; gap: 6px; padding: 6px 12px; border-radius: 9999px; font-size: 13px; font-weight: 600; }
        .badge-success { background: #dcfce7; color: #15803d; }
        .badge-error { background: #fee2e2; color: #b91c1c; }
        .stats-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 16px; margin-bottom: 24px; }
        .stat-card { background: var(--surface); padding: 20px; border-radius: 12px; border: 1px solid var(--border); box-shadow: 0 1px 2px rgba(0,0,0,0.03); }
        .stat-card .label { font-size: 13px; font-weight: 600; color: var(--text-muted); text-transform: uppercase; letter-spacing: 0.5px; }
        .stat-card .value { font-size: 24px; font-weight: 700; margin-top: 6px; }
        .val-income { color: var(--income); }
        .val-expense { color: var(--expense); }
        .val-balance { color: var(--primary); }
        .tabs { display: flex; gap: 8px; margin-bottom: 16px; border-bottom: 2px solid var(--border); padding-bottom: 8px; flex-wrap: wrap; }
        .tab-btn { padding: 8px 16px; border-radius: 8px; text-decoration: none; color: var(--text-muted); font-weight: 600; font-size: 14px; transition: all 0.2s; }
        .tab-btn.active, .tab-btn:hover { background: var(--primary); color: #fff; }
        .panel { background: var(--surface); border-radius: 12px; border: 1px solid var(--border); overflow: hidden; box-shadow: 0 1px 3px rgba(0,0,0,0.05); }
        .panel-header { padding: 16px 20px; border-bottom: 1px solid var(--border); display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 12px; }
        .search-box { display: flex; gap: 8px; }
        .search-box input { padding: 8px 14px; border: 1px solid var(--border); border-radius: 8px; font-size: 14px; outline: none; width: 240px; }
        .search-box button { padding: 8px 16px; background: var(--primary); color: #fff; border: none; border-radius: 8px; cursor: pointer; font-weight: 600; }
        .btn-action { display: inline-flex; align-items: center; gap: 6px; padding: 8px 16px; background: #0284c7; color: #fff; border-radius: 8px; text-decoration: none; font-size: 13px; font-weight: 600; }
        table { width: 100%; border-collapse: collapse; text-align: left; font-size: 14px; }
        th { background: #f1f5f9; padding: 12px 18px; font-weight: 600; color: #475569; }
        td { padding: 12px 18px; border-bottom: 1px solid var(--border); }
        tr:hover td { background: #f8fafc; }
        .pill { display: inline-block; padding: 3px 8px; border-radius: 6px; font-size: 12px; font-weight: 600; }
        .pill-income { background: #dcfce7; color: #15803d; }
        .pill-expense { background: #fee2e2; color: #b91c1c; }
        .pill-channel { background: #e0f2fe; color: #0369a1; }
        .footer-note { margin-top: 24px; padding: 16px; background: #e0e7ff; border-radius: 10px; color: #3730a3; font-size: 13px; }
    </style>
</head>
<body>
<div class="container">
    <header>
        <div class="logo-area">
            <div>
                <h1>🎓 Student Expense Manager — Database Viewer</h1>
                <span>Real-time inspection of database: <strong><?= htmlspecialchars($dbname) ?></strong> on <strong><?= htmlspecialchars($host) ?></strong></span>
            </div>
        </div>
        <div>
            <?php if ($connected): ?>
                <span class="badge badge-success">● Database Connected</span>
            <?php else: ?>
                <span class="badge badge-error">● Connection Failed</span>
            <?php endif; ?>
            <a href="send_alerts.php?action=test" target="_blank" class="btn-action" style="margin-left: 10px;">🔔 Trigger Alert Check</a>
        </div>
    </header>

    <?php if ($error): ?>
        <div style="background: #fee2e2; color: #991b1b; padding: 16px; border-radius: 10px; margin-bottom: 20px;">
            <strong>Database Notice:</strong> <?= htmlspecialchars($error) ?>
        </div>
    <?php endif; ?>

    <div class="stats-grid">
        <div class="stat-card">
            <div class="label">Registered Students</div>
            <div class="value"><?= number_format($stats['users']) ?></div>
        </div>
        <div class="stat-card">
            <div class="label">Total Transactions</div>
            <div class="value"><?= number_format($stats['transactions']) ?></div>
        </div>
        <div class="stat-card">
            <div class="label">Total Recorded Income</div>
            <div class="value val-income">+<?= number_format($stats['income'], 2) ?></div>
        </div>
        <div class="stat-card">
            <div class="label">Total Recorded Expenses</div>
            <div class="value val-expense">-<?= number_format($stats['expense'], 2) ?></div>
        </div>
        <div class="stat-card">
            <div class="label">Current Net Balance</div>
            <div class="value val-balance"><?= number_format($stats['balance'], 2) ?></div>
        </div>
        <div class="stat-card">
            <div class="label">Alerts & Reminders Sent</div>
            <div class="value"><?= number_format($stats['alerts']) ?></div>
        </div>
    </div>

    <div class="tabs">
        <a href="?tab=transactions" class="tab-btn <?= $tab === 'transactions' ? 'active' : '' ?>">Transactions (<?= count($transactionsList) ?>)</a>
        <a href="?tab=users" class="tab-btn <?= $tab === 'users' ? 'active' : '' ?>">Student Accounts (<?= count($usersList) ?>)</a>
        <a href="?tab=budgets" class="tab-btn <?= $tab === 'budgets' ? 'active' : '' ?>">Budgets (<?= count($budgetsList) ?>)</a>
        <a href="?tab=alerts" class="tab-btn <?= $tab === 'alerts' ? 'active' : '' ?>">Alerts History (<?= count($notificationsList) ?>)</a>
    </div>

    <div class="panel">
        <?php if ($tab === 'transactions'): ?>
            <div class="panel-header">
                <h3>Recorded Student Transactions</h3>
                <form class="search-box" method="GET">
                    <input type="hidden" name="tab" value="transactions">
                    <input type="text" name="search" placeholder="Search student, note, category..." value="<?= htmlspecialchars($search) ?>">
                    <button type="submit">Filter</button>
                </form>
            </div>
            <table>
                <thead>
                    <tr>
                        <th>Date & Time</th>
                        <th>Student</th>
                        <th>Type</th>
                        <th>Amount</th>
                        <th>Category</th>
                        <th>Method</th>
                        <th>Notes / Memo</th>
                    </tr>
                </thead>
                <tbody>
                    <?php if (empty($transactionsList)): ?>
                        <tr><td colspan="7" style="text-align: center; color: var(--text-muted); padding: 32px;">No transactions recorded yet. When transactions are added in the smartphone app, they appear here instantly!</td></tr>
                    <?php else: foreach ($transactionsList as $tx): ?>
                        <tr>
                            <td><?= htmlspecialchars($tx['transaction_date']) ?></td>
                            <td><strong><?= htmlspecialchars($tx['student_name']) ?></strong><br><small style="color:var(--text-muted)"><?= htmlspecialchars($tx['email']) ?></small></td>
                            <td>
                                <?php if ((int)$tx['type'] === 0): ?>
                                    <span class="pill pill-income">Income</span>
                                <?php else: ?>
                                    <span class="pill pill-expense">Expense</span>
                                <?php endif; ?>
                            </td>
                            <td><strong><?= number_format((float)$tx['amount'], 2) ?></strong></td>
                            <td><?= htmlspecialchars($tx['category_name']) ?></td>
                            <td><?= htmlspecialchars($tx['payment_method']) ?></td>
                            <td><?= htmlspecialchars($tx['notes'] ?: '-') ?></td>
                        </tr>
                    <?php endforeach; endif; ?>
                </tbody>
            </table>

        <?php elseif ($tab === 'users'): ?>
            <div class="panel-header">
                <h3>Registered Student Accounts</h3>
            </div>
            <table>
                <thead>
                    <tr>
                        <th>Name</th>
                        <th>Email</th>
                        <th>Phone</th>
                        <th>Preferred Alert Time</th>
                        <th>Transactions Logged</th>
                        <th>Joined Date</th>
                    </tr>
                </thead>
                <tbody>
                    <?php if (empty($usersList)): ?>
                        <tr><td colspan="6" style="text-align: center; color: var(--text-muted); padding: 32px;">No student accounts registered yet.</td></tr>
                    <?php else: foreach ($usersList as $u): ?>
                        <tr>
                            <td><strong><?= htmlspecialchars($u['full_name']) ?></strong></td>
                            <td><?= htmlspecialchars($u['email']) ?></td>
                            <td><?= htmlspecialchars($u['phone']) ?></td>
                            <td><?= htmlspecialchars($u['reminder_time']) ?></td>
                            <td><span class="pill pill-channel"><?= (int)$u['tx_count'] ?> records</span></td>
                            <td><?= htmlspecialchars($u['created_at']) ?></td>
                        </tr>
                    <?php endforeach; endif; ?>
                </tbody>
            </table>

        <?php elseif ($tab === 'budgets'): ?>
            <div class="panel-header">
                <h3>Active Budgets</h3>
            </div>
            <table>
                <thead>
                    <tr>
                        <th>Student</th>
                        <th>Category</th>
                        <th>Budget Limit</th>
                        <th>Period</th>
                        <th>Period Start</th>
                    </tr>
                </thead>
                <tbody>
                    <?php if (empty($budgetsList)): ?>
                        <tr><td colspan="5" style="text-align: center; color: var(--text-muted); padding: 32px;">No budgets configured yet.</td></tr>
                    <?php else: foreach ($budgetsList as $b): ?>
                        <tr>
                            <td><strong><?= htmlspecialchars($b['student_name']) ?></strong></td>
                            <td><?= htmlspecialchars($b['category_name']) ?></td>
                            <td><strong><?= number_format((float)$b['amount'], 2) ?></strong></td>
                            <td><?= (int)$b['period'] === 1 ? 'Weekly' : ((int)$b['period'] === 2 ? 'Yearly' : 'Monthly') ?></td>
                            <td><?= htmlspecialchars($b['period_start']) ?></td>
                        </tr>
                    <?php endforeach; endif; ?>
                </tbody>
            </table>

        <?php elseif ($tab === 'alerts'): ?>
            <div class="panel-header">
                <h3>Notification & Alert Dispatch Log</h3>
            </div>
            <table>
                <thead>
                    <tr>
                        <th>Time Sent</th>
                        <th>Student</th>
                        <th>Alert Type</th>
                        <th>Title</th>
                        <th>Channel</th>
                        <th>Status</th>
                        <th>Message</th>
                    </tr>
                </thead>
                <tbody>
                    <?php if (empty($notificationsList)): ?>
                        <tr><td colspan="7" style="text-align: center; color: var(--text-muted); padding: 32px;">No alerts triggered yet. Click "Trigger Alert Check" above to run an automated alert pass.</td></tr>
                    <?php else: foreach ($notificationsList as $n): ?>
                        <tr>
                            <td><?= htmlspecialchars($n['created_at']) ?></td>
                            <td><strong><?= htmlspecialchars($n['student_name']) ?></strong></td>
                            <td><?= htmlspecialchars($n['notification_type']) ?></td>
                            <td><?= htmlspecialchars($n['title']) ?></td>
                            <td><span class="pill pill-channel"><?= htmlspecialchars($n['channel']) ?></span></td>
                            <td><span class="pill pill-income"><?= htmlspecialchars($n['delivery_status']) ?></span></td>
                            <td><small><?= htmlspecialchars($n['message']) ?></small></td>
                        </tr>
                    <?php endforeach; endif; ?>
                </tbody>
            </table>
        <?php endif; ?>
    </div>

    <div class="footer-note">
        💡 <strong>Connecting your smartphone to this database:</strong><br>
        On your smartphone, open the <strong>Student Expense Manager</strong> app. On the Login screen, tap the <strong>Server: ...</strong> button. Enter your computer's IP address (e.g. <code>http://<?= gethostbyname(gethostname()) ?>/student_expense_manager_backend/backend/api.php</code>), tap <strong>Test Connection</strong>, and tap <strong>Save</strong>. All data entered on the phone will be stored here in MySQL!
    </div>
</div>
</body>
</html>
