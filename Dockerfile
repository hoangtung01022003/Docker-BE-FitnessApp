FROM php:8.2-fpm

# Cài đặt dependencies và Nginx
RUN apt-get update && apt-get install -y \
    nginx \
    supervisor \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    libzip-dev \
    zip \
    unzip

# Cài đặt extensions PHP
RUN docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd zip

# Cài đặt composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Thiết lập thư mục làm việc
WORKDIR /var/www/html

# Tạo một số file health cơ bản
RUN echo "OK" > health.txt
RUN mkdir -p public && echo "OK" > public/health.txt

# Sao chép code nguồn
COPY . /var/www/html

# Tạo file phpinfo cho debugging
RUN echo "<?php phpinfo(); ?>" > public/phpinfo.php
RUN echo "OK" > public/status.txt

# Cài đặt dependencies PHP
RUN composer install --no-interaction --no-dev --optimize-autoloader

# Tạo file .env cơ bản nhất có thể
RUN echo "APP_NAME=FitnessApp\n\
APP_ENV=production\n\
APP_KEY=base64:xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx\n\
APP_DEBUG=true\n\
APP_URL=https://docker-be-fitnessapp-production.up.railway.app\n\
\n\
LOG_CHANNEL=stderr\n\
LOG_LEVEL=debug\n\
\n\
DB_CONNECTION=mysql\n\
DB_HOST=\${MYSQLHOST}\n\
DB_PORT=\${MYSQLPORT}\n\
DB_DATABASE=\${MYSQLDATABASE}\n\
DB_USERNAME=\${MYSQLUSER}\n\
DB_PASSWORD=\${MYSQLPASSWORD}\n" > /var/www/html/.env

# Tạo key Laravel
RUN php artisan key:generate --force

# Bỏ qua cache và optimize trong quá trình debug
# RUN php artisan config:cache
# RUN php artisan route:cache

# Tạo file index.php đơn giản nhất có thể
RUN echo "<?php echo 'Laravel is running'; ?>" > /var/www/html/public/index.simple.php

# Thay đổi quyền thư mục
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 777 /var/www/html/storage /var/www/html/bootstrap/cache

# Tạo thư mục cho Nginx và cấu hình
RUN mkdir -p /etc/nginx/conf.d
COPY ./docker/nginx.conf /etc/nginx/conf.d/default.conf

# Cấu hình PHP-FPM để lắng nghe trên 127.0.0.1:9000
RUN echo "listen = 127.0.0.1:9000" >> /usr/local/etc/php-fpm.d/www.conf

# Cấu hình Supervisor để quản lý các process
COPY ./docker/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Expose port 80
EXPOSE 80

# Tạo file kiểm tra kết nối để debug - Đã sửa lỗi cú pháp
RUN echo '<?php\n\
// Hiển thị tất cả lỗi\n\
ini_set("display_errors", 1);\n\
ini_set("display_startup_errors", 1);\n\
error_reporting(E_ALL);\n\
echo "<h1>Kiểm tra kết nối Laravel - MySQL</h1>";\n\
// Kiểm tra môi trường\n\
echo "<h2>Thông tin môi trường:</h2>";\n\
echo "<ul>";\n\
echo "<li>PHP version: " . phpversion() . "</li>";\n\
echo "<li>Server: " . $_SERVER["SERVER_SOFTWARE"] . "</li>";\n\
echo "<li>Document Root: " . $_SERVER["DOCUMENT_ROOT"] . "</li>";\n\
echo "<li>Current directory: " . getcwd() . "</li>";\n\
echo "</ul>";\n\
# // Thử kết nối MySQL
try {\n\
    $db_host = getenv("DB_HOST") ?: "trolley.proxy.rlwy.net";\n\
    $db_port = getenv("DB_PORT") ?: "54154";\n\
    $db_name = getenv("DB_DATABASE") ?: "railway";\n\
    $db_user = getenv("DB_USERNAME") ?: "root";\n\
    $db_pass = getenv("DB_PASSWORD") ?: "ARakarqbSOaCUkoUTXyGSYVMfEYVPuVY";\n\
    echo "<h2>Thông tin kết nối MySQL:</h2>";\n\
    echo "<ul>";\n\
    echo "<li>Host: $db_host</li>";\n\
    echo "<li>Port: $db_port</li>";\n\
    echo "<li>Database: $db_name</li>";\n\
    echo "<li>Username: $db_user</li>";\n\
    echo "</ul>";\n\
    $pdo = new PDO("mysql:host=$db_host;port=$db_port;dbname=$db_name", $db_user, $db_pass);\n\
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);\n\
    echo "<p style=\"color:green\">✅ Kết nối MySQL thành công!</p>";\n\
    // Thử truy vấn\n\
    $stmt = $pdo->query("SHOW TABLES");\n\
    $tables = $stmt->fetchAll(PDO::FETCH_COLUMN);\n\
    echo "<h2>Danh sách bảng:</h2>";\n\
    echo "<ul>";\n\
    if (count($tables) > 0) {\n\
        foreach ($tables as $table) {\n\
            echo "<li>$table</li>";\n\
        }\n\
    } else {\n\
        echo "<li>Không có bảng nào.</li>";\n\
    }\n\
    echo "</ul>";\n\
} catch (PDOException $e) {\n\
    echo "<p style=\"color:red\">❌ Lỗi kết nối MySQL: " . htmlspecialchars($e->getMessage()) . "</p>";\n\
}\n\
' > public/connection-test.php

# Chạy script khởi động Railway
COPY ./docker/railway_start.sh /railway_start.sh
RUN chmod +x /railway_start.sh

# Khởi động với script Railway
CMD ["/railway_start.sh"]