FROM php:8.2-fpm-alpine

# Set working directory
WORKDIR /var/www/html

# Install system dependencies
RUN apk add --no-cache \
    git \
    curl \
    libpng-dev \
    libxml2-dev \
    zip \
    unzip \
    postgresql-dev \
    libzip-dev \
    oniguruma-dev \
    openssl-dev \
    autoconf \
    g++ \
    make \
    linux-headers \
    pcre-dev

# Install PHP extensions
RUN docker-php-ext-install \
    pdo \
    pdo_pgsql \
    pgsql \
    mbstring \
    exif \
    pcntl \
    bcmath \
    gd \
    zip \
    opcache \
    sockets

# Install MongoDB extension
RUN pecl install mongodb-1.17.1 && \
    docker-php-ext-enable mongodb

# Install Redis extension
RUN pecl install redis-6.0.2 && \
    docker-php-ext-enable redis

# Clear cache
RUN rm -rf /tmp/pear

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Create system user to run Composer and Artisan Commands
RUN addgroup -g 1000 laravel && \
    adduser -D -u 1000 -G laravel laravel

# Copy existing application directory contents
COPY --chown=laravel:laravel ./src /var/www/html

# Copy PHP configuration
COPY ./docker/php/local.ini /usr/local/etc/php/conf.d/local.ini

# Set proper permissions
RUN chown -R laravel:laravel /var/www/html && \
    chmod -R 755 /var/www/html/storage && \
    chmod -R 755 /var/www/html/bootstrap/cache

# Switch to non-root user
USER laravel

# Expose port 9000 for PHP-FPM
EXPOSE 9000

CMD ["php-fpm"]