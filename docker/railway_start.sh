#!/bin/bash

echo "🚂 Khởi động ứng dụng trên Railway..."

# Tạo file .env từ các biến môi trường
cat > .env << EOF
APP_NAME=${APP_NAME:-"Fitness App"}
APP_ENV=${APP_ENV:-production}
APP_KEY=${APP_KEY:-}
APP_DEBUG=${APP_DEBUG:-false}
APP_URL=${RAILWAY_PUBLIC_DOMAIN:-${APP_URL:-http://localhost}}

LOG_CHANNEL=${LOG_CHANNEL:-stack}
LOG_LEVEL=${LOG_LEVEL:-error}

# Cấu hình kết nối MySQL
DB_CONNECTION=mysql
DB_HOST=${MYSQLHOST:-${DB_HOST:-127.0.0.1}}
DB_PORT=${MYSQLPORT:-${DB_PORT:-3306}}
DB_DATABASE=${MYSQLDATABASE:-${DB_DATABASE:-laravel}}
DB_USERNAME=${MYSQLUSER:-${DB_USERNAME:-root}}
DB_PASSWORD=${MYSQLPASSWORD:-${DB_PASSWORD:-}}
DB_URL=${DATABASE_URL:-}

BROADCAST_DRIVER=${BROADCAST_DRIVER:-log}
CACHE_DRIVER=${CACHE_DRIVER:-file}
FILESYSTEM_DISK=${FILESYSTEM_DISK:-local}
QUEUE_CONNECTION=${QUEUE_CONNECTION:-sync}
SESSION_DRIVER=${SESSION_DRIVER:-cookie}
SESSION_LIFETIME=${SESSION_LIFETIME:-120}

# Cấu hình CORS
SANCTUM_STATEFUL_DOMAINS=${SANCTUM_STATEFUL_DOMAINS:-localhost:3000,127.0.0.1:3000,*.up.railway.app}
SESSION_DOMAIN=${SESSION_DOMAIN:-.up.railway.app}
SESSION_SECURE_COOKIE=${SESSION_SECURE_COOKIE:-true}
CORS_ALLOWED_ORIGINS=${CORS_ALLOWED_ORIGINS:-http://localhost:3000,http://127.0.0.1:3000}
EOF

# Tạo application key nếu chưa có
if [ -z "$APP_KEY" ]; then
  echo "Tạo APP_KEY mới..."
  php artisan key:generate --force
fi

# Hiển thị thông tin kết nối để debug
echo "Thông tin kết nối MySQL:"
echo "DB_HOST: ${MYSQLHOST:-${DB_HOST:-không có}}"
echo "DB_PORT: ${MYSQLPORT:-${DB_PORT:-không có}}"
echo "DB_DATABASE: ${MYSQLDATABASE:-${DB_DATABASE:-không có}}"
echo "DB_USERNAME: ${MYSQLUSER:-${DB_USERNAME:-không có}}"

# Kiểm tra xem biến môi trường DATABASE_URL đã được đặt chưa
if [ ! -z "$DATABASE_URL" ]; then
  echo "Đã tìm thấy DATABASE_URL. Sẽ sử dụng để kết nối..."
fi

# Kiểm tra xem MySQL đã được cấu hình chưa
if [ -z "${MYSQLHOST:-${DB_HOST}}" ]; then
  echo "⚠️ Không tìm thấy thông tin máy chủ MySQL trong biến môi trường."
  echo "⚠️ Đảm bảo bạn đã thêm MySQL addon trong Railway và biến môi trường đã được thiết lập."
  echo "⚠️ Tiếp tục mà không có MySQL..."
  
  # Thiết lập SQLite làm dự phòng
  echo "Sử dụng SQLite làm cơ sở dữ liệu dự phòng..."
  sed -i "s/DB_CONNECTION=mysql/DB_CONNECTION=sqlite/" .env
  touch database/database.sqlite
  
  # Tiếp tục mà không kiểm tra kết nối MySQL
else
  # Thử kết nối MySQL
  echo "Đợi MySQL sẵn sàng..."
  MAX_RETRIES=15
  RETRY=0

  # Function để kiểm tra kết nối MySQL
  function check_mysql_connection() {
    if nc -z -w5 "${MYSQLHOST:-${DB_HOST}}" "${MYSQLPORT:-${DB_PORT:-3306}}"; then
      # Kết nối thành công, kiểm tra đăng nhập
      if mysql -h"${MYSQLHOST:-${DB_HOST}}" -P"${MYSQLPORT:-${DB_PORT:-3306}}" -u"${MYSQLUSER:-${DB_USERNAME}}" -p"${MYSQLPASSWORD:-${DB_PASSWORD}}" -e "SELECT 1" >/dev/null 2>&1; then
        return 0  # Có thể kết nối và đăng nhập thành công
      fi
    fi
    return 1  # Không thể kết nối hoặc đăng nhập
  }

  # Thử kết nối nhiều lần
  until check_mysql_connection || [ $RETRY -eq $MAX_RETRIES ]
  do
    echo "Thử kết nối MySQL lần $RETRY/$MAX_RETRIES..."
    RETRY=$((RETRY+1))
    sleep 2
  done

  if [ $RETRY -eq $MAX_RETRIES ]; then
    echo "❌ Không thể kết nối đến MySQL sau $MAX_RETRIES lần thử!"
    echo "⚠️ Chuyển sang sử dụng SQLite..."
    
    # Chuyển sang SQLite nếu kết nối MySQL thất bại
    sed -i "s/DB_CONNECTION=mysql/DB_CONNECTION=sqlite/" .env
    touch database/database.sqlite
  else
    echo "✅ Đã kết nối thành công đến MySQL!"
    
    # Tạo database nếu chưa tồn tại
    echo "Kiểm tra và tạo database..."
    DB_NAME="${MYSQLDATABASE:-${DB_DATABASE}}"
    mysql -h"${MYSQLHOST:-${DB_HOST}}" -P"${MYSQLPORT:-${DB_PORT:-3306}}" -u"${MYSQLUSER:-${DB_USERNAME}}" -p"${MYSQLPASSWORD:-${DB_PASSWORD}}" -e "CREATE DATABASE IF NOT EXISTS \`$DB_NAME\`;" || true
  fi
fi

# Chạy migration
echo "Chạy migration..."
php artisan migrate --force || true

# Tạo symbolic link cho storage
echo "Tạo symbolic link..."
php artisan storage:link || true

# Tối ưu ứng dụng
echo "Tối ưu ứng dụng..."
php artisan optimize

# Cấu hình CORS trong config file
echo "Cấu hình CORS..."
php -r "
\$corsFile = 'config/cors.php';
if (file_exists(\$corsFile)) {
    \$content = file_get_contents(\$corsFile);
    \$origins = '${CORS_ALLOWED_ORIGINS:-http://localhost:3000,http://127.0.0.1:3000}';
    \$originsArray = explode(',', \$origins);
    \$formattedOrigins = array_map(function(\$origin) { return \"'\$origin'\"; }, \$originsArray);
    \$originsString = implode(', ', \$formattedOrigins);
    \$pattern = \"/'allowed_origins' => \\[(.*?)\\]/s\";
    \$replacement = \"'allowed_origins' => [\$originsString]\";
    \$content = preg_replace(\$pattern, \$replacement, \$content);
    file_put_contents(\$corsFile, \$content);
    echo 'CORS đã được cấu hình với các origins: ' . \$origins . PHP_EOL;
}
"

# Thay đổi port trong Nginx
PORT="${PORT:-8080}"
echo "Cấu hình Nginx với port $PORT..."
sed -i "s/listen 80/listen $PORT/g" /etc/nginx/sites-available/default

echo "🚀 Khởi động ứng dụng..."
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
