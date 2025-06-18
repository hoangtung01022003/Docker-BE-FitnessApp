#!/bin/bash

# Tạo file .env hợp lệ từ đầu để tránh lỗi định dạng
cat > .env << EOF
APP_NAME=${APP_NAME:-Laravel}
APP_ENV=${APP_ENV:-production}
APP_KEY=${APP_KEY:-}
APP_DEBUG=${APP_DEBUG:-false}
APP_URL=${APP_URL:-https://api-fitness-app.onrender.com}
LOG_CHANNEL=${LOG_CHANNEL:-stack}
LOG_LEVEL=${LOG_LEVEL:-error}

# Cấu hình MySQL
DB_CONNECTION=mysql
DB_HOST=${DB_HOST:-mysql-host}
DB_PORT=${DB_PORT:-3306}
DB_DATABASE=${DB_DATABASE:-laravel}
DB_USERNAME=${DB_USERNAME:-root}
DB_PASSWORD=${DB_PASSWORD:-}

BROADCAST_DRIVER=${BROADCAST_DRIVER:-log}
CACHE_DRIVER=${CACHE_DRIVER:-file}
FILESYSTEM_DISK=${FILESYSTEM_DISK:-local}
QUEUE_CONNECTION=${QUEUE_CONNECTION:-sync}
SESSION_DRIVER=${SESSION_DRIVER:-cookie}
SESSION_LIFETIME=${SESSION_LIFETIME:-120}

SANCTUM_STATEFUL_DOMAINS=${SANCTUM_STATEFUL_DOMAINS:-localhost:3000,127.0.0.1:3000}
SESSION_DOMAIN=${SESSION_DOMAIN:-.render.com}
SESSION_SECURE_COOKIE=${SESSION_SECURE_COOKIE:-true}

CORS_ALLOWED_ORIGINS=${CORS_ALLOWED_ORIGINS:-http://localhost:3000,http://127.0.0.1:3000}
EOF

# Tạo application key mới nếu chưa có
if [ -z "$APP_KEY" ]; then
  php artisan key:generate --force
fi

# Kiểm tra kết nối MySQL trước khi chạy migration
echo "Kiểm tra kết nối đến MySQL..."
php -r "try { 
    \$conn = new PDO('mysql:host=${DB_HOST};port=${DB_PORT}', '${DB_USERNAME}', '${DB_PASSWORD}'); 
    echo 'Kết nối MySQL thành công!\n'; 
    
    # Kiểm tra database đã tồn tại chưa
    \$result = \$conn->query(\"SELECT SCHEMA_NAME FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME = '${DB_DATABASE}'\");
    if (!\$result->fetch()) {
        echo 'Tạo database...\n';
        \$conn->exec('CREATE DATABASE IF NOT EXISTS ${DB_DATABASE}');
    }
} catch (PDOException \$e) { 
    echo 'Lỗi kết nối MySQL: ' . \$e->getMessage() . '\n'; 
    echo 'Kiểm tra lại cấu hình DB_HOST, DB_PORT, DB_USERNAME, DB_PASSWORD trong biến môi trường Render.\n';
    exit(1); 
}"

# Chạy migration (tùy chỉnh theo nhu cầu)
php artisan migrate --force

# Tạo symbolic link
php artisan storage:link || true

# Xóa cache
php artisan optimize:clear

# Tạo cache mới
php artisan optimize

# Thay đổi port trong Nginx
sed -i "s/listen 80/listen $PORT/g" /etc/nginx/sites-available/default

# Khởi động supervisor
/usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
