#!/bin/bash

echo "🚂 Khởi động ứng dụng trên Railway..."

# Railway tự động tạo biến môi trường với thông tin kết nối MySQL
# MYSQLHOST, MYSQLPORT, MYSQLDATABASE, MYSQLUSER, MYSQLPASSWORD

# Chờ MySQL sẵn sàng - Railway có thể khởi động MySQL sau container ứng dụng
echo "Đợi MySQL sẵn sàng..."
MAX_RETRIES=30
RETRY=0

until [ $RETRY -eq $MAX_RETRIES ] || mysql -h"${MYSQLHOST:-$DB_HOST}" -P"${MYSQLPORT:-$DB_PORT}" -u"${MYSQLUSER:-$DB_USERNAME}" -p"${MYSQLPASSWORD:-$DB_PASSWORD}" -e "SELECT 1;" > /dev/null 2>&1
do
  echo "Thử kết nối MySQL lần $RETRY/$MAX_RETRIES..."
  RETRY=$((RETRY+1))
  sleep 2
done

if [ $RETRY -eq $MAX_RETRIES ]; then
  echo "❌ Không thể kết nối đến MySQL sau $MAX_RETRIES lần thử!"
  echo "Kiểm tra thông tin kết nối:"
  echo "Host: ${MYSQLHOST:-$DB_HOST}"
  echo "Port: ${MYSQLPORT:-$DB_PORT}"
  echo "User: ${MYSQLUSER:-$DB_USERNAME}"
  echo "Database: ${MYSQLDATABASE:-$DB_DATABASE}"
  exit 1
fi

echo "✅ Đã kết nối thành công đến MySQL!"

# Chạy các lệnh Laravel
echo "Chạy migration..."
php artisan migrate --force

echo "Tạo storage link..."
php artisan storage:link || true

echo "Tối ưu ứng dụng..."
php artisan optimize

# Thay đổi port trong Nginx
echo "Cấu hình Nginx với port $PORT..."
sed -i "s/listen 80/listen $PORT/g" /etc/nginx/sites-available/default

echo "🚀 Khởi động ứng dụng..."
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
