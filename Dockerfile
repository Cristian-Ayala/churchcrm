FROM php:8.2-apache

# Install dependencies
RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y \
    wget \
    nano \
    unzip \
    gettext \
    libfreetype6-dev \
    libzip-dev \
    libpng-dev \
    libgmp-dev \
    libxml2-dev \
    libcurl4-gnutls-dev \
    libicu-dev \
    libjpeg-dev \
    libonig-dev \
    libc-client-dev && \
    rm -rf /var/lib/apt/lists/*

RUN docker-php-ext-install -j$(nproc) \
    xml \
    exif \
    pdo_mysql \
    gettext \
    iconv \
    mysqli \
    zip

RUN docker-php-ext-configure gd --with-freetype --with-jpeg && \
    docker-php-ext-install -j$(nproc) gd

# Download ChurchCRM and unzip
RUN wget https://github.com/ChurchCRM/CRM/releases/download/5.3.1/ChurchCRM-5.3.1.zip -P /tmp && \
    unzip /tmp/ChurchCRM-5.3.1.zip -d /var/www/ && \
    rm /tmp/ChurchCRM-5.3.1.zip

# Create log directory
RUN if [ ! -d /var/log/churchcrm/ ]; then mkdir /var/log/churchcrm/; fi

# Set permissions
RUN chown -R www-data:www-data /var/log/churchcrm/ /var/www/churchcrm/ && \
    chmod -R 755 /var/www/churchcrm/ && \
    chmod -R 777 /var/www/churchcrm/Include/ /var/www/churchcrm/Images/

# Configure Apache for ChurchCRM
RUN echo '<VirtualHost *:80>' > /etc/apache2/sites-available/churchcrm.conf && \
    echo '    ServerAdmin cristianaaron10@gmail.com' >> /etc/apache2/sites-available/churchcrm.conf && \
    echo '    DocumentRoot /var/www/churchcrm' >> /etc/apache2/sites-available/churchcrm.conf && \
    echo '    ServerName churchcrm.kleex.store' >> /etc/apache2/sites-available/churchcrm.conf && \
    echo '    ServerAlias churchcrm.kleex.store' >> /etc/apache2/sites-available/churchcrm.conf && \
    echo '    <Directory /var/www/churchcrm/>' >> /etc/apache2/sites-available/churchcrm.conf && \
    echo '        Options FollowSymlinks' >> /etc/apache2/sites-available/churchcrm.conf && \
    echo '        AllowOverride All' >> /etc/apache2/sites-available/churchcrm.conf && \
    echo '        Require all granted' >> /etc/apache2/sites-available/churchcrm.conf && \
    echo '    </Directory>' >> /etc/apache2/sites-available/churchcrm.conf && \
    echo '    ErrorLog /var/log/churchcrm/error.log' >> /etc/apache2/sites-available/churchcrm.conf && \
    echo '    CustomLog /var/log/churchcrm/access.log combined' >> /etc/apache2/sites-available/churchcrm.conf && \
    echo '</VirtualHost>' >> /etc/apache2/sites-available/churchcrm.conf

# Enable the ChurchCRM site configuration
RUN a2ensite churchcrm.conf

# Enable the rewrite module
RUN a2enmod rewrite

COPY ./default.conf /etc/apache2/apache2.conf

# Reload Apache service
RUN service apache2 restart

# Configure PHP
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini" && \
    sed -i 's/^upload_max_filesize.*$/upload_max_filesize = 2G/g' $PHP_INI_DIR/php.ini && \
    sed -i 's/^post_max_size.*$/post_max_size = 2G/g' $PHP_INI_DIR/php.ini && \
    sed -i 's/^memory_limit.*$/memory_limit = 2G/g' $PHP_INI_DIR/php.ini && \
    sed -i 's/^max_execution_time.*$/max_execution_time = 120/g' $PHP_INI_DIR/php.ini

WORKDIR /var/www/churchcrm

EXPOSE 80

# ##########################
# database url: mariadb-db #
# ##########################
# Default credentials:#
# username: admin     #
# password: changeme  #
# #####################

# nano /var/www/churchcrm/Include/Config.php --> $TwoFASecretKey
