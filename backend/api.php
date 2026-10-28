<?php
declare(strict_types=1);

ob_start();

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(204); exit; }

$config = file_exists(__DIR__ . '/config.php')
    ? require __DIR__ . '/config.php'
    : (file_exists(__DIR__ . '/config.example.php') ? require __DIR__ . '/config.example.php' : []);

function respond(bool $ok, string $message = '', $data = null, int $status = 200): never {
    if (ob_get_length()) ob_clean();
    http_response_code($status);
    echo json_encode(['success' => $ok, 'message' => $message, 'data' => $data],
        JSON_UNESCAPED_SLASHES);
    exit;
}
function input(): array {
    $raw = file_get_contents('php://input');
    if (!$raw) return $_POST ?: [];
    $json = json_decode($raw, true);
    return is_array($json) ? $json : ($_POST ?: []);
}
function ensureDatabaseAndTables(PDO $pdo, string $sqlPath): void {
    static $checked = false;
    if ($checked) return;
    $checked = true;
    try {
        $check = $pdo->query("SHOW TABLES LIKE 'users'");
        if ($check->rowCount() === 0 && file_exists($sqlPath)) {
            $sql = file_get_contents($sqlPath);
            if ($sql) {
                $pdo->exec($sql);
            }
        }
    } catch (Throwable $e) {
        error_log('Auto schema init notice: ' . $e->getMessage());
    }
}

function db(array $c): PDO {
    static $pdo;
    if ($pdo instanceof PDO) return $pdo;
    $host = $c['db_host'] ?? '127.0.0.1';
    $dbname = $c['db_name'] ?? 'student_expense_manager';
    $user = $c['db_user'] ?? 'root';
    $pass = $c['db_password'] ?? '';
    $charset = $c['db_charset'] ?? 'utf8mb4';

    try {
        $dsn = "mysql:host={$host};dbname={$dbname};charset={$charset}";
        $pdo = new PDO($dsn, $user, $pass, [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            PDO::ATTR_EMULATE_PREPARES => false,
        ]);
    } catch (PDOException $e) {
        if ($e->getCode() == 1049 || stripos($e->getMessage(), 'Unknown database') !== false) {
            $rootDsn = "mysql:host={$host};charset={$charset}";
            $initPdo = new PDO($rootDsn, $user, $pass, [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]);
            $initPdo->exec("CREATE DATABASE IF NOT EXISTS `{$dbname}` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci");
            $pdo = new PDO("mysql:host={$host};dbname={$dbname};charset={$charset}", $user, $pass, [
                PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
                PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                PDO::ATTR_EMULATE_PREPARES => false,
            ]);
        } else {
            throw $e;
        }
    }

    ensureDatabaseAndTables($pdo, __DIR__ . '/student_expense_manager.sql');
    return $pdo;
}
function uuid(): string {
    $d = random_bytes(16);
    $d[6] = chr((ord($d[6]) & 0x0f) | 0x40);
    $d[8] = chr((ord($d[8]) & 0x3f) | 0x80);
    return vsprintf('%s%s-%s-%s-%s-%s%s%s', str_split(bin2hex($d), 4));
}
function bearerToken(): string {
    // Apache can hide the Authorization header from PHP; check every place it may appear.
    $h = $_SERVER['HTTP_AUTHORIZATION'] ?? $_SERVER['REDIRECT_HTTP_AUTHORIZATION'] ?? '';
    if ($h === '' && function_exists('getallheaders')) {
        foreach (getallheaders() as $k => $v) {
            if (strcasecmp((string)$k, 'Authorization') === 0) { $h = (string)$v; break; }
        }
    }
    return preg_match('/Bearer\s+(.+)/i', $h, $m) ? trim($m[1]) : '';
}
function auth(PDO $pdo): array {
    $token = bearerToken();
    if ($token === '') respond(false, 'Authentication token required.', null, 401);
    $hash = hash('sha256', $token);
    $q = $pdo->prepare('SELECT s.user_id, u.full_name, u.email FROM sessions s JOIN users u ON u.id=s.user_id WHERE s.token_hash=? AND s.expires_at>NOW() LIMIT 1');
    $q->execute([$hash]);
    $user = $q->fetch();
    if (!$user) respond(false, 'Session expired. Please log in again.', null, 401);
    return $user;
}
function issueToken(PDO $pdo, string $userId, int $days): string {
    $token = bin2hex(random_bytes(32));
    $hash = hash('sha256', $token);
    $q = $pdo->prepare('INSERT INTO sessions(user_id,token_hash,expires_at) VALUES(?,?,DATE_ADD(NOW(), INTERVAL ? DAY))');
    $q->execute([$userId,$hash,$days]);
    return $token;
}
function dt($v): string {
    if ($v === null || $v === '') return date('Y-m-d H:i:s');
    try { $t = new DateTime((string)$v); } catch (Throwable $e) { $t = new DateTime(); }
    return $t->format('Y-m-d H:i:s');
}
function isoDate($v): string {
    if ($v === null || $v === '') return date('c');
    try { $ts = strtotime((string)$v); return $ts !== false ? date('c', $ts) : date('c'); } catch (Throwable $e) { return date('c'); }
}
function arr($v): array { return is_array($v) ? $v : []; }

