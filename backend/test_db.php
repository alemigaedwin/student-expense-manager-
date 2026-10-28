<?php
// Database & Environment Diagnostic Tool for Student Expense Manager
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');

$config = file_exists(__DIR__ . '/config.php') ? require __DIR__ . '/config.php' : [];

$report = [
    'status' => 'checking',
    'php_version' => PHP_VERSION,
    'config_exists' => file_exists(__DIR__ . '/config.php'),
    'sql_file_exists' => file_exists(__DIR__ . '/student_expense_manager.sql'),
    'db_connection' => 'failed',
    'db_name' => $config['db_name'] ?? 'student_expense_manager',
    'tables_found' => [],
    'error' => null,
];

try {
    require_once __DIR__ . '/api.php';
    // api.php already calls db($config), which ensures database and tables are created.
    $pdo = db($config);
    $report['db_connection'] = 'successful';
    $report['status'] = 'ready';

    $stmt = $pdo->query("SHOW TABLES");
    $tables = [];
    while ($row = $stmt->fetch(PDO::FETCH_NUM)) {
        $tables[] = $row[0];
    }
    $report['tables_found'] = $tables;
    $report['tables_count'] = count($tables);

} catch (Throwable $e) {
    $report['status'] = 'error';
    $report['error'] = $e->getMessage();
}

echo json_encode($report, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES);
