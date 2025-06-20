#!/bin/bash

# Tạo application key nếu chưa có
php artisan key:generate --force

# Chạy migration
php artisan migrate --force

# Tạo symbolic link
php artisan storage:link || true

# Xóa cache và tạo cache mới
php artisan optimize

# Kiểm tra thư mục cấu hình Nginx
mkdir -p /etc/nginx/sites-available /etc/nginx/sites-enabled

# Sao chép file cấu hình Nginx đúng vào vị trí thích hợp
cp /var/www/html/docker/nginx.conf /etc/nginx/sites-available/default

# Tạo symlink nếu chưa tồn tại
ln -sf /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default

# Thay đổi port trong Nginx
sed -i "s/listen 80/listen $PORT/g" /etc/nginx/sites-available/default

# Kiểm tra cấu hình Nginx
nginx -t

# Khởi động supervisor
/usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