const RECEIPT_PREFIX = 'receipt:';

function receiptIdFromRef($ref): ?string {
    $ref = (string)$ref;
    if (strncmp($ref, RECEIPT_PREFIX, strlen(RECEIPT_PREFIX)) !== 0) return null;
    $id = substr($ref, strlen(RECEIPT_PREFIX));
    return preg_match('/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/', $id) ? $id : null;
}
/** Detects the real file type from its first bytes; the client-sent MIME type is never trusted. */
function detectReceiptMime(string $b): ?string {
    if (strncmp($b, "\xFF\xD8\xFF", 3) === 0) return 'image/jpeg';
    if (strncmp($b, "\x89PNG\r\n\x1A\n", 8) === 0) return 'image/png';
    if (strncmp($b, '%PDF-', 5) === 0) return 'application/pdf';
    if (strlen($b) > 12 && substr($b, 0, 4) === 'RIFF' && substr($b, 8, 4) === 'WEBP') return 'image/webp';
    return null;
}
function receiptName(string $name): string {
    $name = basename(str_replace('\\', '/', $name));
    $name = preg_replace('/[\x00-\x1F\x7F<>:"|?*]+/u', '', $name) ?? '';
    $name = trim($name);
    if ($name === '') $name = 'receipt';
    return mb_substr($name, 0, 150);
}

function state(PDO $pdo, string $uid): array {
    $out = [];
    $queries = [
      'accounts'=>'SELECT id,name FROM accounts WHERE user_id=? ORDER BY created_at',
      'categories'=>'SELECT id,name,icon_code_point AS iconCodePoint,icon_font_family AS iconFontFamily,color_value AS colorValue,icon_asset AS iconAsset,kind,is_custom AS isCustom,parent_id AS parentId FROM categories WHERE user_id=?',
      'paymentMethods'=>'SELECT id,name,is_custom AS isCustom FROM payment_methods WHERE user_id=?',
      'transactions'=>'SELECT id,account_id AS accountId,type,amount,category_id AS categoryId,payment_method_id AS paymentMethodId,to_payment_method_id AS toPaymentMethodId,notes,transaction_date AS date,is_deleted AS isDeleted FROM transactions WHERE user_id=?',
      'budgets'=>'SELECT id,account_id AS accountId,category_id AS categoryId,amount,period,period_start AS periodStart FROM budgets WHERE user_id=?',
      'overallBudgets'=>'SELECT id,account_id AS accountId,amount,period,period_start AS periodStart FROM overall_budgets WHERE user_id=?',
      'notes'=>'SELECT id,account_id AS accountId,note_text AS text,date_time AS dateTime,completed FROM notes WHERE user_id=?',
      'reminders'=>'SELECT id,account_id AS accountId,category_id AS categoryId,payment_method_id AS paymentMethodId,amount,type,recurrence,next_date AS nextDate,notes FROM reminders WHERE user_id=?',
    ];
    foreach ($queries as $key=>$sql) {
        $q=$pdo->prepare($sql); $q->execute([$uid]); $rows=$q->fetchAll();
        foreach ($rows as &$r) {
            foreach (['amount','rate','quantity'] as $n) if (isset($r[$n])) $r[$n]=(float)$r[$n];
            foreach (['type','kind','period','recurrence','iconCodePoint','colorValue'] as $n) if (isset($r[$n])) $r[$n]=(int)$r[$n];
            foreach (['isCustom','isDeleted','completed'] as $b) if (isset($r[$b])) $r[$b]=(bool)$r[$b];
        }
        $out[$key]=$rows;
    }
    $q=$pdo->prepare('SELECT transaction_id,item_name,quantity,unit,rate FROM transaction_items WHERE transaction_id IN (SELECT id FROM transactions WHERE user_id=?) ORDER BY id');
    $q->execute([$uid]); $items=[];
    foreach($q->fetchAll() as $r) $items[$r['transaction_id']][]=[
        'name'=>$r['item_name'],'quantity'=>(float)$r['quantity'],'unit'=>$r['unit'],'rate'=>(float)$r['rate']
    ];
    $q=$pdo->prepare('SELECT transaction_id,bill_path FROM transaction_bills WHERE transaction_id IN (SELECT id FROM transactions WHERE user_id=?) ORDER BY id');
    $q->execute([$uid]); $bills=[];
    foreach($q->fetchAll() as $r) $bills[$r['transaction_id']][]=$r['bill_path'];
    foreach($out['transactions'] as &$t) {
        $t['amount']=(float)$t['amount'];
        $t['isDeleted']=(bool)$t['isDeleted'];
        $t['date']=isoDate($t['date'] ?? null);
        $t['items']=$items[$t['id']] ?? [];
        $t['billPaths']=$bills[$t['id']] ?? [];
    }
    $q=$pdo->prepare('SELECT id,transaction_id,file_name,mime_type,file_size FROM receipts WHERE user_id=? ORDER BY created_at');
    $q->execute([$uid]);
    $out['receipts']=array_map(static fn($r)=>[
        'id'=>$r['id'],'transactionId'=>$r['transaction_id'],'fileName'=>$r['file_name'],
        'mimeType'=>$r['mime_type'],'size'=>(int)$r['file_size'],
    ], $q->fetchAll());
    foreach($out['budgets'] as &$r){$r['amount']=(float)$r['amount'];$r['periodStart']=isoDate($r['periodStart'] ?? null);}
    foreach($out['overallBudgets'] as &$r){$r['amount']=(float)$r['amount'];$r['periodStart']=isoDate($r['periodStart'] ?? null);}
    foreach($out['notes'] as &$r){$r['completed']=(bool)$r['completed'];$r['dateTime']=isoDate($r['dateTime'] ?? null);}
    foreach($out['reminders'] as &$r){$r['amount']=(float)$r['amount'];$r['nextDate']=isoDate($r['nextDate'] ?? null);}
    $q=$pdo->prepare('SELECT setting_key,setting_value FROM user_settings WHERE user_id=?');$q->execute([$uid]);
    $out['settings']=(object)[]; foreach($q->fetchAll() as $r)$out['settings']->{$r['setting_key']} = $r['setting_value'];
    return $out;
}

