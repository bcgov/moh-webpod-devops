FROM drupal:10-apache

# Install additional PHP extensions if needed
RUN apt-get update && apt-get install -y \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) gd

# Set working directory
WORKDIR /var/www/html

# Ensure permissions for mounted volumes
# RUN chown -R www-data:www-data /var/www/html/sites
# RUN chown -R www-data:www-data /var/www/html/modules
# RUN chown -R www-data:www-data /var/www/html/profiles
# RUN chown -R www-data:www-data /var/www/html/themes
RUN chmod -R 777 /var/www/html/sites

# Expose Apache port
EXPOSE 80