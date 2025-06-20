<?php
// Hiển thị tất cả lỗi
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

echo "<h1>Kiểm tra cài đặt Laravel</h1>";

try {
    echo "<h2>Thông tin cơ bản:</h2>";
    echo "<ul>";
    echo "<li>PHP version: " . phpversion() . "</li>";
    echo "<li>Current directory: " . getcwd() . "</li>";
    echo "<li>Directory parent: " . dirname(getcwd()) . "</li>";
    echo "<li>Document root: " . $_SERVER['DOCUMENT_ROOT'] . "</li>";
    echo "<li>Server software: " . $_SERVER['SERVER_SOFTWARE'] . "</li>";
    echo "</ul>";

    echo "<h2>Kiểm tra tệp tin Laravel:</h2>";
    echo "<ul>";
    
    // Kiểm tra file cơ bản
    $files_to_check = [
        "../vendor/autoload.php",
        "../bootstrap/app.php",
        "index.php",
        ".htaccess"
    ];
    
    foreach ($files_to_check as $file) {
        echo "<li>" . $file . ": " . (file_exists($file) ? "<span style='color:green'>Tồn tại</span>" : "<span style='color:red'>Không tồn tại</span>") . "</li>";
    }
    echo "</ul>";
    
    // Thử tải autoloader
    echo "<h2>Thử tải Composer autoloader:</h2>";
    if (file_exists("../vendor/autoload.php")) {
        require "../vendor/autoload.php";
        echo "<p style='color:green'>✅ Đã tải autoloader thành công.</p>";
        
        // Kiểm tra Laravel version
        if (class_exists('Illuminate\Foundation\Application')) {
            echo "<p>Laravel version: " . \Illuminate\Foundation\Application::VERSION . "</p>";
        } else {
            echo "<p style='color:orange'>⚠️ Không thể xác định phiên bản Laravel.</p>";
        }
    } else {
        echo "<p style='color:red'>❌ Không thể tải autoloader.</p>";
    }
    
    // Kiểm tra quyền truy cập thư mục
    echo "<h2>Kiểm tra quyền thư mục:</h2>";
    $directories = [
        "../storage" => 0755,
        "../storage/logs" => 0755,
        "../storage/framework" => 0755,
        "../bootstrap/cache" => 0755
    ];
    
    foreach ($directories as $dir => $required_permission) {
        if (!file_exists($dir)) {
            echo "<li>$dir: <span style='color:red'>Không tồn tại</span></li>";
            continue;
        }
        
        $perms = substr(sprintf('%o', fileperms($dir)), -4);
        echo "<li>$dir: Quyền hiện tại = $perms";
        
        if (is_writable($dir)) {
            echo " - <span style='color:green'>Có thể ghi</span></li>";
        } else {
            echo " - <span style='color:red'>Không thể ghi</span></li>";
        }
    }
    
    echo "</ul>";
    
} catch (Exception $e) {
    echo "<h2 style='color:red'>Lỗi: " . $e->getMessage() . "</h2>";
}
?>