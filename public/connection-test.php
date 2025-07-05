<?php
// Hiển thị tất cả lỗi
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

echo "<h1>Kiểm tra kết nối Laravel - MySQL</h1>";

// Kiểm tra môi trường
echo "<h2>Thông tin môi trường:</h2>";
echo "<ul>";
echo "<li>PHP version: " . phpversion() . "</li>";
echo "<li>Server: " . $_SERVER['SERVER_SOFTWARE'] . "</li>";
echo "<li>Document Root: " . $_SERVER['DOCUMENT_ROOT'] . "</li>";
echo "<li>Current directory: " . getcwd() . "</li>";
echo "</ul>";

// Kiểm tra cấu trúc thư mục Laravel
echo "<h2>Kiểm tra thư mục Laravel:</h2>";
echo "<ul>";
$dirs = ['app', 'bootstrap', 'config', 'database', 'resources', 'routes', 'storage', 'vendor'];
foreach ($dirs as $dir) {
    $path = dirname($_SERVER['DOCUMENT_ROOT']) . '/' . $dir;
    echo "<li>$dir: " . (file_exists($path) ? "<span style='color:green'>Tồn tại</span>" : "<span style='color:red'>Không tồn tại</span>") . "</li>";
}
echo "</ul>";

// Thử kết nối MySQL
try {
    $db_host = getenv('DB_HOST') ?: 'trolley.proxy.rlwy.net';
    $db_port = getenv('DB_PORT') ?: '54154';
    $db_name = getenv('DB_DATABASE') ?: 'railway';
    $db_user = getenv('DB_USERNAME') ?: 'root';
    $db_pass = getenv('DB_PASSWORD') ?: 'ARakarqbSOaCUkoUTXyGSYVMfEYVPuVY';

    echo "<h2>Thông tin kết nối MySQL:</h2>";
    echo "<ul>";
    echo "<li>Host: $db_host</li>";
    echo "<li>Port: $db_port</li>";
    echo "<li>Database: $db_name</li>";
    echo "<li>Username: $db_user</li>";
    echo "</ul>";

    $pdo = new PDO("mysql:host=$db_host;port=$db_port;dbname=$db_name", $db_user, $db_pass);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    echo "<p style='color:green'>✅ Kết nối MySQL thành công!</p>";

    // Thử truy vấn
    $stmt = $pdo->query("SHOW TABLES");
    $tables = $stmt->fetchAll(PDO::FETCH_COLUMN);

    echo "<h2>Danh sách bảng:</h2>";
    echo "<ul>";
    if (count($tables) > 0) {
        foreach ($tables as $table) {
            echo "<li>$table</li>";
        }
    } else {
        echo "<li>Không có bảng nào.</li>";
    }
    echo "</ul>";

} catch (PDOException $e) {
    echo "<p style='color:red'>❌ Lỗi kết nối MySQL: " . htmlspecialchars($e->getMessage()) . "</p>";
}
