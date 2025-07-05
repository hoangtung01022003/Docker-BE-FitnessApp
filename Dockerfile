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

# Sao chép code nguồn
COPY . /var/www/html

# Cài đặt dependencies PHP
RUN composer install --no-interaction --optimize-autoloader

# Thay đổi quyền thư mục
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html/storage /var/www/html/bootstrap/cache

# Tạo thư mục cho Nginx và cấu hình
RUN mkdir -p /etc/nginx/conf.d
COPY ./docker/nginx/conf.d/app.conf /etc/nginx/conf.d/default.conf

# Cấu hình PHP-FPM để lắng nghe trên 127.0.0.1:9000
RUN echo "listen = 127.0.0.1:9000" >> /usr/local/etc/php-fpm.d/www.conf

# Cấu hình Supervisor để quản lý các process
COPY ./docker/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Expose port 80
EXPOSE 80

# Khởi động Nginx và PHP-FPM
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]