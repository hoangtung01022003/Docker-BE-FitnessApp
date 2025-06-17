FROM php:8.2-fpm

# Cài đặt các dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    libpng-dev \
    libfreetype6-dev \
    locales \
    zip \
    unzip \
    git \
    curl \
    libonig-dev \
    libxml2-dev \
    libpq-dev \
    libzip-dev \
    nginx \
    supervisor \
    default-mysql-client \
    redis-tools

# Clean cache
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Cài đặt extensions PHP - thêm MySQL và Redis
RUN docker-php-ext-install pdo pdo_mysql pdo_pgsql pgsql zip exif pcntl bcmath mbstring
RUN pecl install redis && docker-php-ext-enable redis

# Cài đặt Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Tạo thư mục làm việc
WORKDIR /var/www/html

# Copy source code
COPY . /var/www/html

# Cấu hình Nginx
COPY docker/nginx.conf /etc/nginx/sites-available/default

# Cấu hình supervisor
COPY docker/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Cài đặt dependencies và tối ưu autoload
RUN composer install --no-interaction --no-dev --optimize-autoloader 

# Tạo file .env từ production
RUN cp .env.production .env

# Tạo application key nếu chưa có
RUN php artisan key:generate --force

# Cấu hình CORS cho frontend ở localhost
RUN sed -i "s/'allowed_origins' => \[\]/'allowed_origins' => \['http:\/\/localhost:3000', 'http:\/\/localhost', 'http:\/\/localhost:8080', 'http:\/\/127.0.0.1', 'http:\/\/127.0.0.1:3000', 'http:\/\/127.0.0.1:8080'\]/g" config/cors.php

# Phân quyền thư mục storage và cache - bổ sung quyền
RUN chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache
RUN chown -R www-data:www-data /var/www/html
RUN mkdir -p /var/www/html/storage/logs
RUN touch /var/www/html/storage/logs/laravel.log
RUN chmod -R 777 /var/www/html/storage/logs/laravel.log

# Exposing port - để Render.com tự quyết định port
ENV PORT=${PORT:-8080}
EXPOSE $PORT

# Start script
COPY docker/start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

# Khởi động các dịch vụ
CMD ["/usr/local/bin/start.sh"]