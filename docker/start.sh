#!/bin/bash

# Chạy migration (tùy chỉnh theo nhu cầu)
php artisan migrate --force

# Cách tạo ứng dụng symbolic link
php artisan storage:link

# Xóa cache
php artisan optimize:clear

# Tạo cache mới để tối ưu hóa ứng dụng
php artisan optimize

# Thay đổi port trong cấu hình Nginx
sed -i "s/listen 80/listen $PORT/g" /etc/nginx/sites-available/default

# Khởi động supervisor
/usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