function strOrNull($v): ?string {
    if ($v === null) return null;
    $s = trim((string)$v);
    return $s === '' ? null : $s;
}

class OwnershipException extends RuntimeException {}

function assertOwnedIds(PDO $pdo, string $uid, string $table, array $rows): void {
    $ids = [];
    foreach ($rows as $row) {
        if (is_array($row) && isset($row['id']) && (string)$row['id'] !== '') {
            $ids[] = (string)$row['id'];
        }
    }
    $ids = array_values(array_unique($ids));
    if (!$ids) return;
    $marks = implode(',', array_fill(0, count($ids), '?'));
    $q = $pdo->prepare("SELECT id FROM {$table} WHERE id IN ({$marks}) AND user_id<>? LIMIT 1");
    $q->execute([...$ids, $uid]);
    if ($q->fetchColumn() !== false) {
        throw new OwnershipException('A submitted record belongs to a different account.');
    }
}

function deleteOwnedIds(PDO $pdo, string $uid, string $table, array $rows): void {
    $ids = [];
    foreach ($rows as $row) {
        $id = is_array($row) ? ($row['id'] ?? null) : $row;
        if ($id !== null && (string)$id !== '') {
            $ids[] = (string)$id;
        }
    }
    $ids = array_values(array_unique($ids));
    if (!$ids) return;
    $marks = implode(',', array_fill(0, count($ids), '?'));
    $q = $pdo->prepare("DELETE FROM {$table} WHERE user_id=? AND id IN ({$marks})");
    $q->execute([$uid, ...$ids]);
}

