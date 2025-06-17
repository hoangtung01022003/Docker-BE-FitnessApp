#!/bin/bash

# Tạo application key nếu chưa có
php artisan key:generate --force

# Chạy migration
php artisan migrate --force

# Tạo symbolic link
php artisan storage:link || true

# Xóa cache và tạo cache mới
php artisan optimize

# Thay đổi port trong Nginx
sed -i "s/listen 80/listen $PORT/g" /etc/nginx/sites-available/default

# Khởi động supervisor
/usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
