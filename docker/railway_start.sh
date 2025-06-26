#!/bin/bash

echo "🚂 Khởi động ứng dụng trên Railway với Nginx..."

# Kiểm tra biến môi trường Railway
echo "Kiểm tra biến môi trường Railway..."
env | grep -E "RAILWAY_|MYSQL|DB_|PORT|CORS_" || echo "Không tìm thấy biến môi trường cần thiết"

# Vô hiệu hóa Apache nếu có
if [ -f "/etc/apache2/sites-available/000-default.conf" ]; then
  echo "Vô hiệu hóa Apache..."
  mv /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/000-default.conf.bak
  echo "✅ Apache đã được vô hiệu hóa"
fi

# Thiết lập CORS đơn giản và an toàn nhất
CORS_ORIGIN="*"
CORS_METHODS="GET, POST, PUT, DELETE, OPTIONS"
CORS_HEADERS="Content-Type, Authorization, X-Requested-With, Accept"

echo "CORS Origin: $CORS_ORIGIN"
echo "CORS Methods: $CORS_METHODS"
echo "CORS Headers: $CORS_HEADERS"

# Kiểm tra xem chúng ta đang ở trong thư mục gốc của Laravel hay không
if [ -f "artisan" ]; then
  LARAVEL_ROOT=$(pwd)
  echo "✅ Đã phát hiện thư mục gốc Laravel tại: $LARAVEL_ROOT"
else
  echo "❌ ERROR: Không tìm thấy file 'artisan' trong thư mục hiện tại!"
  echo "Thư mục hiện tại: $(pwd)"
  echo "Nội dung thư mục:"
  ls -la
  
  # Tìm kiếm file artisan trong các thư mục con
  ARTISAN_PATH=$(find . -name "artisan" -type f | head -n 1)
  if [ ! -z "$ARTISAN_PATH" ]; then
    LARAVEL_ROOT=$(dirname "$ARTISAN_PATH")
    echo "Tìm thấy file artisan tại: $ARTISAN_PATH"
    echo "Chuyển đến thư mục: $LARAVEL_ROOT"
    cd "$LARAVEL_ROOT"
  fi
fi