function syncData(PDO $pdo, string $uid, array $s): void {
    $pdo->beginTransaction();
    try {
        // Validate every submitted primary key before touching any table. This
        // prevents an ID collision from one account modifying another user's
        // row or transaction child records.
        $ownedTables = [
            'accounts' => 'accounts',
            'categories' => 'categories',
            'paymentMethods' => 'payment_methods',
            'transactions' => 'transactions',
            'budgets' => 'budgets',
            'overallBudgets' => 'overall_budgets',
            'notes' => 'notes',
            'reminders' => 'reminders',
        ];
        foreach ($ownedTables as $key => $table) {
            if (isset($s[$key])) {
                assertOwnedIds($pdo, $uid, $table, arr($s[$key]));
            }
        }
        $deletionTables = [
            'transactions' => 'transactions',
            'budgets' => 'budgets',
            'overallBudgets' => 'overall_budgets',
            'notes' => 'notes',
            'reminders' => 'reminders',
        ];
        $deletions = arr($s['deletions'] ?? null);
        foreach ($deletionTables as $key => $table) {
            $ids = array_values(array_filter(
                arr($deletions[$key] ?? null),
                static fn($id) => $id !== null && (string)$id !== ''
            ));
            $rows = array_map(static fn($id) => ['id' => (string)$id], $ids);
            assertOwnedIds($pdo, $uid, $table, $rows);
        }

        // 1. Accounts - Upsert (Insert or Update)
        if (isset($s['accounts'])) {
            $q = $pdo->prepare('INSERT INTO accounts(id,user_id,name) VALUES(?,?,?)
                                ON DUPLICATE KEY UPDATE name=VALUES(name)');
            foreach(arr($s['accounts']) as $r) {
                $accId = strOrNull($r['id'] ?? null) ?? 'default';
                $accName = strOrNull($r['name'] ?? null) ?? 'Income Expense';
                $q->execute([$accId, $uid, $accName]);
            }
        }

        // 2. Categories - Upsert
        if (isset($s['categories'])) {
            $q = $pdo->prepare('INSERT INTO categories(id,user_id,name,icon_code_point,icon_font_family,color_value,icon_asset,kind,is_custom,parent_id)
                                VALUES(?,?,?,?,?,?,?,?,?,?)
                                ON DUPLICATE KEY UPDATE name=VALUES(name), icon_code_point=VALUES(icon_code_point), icon_font_family=VALUES(icon_font_family), color_value=VALUES(color_value), icon_asset=VALUES(icon_asset), kind=VALUES(kind), is_custom=VALUES(is_custom), parent_id=VALUES(parent_id)');
            foreach(arr($s['categories']) as $r) {
                if (empty($r['id']) || empty($r['name'])) continue;
                $q->execute([
                    (string)$r['id'], $uid, (string)$r['name'],
                    (int)($r['iconCodePoint']??0), (string)($r['iconFontFamily']??'MaterialIcons'),
                    (int)($r['colorValue']??0), strOrNull($r['iconAsset']??null),
                    (int)($r['kind']??2), !empty($r['isCustom'])?1:0, strOrNull($r['parentId']??null)
                ]);
            }
        }

        // 3. Payment Methods - Upsert
        if (isset($s['paymentMethods'])) {
            $q = $pdo->prepare('INSERT INTO payment_methods(id,user_id,name,is_custom) VALUES(?,?,?,?)
                                ON DUPLICATE KEY UPDATE name=VALUES(name), is_custom=VALUES(is_custom)');
            foreach(arr($s['paymentMethods']) as $r) {
                if (empty($r['id']) || empty($r['name'])) continue;
                $q->execute([(string)$r['id'], $uid, (string)$r['name'], !empty($r['isCustom'])?1:0]);
            }
        }

        // 4. Transactions - Upsert
        if (isset($s['transactions'])) {
            $q = $pdo->prepare('INSERT INTO transactions(id,user_id,account_id,type,amount,category_id,payment_method_id,to_payment_method_id,notes,transaction_date,is_deleted)
                                VALUES(?,?,?,?,?,?,?,?,?,?,?)
                                ON DUPLICATE KEY UPDATE account_id=VALUES(account_id), type=VALUES(type), amount=VALUES(amount), category_id=VALUES(category_id), payment_method_id=VALUES(payment_method_id), to_payment_method_id=VALUES(to_payment_method_id), notes=VALUES(notes), transaction_date=VALUES(transaction_date), is_deleted=VALUES(is_deleted)');
            $qi = $pdo->prepare('DELETE FROM transaction_items WHERE transaction_id=?');
            $qi_ins = $pdo->prepare('INSERT INTO transaction_items(transaction_id,item_name,quantity,unit,rate) VALUES(?,?,?,?,?)');
            $qb = $pdo->prepare('DELETE FROM transaction_bills WHERE transaction_id=?');
            $qb_ins = $pdo->prepare('INSERT INTO transaction_bills(transaction_id,bill_path) VALUES(?,?)');

            foreach(arr($s['transactions']) as $r) {
                if (empty($r['id'])) continue;
                $q->execute([
                    (string)$r['id'], $uid, strOrNull($r['accountId']??null) ?? 'default',
                    (int)($r['type']??1), (float)($r['amount']??0),
                    strOrNull($r['categoryId']??null), strOrNull($r['paymentMethodId']??null),
                    strOrNull($r['toPaymentMethodId']??null), (string)($r['notes']??''),
                    dt($r['date']??null), !empty($r['isDeleted'])?1:0
                ]);
                $qi->execute([(string)$r['id']]);
                foreach(arr($r['items']??null) as $i) {
                    if (!empty($i['name'])) {
                        $qi_ins->execute([
                            (string)$r['id'],
                            (string)$i['name'],
                            (float)($i['quantity']??1),
                            (string)($i['unit']??''),
                            (float)($i['rate']??0)
                        ]);
                    }
                }
                $qb->execute([(string)$r['id']]);
                $refs = [];
                foreach(arr($r['billPaths']??null) as $b) {
                    if ($b !== null && $b !== '') $refs[] = (string)$b;
                }
                // Receipt references must point at this user's own uploads.
                $wanted = [];
                foreach ($refs as $ref) { $rid = receiptIdFromRef($ref); if ($rid !== null) $wanted[$rid] = true; }
                $existing = [];
                if ($wanted) {
                    $ids = array_keys($wanted);
                    $marks = implode(',', array_fill(0, count($ids), '?'));
                    $qr = $pdo->prepare("SELECT id,user_id FROM receipts WHERE id IN ({$marks})");
                    $qr->execute($ids);
                    foreach ($qr->fetchAll() as $row) {
                        if ($row['user_id'] !== $uid) throw new OwnershipException('A receipt belongs to a different account.');
                        $existing[$row['id']] = true;
                    }
                }
                $keep = [];
                foreach ($refs as $ref) {
                    $rid = receiptIdFromRef($ref);
                    if ($rid !== null && !isset($existing[$rid])) continue; // receipt no longer exists: drop dangling reference
                    $qb_ins->execute([(string)$r['id'], $ref]);
                    if ($rid !== null) $keep[] = $rid;
                }
                try {
                    // Link kept receipts to this transaction; delete receipts the user removed from it.
                    foreach ($keep as $rid) {
                        $pdo->prepare('UPDATE receipts SET transaction_id=? WHERE id=? AND user_id=?')->execute([(string)$r['id'], $rid, $uid]);
                    }
                    if ($keep) {
                        $marks = implode(',', array_fill(0, count($keep), '?'));
                        $pdo->prepare("DELETE FROM receipts WHERE user_id=? AND transaction_id=? AND id NOT IN ({$marks})")->execute([$uid, (string)$r['id'], ...$keep]);
                    } else {
                        $pdo->prepare('DELETE FROM receipts WHERE user_id=? AND transaction_id=?')->execute([$uid, (string)$r['id']]);
                    }
                } catch (Throwable $e) {
                    // Ignore if receipts table is not present in legacy schema
                }
            }
        }

        // 5. Budgets - Upsert
        if (isset($s['budgets'])) {
            $q = $pdo->prepare('INSERT INTO budgets(id,user_id,account_id,category_id,amount,period,period_start)
                                VALUES(?,?,?,?,?,?,?)
                                ON DUPLICATE KEY UPDATE account_id=VALUES(account_id), category_id=VALUES(category_id), amount=VALUES(amount), period=VALUES(period), period_start=VALUES(period_start)');
            foreach(arr($s['budgets']) as $r) {
                if (empty($r['id'])) continue;
                $q->execute([
                    (string)$r['id'], $uid, strOrNull($r['accountId']??null) ?? 'default',
                    strOrNull($r['categoryId']??null), (float)($r['amount']??0),
                    (int)($r['period']??0), dt($r['periodStart']??null)
                ]);
            }
        }

        // 6. Overall Budgets - Upsert
        if (isset($s['overallBudgets'])) {
            $q = $pdo->prepare('INSERT INTO overall_budgets(id,user_id,account_id,amount,period,period_start)
                                VALUES(?,?,?,?,?,?)
                                ON DUPLICATE KEY UPDATE account_id=VALUES(account_id), amount=VALUES(amount), period=VALUES(period), period_start=VALUES(period_start)');
            foreach(arr($s['overallBudgets']) as $r) {
                if (empty($r['id'])) continue;
                $q->execute([
                    (string)$r['id'], $uid, strOrNull($r['accountId']??null) ?? 'default',
                    (float)($r['amount']??0), (int)($r['period']??0),
                    dt($r['periodStart']??null)
                ]);
            }
        }

        // 7. Notes - Upsert
        if (isset($s['notes'])) {
            $q = $pdo->prepare('INSERT INTO notes(id,user_id,account_id,note_text,date_time,completed)
                                VALUES(?,?,?,?,?,?)
                                ON DUPLICATE KEY UPDATE account_id=VALUES(account_id), note_text=VALUES(note_text), date_time=VALUES(date_time), completed=VALUES(completed)');
            foreach(arr($s['notes']) as $r) {
                if (empty($r['id'])) continue;
                $q->execute([
                    (string)$r['id'], $uid, strOrNull($r['accountId']??null) ?? 'default',
                    (string)($r['text']??''), dt($r['dateTime']??null),
                    !empty($r['completed'])?1:0
                ]);
            }
        }

        // 8. Reminders - Upsert
        if (isset($s['reminders'])) {
            $q = $pdo->prepare('INSERT INTO reminders(id,user_id,account_id,category_id,payment_method_id,amount,type,recurrence,next_date,notes)
                                VALUES(?,?,?,?,?,?,?,?,?,?)
                                ON DUPLICATE KEY UPDATE account_id=VALUES(account_id), category_id=VALUES(category_id), payment_method_id=VALUES(payment_method_id), amount=VALUES(amount), type=VALUES(type), recurrence=VALUES(recurrence), next_date=VALUES(next_date), notes=VALUES(notes)');
            foreach(arr($s['reminders']) as $r) {
                if (empty($r['id'])) continue;
                $q->execute([
                    (string)$r['id'], $uid, strOrNull($r['accountId']??null) ?? 'default',
                    strOrNull($r['categoryId']??null), strOrNull($r['paymentMethodId']??null),
                    (float)($r['amount']??0), (int)($r['type']??1),
                    (int)($r['recurrence']??0), dt($r['nextDate']??null),
                    (string)($r['notes']??'')
                ]);
            }
        }

        // 9. User Settings - Upsert
        if (isset($s['settings'])) {
            $q = $pdo->prepare('INSERT INTO user_settings(user_id,setting_key,setting_value)
                                VALUES(?,?,?)
                                ON DUPLICATE KEY UPDATE setting_value=VALUES(setting_value)');
            foreach(arr($s['settings']) as $k=>$v) {
                if ($k !== null && $k !== '') {
                    $q->execute([$uid, (string)$k, (string)($v ?? '')]);
                }
            }
        }

        // Apply only explicit user deletions. Treating every omitted record as
        // deleted would let an older phone/browser snapshot erase newer data
        // saved by a second signed-in device.
        $deleteOrder = [
            'reminders' => 'reminders',
            'notes' => 'notes',
            'overallBudgets' => 'overall_budgets',
            'budgets' => 'budgets',
            'transactions' => 'transactions',
        ];
        foreach ($deleteOrder as $key => $table) {
            if (isset($deletions[$key])) {
                if ($key === 'transactions') {
                    // Receipt files have no FK to transactions, so remove them explicitly.
                    $tids = array_values(array_unique(array_map('strval', array_filter(arr($deletions[$key]), static fn($i) => $i !== null && (string)$i !== ''))));
                    if ($tids) {
                        $marks = implode(',', array_fill(0, count($tids), '?'));
                        $pdo->prepare("DELETE FROM receipts WHERE user_id=? AND transaction_id IN ({$marks})")->execute([$uid, ...$tids]);
                    }
                }
                deleteOwnedIds($pdo, $uid, $table, arr($deletions[$key]));
            }
        }

        $pdo->commit();
    } catch(Throwable $e) {
        if($pdo->inTransaction()) $pdo->rollBack();
        throw $e;
    }
}

function notificationPrefs(PDO $pdo, string $uid): array {
    $q=$pdo->prepare('SELECT phone_number,email_enabled,sms_enabled,daily_reminder_enabled,balance_alert_enabled,low_balance_threshold FROM notification_preferences WHERE user_id=?');
    $q->execute([$uid]); $r=$q->fetch();
    if(!$r) return ['phoneNumber'=>'','emailEnabled'=>true,'smsEnabled'=>false,'dailyReminderEnabled'=>true,'balanceAlertEnabled'=>true,'lowBalanceThreshold'=>0.0];
    return ['phoneNumber'=>$r['phone_number']??'','emailEnabled'=>(bool)$r['email_enabled'],'smsEnabled'=>(bool)$r['sms_enabled'],'dailyReminderEnabled'=>(bool)$r['daily_reminder_enabled'],'balanceAlertEnabled'=>(bool)$r['balance_alert_enabled'],'lowBalanceThreshold'=>(float)$r['low_balance_threshold']];
}
function accountSummary(PDO $pdo, string $uid): array {
    $q=$pdo->prepare("SELECT COALESCE(SUM(CASE WHEN type=0 AND is_deleted=0 THEN amount ELSE 0 END),0) income, COALESCE(SUM(CASE WHEN type=1 AND is_deleted=0 THEN amount ELSE 0 END),0) expense, COUNT(CASE WHEN is_deleted=0 THEN 1 END) transactions FROM transactions WHERE user_id=?");
    $q->execute([$uid]); $r=$q->fetch() ?: ['income'=>0,'expense'=>0,'transactions'=>0];
    $r['income']=(float)$r['income']; $r['expense']=(float)$r['expense']; $r['balance']=$r['income']-$r['expense']; $r['transactions']=(int)$r['transactions']; return $r;
}
function insertInApp(PDO $pdo, string $uid, string $type, string $title, string $message): void {
    $q=$pdo->prepare("INSERT IGNORE INTO notifications(user_id,notification_type,title,message,channel,delivery_status,notification_date) VALUES(?,?,?,?, 'in_app','sent',CURDATE())");
    $q->execute([$uid,$type,$title,$message]);
}

try {
    $pdo=db($config); $in=input(); $action=$_GET['action']??($in['action']??'');
    if($action==='ping' || $action==='health' || ($action==='' && $_SERVER['REQUEST_METHOD']==='GET')){
        $pdo->query('SELECT 1');
        respond(true,'Student Expense Manager API is running and connected to database.',['database'=>'connected','database_name'=>$config['db_name']??'','server_time'=>date('c')]);
    }
    if($action==='register'){
        $name=trim((string)($in['name']??''));$email=strtolower(trim((string)($in['email']??'')));$password=(string)($in['password']??'');
        if($name===''||!filter_var($email,FILTER_VALIDATE_EMAIL)||strlen($password)<6)respond(false,'Enter a valid name, email and password of at least 6 characters.',null,422);
        $q=$pdo->prepare('SELECT id FROM users WHERE email=?');$q->execute([$email]);if($q->fetch())respond(false,'An account with this email already exists.',null,409);
        $uid=uuid();$q=$pdo->prepare('INSERT INTO users(id,full_name,email,password_hash) VALUES(?,?,?,?)');$q->execute([$uid,$name,$email,password_hash($password,PASSWORD_DEFAULT)]);
        $accountId=uuid();$pdo->prepare('INSERT INTO accounts(id,user_id,name) VALUES(?,?,?)')->execute([$accountId,$uid,'Income Expense']);
        // Registration creates a database account only. Login is a separate step.
        respond(true,'Account created. Please log in.',['user'=>['id'=>$uid,'name'=>$name,'email'=>$email]]);
    }
    if($action==='login'){
        $email=strtolower(trim((string)($in['email']??'')));$password=(string)($in['password']??'');
        $q=$pdo->prepare('SELECT id,full_name,email,password_hash FROM users WHERE email=?');$q->execute([$email]);$u=$q->fetch();
        if(!$u||!password_verify($password,$u['password_hash']))respond(false,'Incorrect email or password.',null,401);
        $token=issueToken($pdo,$u['id'],(int)$config['session_days']);
        respond(true,'Login successful.',['token'=>$token,'user'=>['id'=>$u['id'],'name'=>$u['full_name'],'email'=>$u['email']],'state'=>state($pdo,$u['id'])]);
    }
    if($action==='request_password_reset_code'){
        $email=strtolower(trim((string)($in['email']??'')));
        if(!filter_var($email,FILTER_VALIDATE_EMAIL)) respond(false,'Enter a valid email address.',null,422);
        $q=$pdo->prepare('SELECT id,email FROM users WHERE email=?');$q->execute([$email]);$u=$q->fetch();
        if($u){
            $q=$pdo->prepare('SELECT id FROM password_reset_tokens WHERE user_id=? AND created_at>DATE_SUB(NOW(),INTERVAL 1 MINUTE) LIMIT 1');
            $q->execute([$u['id']]);
            if(!$q->fetchColumn()){
                $pdo->prepare('DELETE FROM password_reset_tokens WHERE user_id=?')->execute([$u['id']]);
                $code=str_pad((string)random_int(0,999999),6,'0',STR_PAD_LEFT);
                $q=$pdo->prepare('INSERT INTO password_reset_tokens(user_id,token_hash,expires_at) VALUES(?,?,DATE_ADD(NOW(),INTERVAL 15 MINUTE))');
                $q->execute([$u['id'],hash('sha256',$code)]);
                $subject='Student Expense Manager password reset code';
                $body="Your password reset code is {$code}. It expires in 15 minutes. If you did not request this, ignore this message.";
                $headers='From: '.(string)($config['email_from']??'');
                if(empty($config['email_from']) || !@mail($u['email'],$subject,$body,$headers)){
                    $pdo->prepare('DELETE FROM password_reset_tokens WHERE user_id=?')->execute([$u['id']]);
                    error_log('Password recovery email delivery failed.');
                }
            }
        }
        respond(true,'If the address belongs to an account and email is configured, a reset code will arrive shortly.');
    }
    if($action==='reset_password'){
        $email=strtolower(trim((string)($in['email']??'')));
        $code=trim((string)($in['code']??''));
        $password=(string)($in['password']??'');
        if(strlen($password)<6)respond(false,'Password must be at least 6 characters.',null,422);
        if(!preg_match('/^[0-9]{6}$/',$code))respond(false,'Enter the six-digit reset code.',null,422);
        $pdo->beginTransaction();
        $q=$pdo->prepare('SELECT u.id,pr.id AS reset_id,pr.token_hash,pr.attempts FROM users u JOIN password_reset_tokens pr ON pr.user_id=u.id WHERE u.email=? AND pr.expires_at>NOW() ORDER BY pr.created_at DESC LIMIT 1 FOR UPDATE');
        $q->execute([$email]);$reset=$q->fetch();
        if(!$reset){
            $pdo->rollBack();
            respond(false,'The reset code is invalid or expired. Request a new code.',null,422);
        }
        if((int)$reset['attempts']>=5 || !hash_equals($reset['token_hash'],hash('sha256',$code))){
            $pdo->prepare('UPDATE password_reset_tokens SET attempts=attempts+1 WHERE id=?')->execute([$reset['reset_id']]);
            $pdo->commit();
            respond(false,'The reset code is invalid or expired. Request a new code.',null,422);
        }
        $pdo->prepare('UPDATE users SET password_hash=? WHERE id=?')->execute([password_hash($password,PASSWORD_DEFAULT),$reset['id']]);
        $pdo->prepare('DELETE FROM sessions WHERE user_id=?')->execute([$reset['id']]);
        $pdo->prepare('DELETE FROM password_reset_tokens WHERE user_id=?')->execute([$reset['id']]);
        $pdo->commit();
        respond(true,'Password updated. You can now log in.');
    }
    if($action==='logout'){
        $t=bearerToken();if($t!==''){$pdo->prepare('DELETE FROM sessions WHERE token_hash=?')->execute([hash('sha256',$t)]);}
        respond(true,'Logged out.');
    }
    $u=auth($pdo); $uid=$u['user_id'];
    if($action==='upload_receipt'){
        $name=receiptName((string)($in['fileName']??'receipt'));
        $raw=(string)($in['data']??'');
        $bytes=$raw===''?false:base64_decode($raw,true);
        if($bytes===false||$bytes==='') respond(false,'The receipt file could not be read. Please choose it again.',null,422);
        $max=(int)($config['max_receipt_bytes']??4194304);
        if(strlen($bytes)>$max) respond(false,'This receipt is too large. The limit is '.round($max/1048576,1).' MB.',null,413);
        $mime=detectReceiptMime($bytes);
        if($mime===null) respond(false,'Only JPG, PNG, WEBP images and PDF files can be uploaded as receipts.',null,415);
        // Remove uploads that were never attached to a saved transaction.
        $pdo->prepare('DELETE FROM receipts WHERE user_id=? AND transaction_id IS NULL AND created_at<DATE_SUB(NOW(),INTERVAL 1 DAY)')->execute([$uid]);
        $quota=(int)($config['user_receipt_quota_bytes']??209715200);
        $q=$pdo->prepare('SELECT COALESCE(SUM(file_size),0) FROM receipts WHERE user_id=?');$q->execute([$uid]);
        if((int)$q->fetchColumn()+strlen($bytes)>$quota) respond(false,'Your receipt storage is full. Delete some old receipts and try again.',null,413);
        $rid=uuid();
        $q=$pdo->prepare('INSERT INTO receipts(id,user_id,file_name,mime_type,file_size,file_data) VALUES(?,?,?,?,?,?)');
        $q->bindValue(1,$rid);$q->bindValue(2,$uid);$q->bindValue(3,$name);$q->bindValue(4,$mime);
        $q->bindValue(5,strlen($bytes),PDO::PARAM_INT);$q->bindValue(6,$bytes,PDO::PARAM_LOB);
        $q->execute();
        respond(true,'Receipt uploaded successfully.',['id'=>$rid,'fileName'=>$name,'mimeType'=>$mime,'size'=>strlen($bytes)]);
    }
    if($action==='get_receipt'){
        $rid=(string)($_GET['id']??($in['id']??''));
        if(!preg_match('/^[0-9a-f-]{36}$/',$rid)) respond(false,'Invalid receipt.',null,422);
        $q=$pdo->prepare('SELECT file_name,mime_type,file_size,file_data FROM receipts WHERE id=? AND user_id=? LIMIT 1');
        $q->execute([$rid,$uid]);$f=$q->fetch();
        if(!$f) respond(false,'Receipt not found.',null,404);
        $data=is_resource($f['file_data'])?stream_get_contents($f['file_data']):(string)$f['file_data'];
        header_remove('Content-Type');
        header('Content-Type: '.$f['mime_type']);
        header('Content-Length: '.strlen($data));
        header("Content-Disposition: inline; filename*=UTF-8''".rawurlencode($f['file_name']));
        header('X-Content-Type-Options: nosniff');
        header('Cache-Control: private, max-age=3600');
        echo $data; exit;
    }
    if($action==='delete_receipt'){
        $rid=(string)($in['id']??'');
        if(!preg_match('/^[0-9a-f-]{36}$/',$rid)) respond(false,'Invalid receipt.',null,422);
        $pdo->beginTransaction();
        $pdo->prepare('DELETE tb FROM transaction_bills tb JOIN transactions t ON t.id=tb.transaction_id WHERE t.user_id=? AND tb.bill_path=?')->execute([$uid,RECEIPT_PREFIX.$rid]);
        $pdo->prepare('DELETE FROM receipts WHERE id=? AND user_id=?')->execute([$rid,$uid]);
        $pdo->commit();
        respond(true,'Receipt deleted.');
    }
    if($action==='state'){respond(true,'',state($pdo,$uid));}
    if($action==='sync'){syncData($pdo,$uid,arr($in['state']??[]));respond(true,'Synchronized successfully.',state($pdo,$uid));}
    if($action==='notification_preferences') {
        if($_SERVER['REQUEST_METHOD']==='GET' || !isset($in['preferences'])) respond(true,'Notification preferences loaded.',notificationPrefs($pdo,$uid));
        $p=arr($in['preferences']); $phone=trim((string)($p['phoneNumber']??''));
        $smsEnabled=!empty($p['smsEnabled']);
        if($smsEnabled && $phone==='') respond(false,'Add a phone number before enabling SMS alerts.',null,422);
        if($phone!=='' && !preg_match('/^\+[1-9][0-9]{7,14}$/',$phone)) respond(false,'Enter the phone number in international format, for example +2567XXXXXXXX.',null,422);
        $q=$pdo->prepare('INSERT INTO notification_preferences(user_id,phone_number,email_enabled,sms_enabled,daily_reminder_enabled,balance_alert_enabled,low_balance_threshold) VALUES(?,?,?,?,?,?,?) ON DUPLICATE KEY UPDATE phone_number=VALUES(phone_number),email_enabled=VALUES(email_enabled),sms_enabled=VALUES(sms_enabled),daily_reminder_enabled=VALUES(daily_reminder_enabled),balance_alert_enabled=VALUES(balance_alert_enabled),low_balance_threshold=VALUES(low_balance_threshold)');
        $q->execute([$uid,$phone!==''?$phone:null,!empty($p['emailEnabled'])?1:0,$smsEnabled?1:0,!empty($p['dailyReminderEnabled'])?1:0,!empty($p['balanceAlertEnabled'])?1:0,max(0,(float)($p['lowBalanceThreshold']??0))]);
        respond(true,'Notification preferences saved.',notificationPrefs($pdo,$uid));
    }
    if($action==='notifications') {
        $q=$pdo->prepare('SELECT id,notification_type AS type,title,message,channel,delivery_status AS deliveryStatus,is_read AS isRead,created_at AS createdAt FROM notifications WHERE user_id=? ORDER BY created_at DESC LIMIT 100'); $q->execute([$uid]);
        $rows=$q->fetchAll(); foreach($rows as &$r){$r['isRead']=(bool)$r['isRead'];}
        respond(true,'Notifications loaded.',['notifications'=>$rows,'unreadCount'=>count(array_filter($rows,fn($r)=>!$r['isRead'])),'summary'=>accountSummary($pdo,$uid),'preferences'=>notificationPrefs($pdo,$uid)]);
    }
    if($action==='mark_notifications_read') { $pdo->prepare('UPDATE notifications SET is_read=1 WHERE user_id=?')->execute([$uid]); respond(true,'Notifications marked as read.'); }
    if($action==='summary') respond(true,'Account summary loaded.',accountSummary($pdo,$uid));
    respond(false,'Unknown action.',null,404);
} catch(Throwable $e) {
    error_log((string)$e);
    if ($e instanceof PDOException && (stripos($e->getMessage(), 'max_allowed_packet') !== false || stripos($e->getMessage(), 'server has gone away') !== false)) {
        respond(false, 'The database rejected this file because it is larger than MySQL max_allowed_packet. Ask the administrator to set max_allowed_packet=16M, or upload a smaller receipt.', null, 413);
    }
    if ($e instanceof OwnershipException) {
        respond(false, 'One or more submitted records do not belong to this account.', null, 409);
    }
    respond(false, 'Server error: ' . $e->getMessage(), null, 500);
}
