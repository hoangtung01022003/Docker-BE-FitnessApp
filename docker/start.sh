#!/bin/bash

# Tạo file .env hợp lệ từ đầu để tránh lỗi định dạng
cat > .env << EOF
APP_NAME=Laravel
APP_ENV=production
APP_KEY=
APP_DEBUG=false
APP_URL=${APP_URL:-https://api-fitness-app.onrender.com}
LOG_CHANNEL=stack
LOG_LEVEL=error

DB_CONNECTION=${DB_CONNECTION:-pgsql}
DB_HOST=${DB_HOST:-127.0.0.1}
DB_PORT=${DB_PORT:-5432}
DB_DATABASE=${DB_DATABASE:-laravel}
DB_USERNAME=${DB_USERNAME:-postgres}
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

# Tạo application key mới
php artisan key:generate --force

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