# Tạo file .env từ các biến môi trường với các giá trị cụ thể cung cấp
cat > .env << EOF
APP_NAME=FitnessApp
APP_ENV=${APP_ENV:-production}
APP_KEY=${APP_KEY:-}
APP_DEBUG=true
APP_URL=${RAILWAY_PUBLIC_DOMAIN:-${APP_URL:-http://localhost}}

LOG_CHANNEL=stderr
LOG_LEVEL=debug

# Kết nối cơ sở dữ liệu MySQL
DB_CONNECTION=mysql
DB_HOST=${DB_HOST:-trolley.proxy.rlwy.net}
DB_PORT=${DB_PORT:-54154}
DB_DATABASE=${DB_DATABASE:-railway}
DB_USERNAME=${DB_USERNAME:-root}
DB_PASSWORD=${DB_PASSWORD:-ARakarqbSOaCUkoUTXyGSYVMfEYVPuVY}

BROADCAST_DRIVER=${BROADCAST_DRIVER:-log}
CACHE_DRIVER=${CACHE_DRIVER:-file}
FILESYSTEM_DISK=${FILESYSTEM_DISK:-local}
QUEUE_CONNECTION=${QUEUE_CONNECTION:-sync}
SESSION_DRIVER=${SESSION_DRIVER:-cookie}
SESSION_LIFETIME=${SESSION_LIFETIME:-120}

# Cấu hình CORS
SANCTUM_STATEFUL_DOMAINS=${SANCTUM_STATEFUL_DOMAINS:-localhost:3000,127.0.0.1:3000,*.railway.app}
SESSION_DOMAIN=${SESSION_DOMAIN:-.railway.app}
SESSION_SECURE_COOKIE=${SESSION_SECURE_COOKIE:-true}
CORS_ALLOWED_ORIGINS=*
EOF

# Tạo application key nếu chưa có
if [ -z "$APP_KEY" ]; then
  echo "Tạo APP_KEY mới..."
  php artisan key:generate --force
fi

# Xác định PORT
PORT="${PORT:-8080}"
echo "Port được cấu hình: $PORT"

# Đảm bảo các thư mục framework tồn tại và có quyền ghi
echo "Đảm bảo các thư mục framework tồn tại..."
mkdir -p storage/framework/{sessions,views,cache}
mkdir -p bootstrap/cache

# Đặt quyền cho các thư mục quan trọng
echo "Thiết lập quyền truy cập thư mục..."
chmod -R 775 storage bootstrap/cache
chown -R www-data:www-data storage bootstrap/cache

# Kiểm tra và đảm bảo thư mục public tồn tại
if [ ! -d "public" ]; then
  echo "⚠️ Thư mục public không tồn tại, tạo mới thư mục public..."
  mkdir -p public
fi

# Kiểm tra file index.php tồn tại trong thư mục public
if [ ! -f "public/index.php" ]; then
  echo "⚠️ File public/index.php không tồn tại!"
  
  # Tạo file index.php chuẩn cho Laravel trong thư mục public
  cat > public/index.php << 'EOF_INDEX'
<?php

use Illuminate\Foundation\Application;
use Illuminate\Http\Request;

define('LARAVEL_START', microtime(true));

// Determine if the application is in maintenance mode...
if (file_exists($maintenance = __DIR__.'/../storage/framework/maintenance.php')) {
    require $maintenance;
}

// Register the Composer autoloader...
require __DIR__.'/../vendor/autoload.php';

// Bootstrap Laravel and handle the request...
/** @var Application $app */
$app = require_once __DIR__.'/../bootstrap/app.php';

$app->handleRequest(Request::capture());
EOF_INDEX

  echo "✅ Đã tạo file public/index.php"
else
  echo "✅ File public/index.php đã tồn tại."
fi

# Đảm bảo file test health tồn tại
echo "OK" > public/health.txt
echo "OK" > public/status.txt

# Tạo file phpinfo.php để debug
echo "<?php phpinfo(); ?>" > public/phpinfo.php

# Cấu hình Nginx
echo "Cấu hình Nginx với port $PORT..."

# Đảm bảo thư mục cấu hình Nginx tồn tại
mkdir -p /etc/nginx/conf.d

# Tạo cấu hình Nginx mới với xử lý CORS được cải thiện
cat > /etc/nginx/conf.d/default.conf << EOF
server {
    listen $PORT;
    server_name _;
    root /var/www/html/public;
    index index.php;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }
    
    # # Xử lý pre-flight OPTIONS request ở cấp độ server
    # if (\$request_method = OPTIONS) {
    #     add_header 'Access-Control-Allow-Origin' '*';
    #     add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, OPTIONS';
    #     add_header 'Access-Control-Allow-Headers' 'Content-Type, Authorization, X-Requested-With, Accept';
    #     add_header 'Access-Control-Max-Age' '86400';
    #     add_header 'Content-Type' 'text/plain charset=UTF-8';
    #     add_header 'Content-Length' '0';
    #     return 204;
    # }
    
    location ~ \.php$ {
        fastcgi_pass 127.0.0.1:9000;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }
    
    # Health check endpoints
    location = /health.txt {
        access_log off;
        add_header Content-Type text/plain;
        return 200 'OK';
    }
    
    location = /status.txt {
        access_log off;
        add_header Content-Type text/plain;
        return 200 'OK';
    }
}
EOF

echo "✅ Cấu hình Nginx đã được tạo"

# Đảm bảo thư mục trong DocumentRoot tồn tại
echo "Kiểm tra DocumentRoot /var/www/html/public..."
if [ ! -d "/var/www/html/public" ]; then
  echo "⚠️ Thư mục DocumentRoot không tồn tại, tạo mới..."
  mkdir -p /var/www/html/public
fi

# Sao chép các tệp tin từ thư mục public của dự án vào /var/www/html/public
echo "Sao chép các tệp tin từ thư mục public vào DocumentRoot..."
if [ -d "public" ]; then
  cp -r public/* /var/www/html/public/ 2>/dev/null || echo "❌ Không thể sao chép files"
  
  # Đặt quyền cho thư mục DocumentRoot
  chown -R www-data:www-data /var/www/html
  chmod -R 755 /var/www/html
  echo "✅ Đã sao chép các tệp tin vào /var/www/html/public"
else
  echo "❌ Không tìm thấy thư mục public trong dự án!"
fi

# Tạo file index.php trong DocumentRoot nếu không tồn tại
if [ ! -f "/var/www/html/public/index.php" ]; then
  echo "⚠️ File index.php không tồn tại trong DocumentRoot, tạo mới..."
  cat > /var/www/html/public/index.php << 'EOF_INDEX'
<?php

use Illuminate\Foundation\Application;
use Illuminate\Http\Request;

define('LARAVEL_START', microtime(true));

// Determine if the application is in maintenance mode...
if (file_exists($maintenance = __DIR__.'/../storage/framework/maintenance.php')) {
    require $maintenance;
}

// Register the Composer autoloader...
require __DIR__.'/../vendor/autoload.php';

// Bootstrap Laravel and handle the request...
/** @var Application $app */
$app = require_once __DIR__.'/../bootstrap/app.php';

$app->handleRequest(Request::capture());
EOF_INDEX
  echo "✅ Đã tạo file index.php trong DocumentRoot"
fi

# Tạo symbolic link từ thư mục gốc của Laravel đến /var/www/html
echo "Tạo symbolic links từ thư mục Laravel đến /var/www/html..."
for dir in app bootstrap config database resources routes storage vendor; do
  if [ -d "$dir" ]; then
    if [ ! -d "/var/www/html/$dir" ] || [ -L "/var/www/html/$dir" ]; then
      rm -rf "/var/www/html/$dir" 2>/dev/null
      ln -sf "$(pwd)/$dir" "/var/www/html/$dir"
      echo "✅ Đã liên kết thư mục $dir"
    else
      echo "⚠️ Thư mục /var/www/html/$dir đã tồn tại và không phải symlink"
    fi
  else
    echo "❌ Không tìm thấy thư mục $dir trong dự án"
  fi
done

# Tạo file .env trong /var/www/html
cp .env /var/www/html/.env 2>/dev/null

# Cập nhật cấu hình Supervisor để chạy Nginx và PHP-FPM
echo "Cập nhật cấu hình Supervisor..."
cat > /etc/supervisor/conf.d/supervisord.conf << EOF
[supervisord]
nodaemon=true
logfile=/var/log/supervisord.log
pidfile=/var/run/supervisord.pid
user=root

[program:php-fpm]
command=php-fpm
stdout_logfile=/dev/stdout
stdout_logfile_maxbytes=0
stderr_logfile=/dev/stderr
stderr_logfile_maxbytes=0

[program:nginx]
command=nginx -g "daemon off;"
stdout_logfile=/dev/stdout
stdout_logfile_maxbytes=0
stderr_logfile=/dev/stderr
stderr_logfile_maxbytes=0
EOF

echo "✅ Cấu hình Supervisor đã được cập nhật"

# Xóa cache
echo "Xóa cache Laravel..."
php artisan cache:clear
php artisan config:clear
php artisan route:clear

# Chạy migration
echo "Chạy migration..."
php artisan migrate --force || echo "Lỗi khi chạy migration"

# Tạo symbolic link cho storage
echo "Tạo symbolic link..."
php artisan storage:link || echo "Không thể tạo symbolic link"

# Tối ưu ứng dụng
echo "Tối ưu ứng dụng..."
php artisan optimize || echo "Không thể tối ưu ứng dụng"

# Tạo file kiểm tra kết nối để debug
cat > /var/www/html/public/connection-test.php << 'EOF'
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
EOF

echo "🚀 Khởi động ứng dụng với Nginx và PHP-FPM..."
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
