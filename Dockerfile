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
    supervisor

# Clean cache
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Cài đặt extensions PHP
RUN docker-php-ext-install pdo pdo_pgsql pgsql zip exif pcntl bcmath mbstring

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

# Cài đặt dependencies
RUN composer install --no-interaction --no-dev --optimize-autoloader 

# Tạo file .env từ example hoặc tạo mới nếu không có
RUN if [ -f ".env.example" ]; then cp .env.example .env; else echo "APP_NAME=Laravel\nAPP_ENV=production\nAPP_KEY=\nAPP_DEBUG=false\nAPP_URL=https://api-fitness-app.onrender.com\nLOG_CHANNEL=stack\nDB_CONNECTION=pgsql" > .env; fi

# Tạo application key nếu chưa có
RUN php artisan key:generate --force

# Phân quyền thư mục storage và cache
RUN chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache
RUN chown -R www-data:www-data /var/www/html

# Exposing port
ENV PORT=${PORT:-8080}
EXPOSE $PORT

# Start script
COPY docker/start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

# Khởi động các dịch vụ
CMD ["/usr/local/bin/start.sh"]