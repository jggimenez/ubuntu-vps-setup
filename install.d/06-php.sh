#!/bin/bash
#==============================================================================
# ENTRY: installPHP
# TEXT: Install PHP (source) with PHP-FPM
#==============================================================================

installPHP() {
    PHP_V=5.4.11
    MIRROR=us.php.net
#    MIRROR= http://us.php.net/distributions/php-$PHP_V.tar.bz2

    INSTALL_DIR="/opt/php5"
    CONFIG_DIR="$INSTALL_DIR/etc"
    EXTRAS_DIR="$CONFIG_DIR/conf.d"

    clear
    _title "Compiling & Installing PHP with PHP-FPM."

#        libpq5 libtool libevent-dev libmysqlclient16-dev
#        libsyck0-dev subversion
    apt-get -y install make bison flex gcc patch autoconf autoconf2.13 \
        locate libxml2-dev libbz2-dev libpcre3-dev libssl-dev zlib1g-dev \
        libmcrypt-dev libmhash-dev libmhash2 libcurl4-openssl-dev libpq-dev \
        libpq5 libtool libevent-dev libmysqlclient-dev\
        libjpeg62-dev libpng3-dev libfreetype6-dev libt1-dev libxslt1-dev \
        libxpm-dev

    pushd .
    cd /usr/local/src/


    ##==================================================
    ##Download necesary files for PHP +  Suhosin
    ##==================================================
    _writeline "Checking & downloading files (if needed)"
    [ ! -f php-$PHP_V.tar.bz2 -o "$1" == "true" ] \
        && wget http://$MIRROR/get/php-$PHP_V.tar.bz2/from/this/mirror \
        -O php-$PHP_V.tar.bz2

    _write "Deleting working directories..."
    [ -d php-$PHP_V ] \
        && [ ! -L php-$PHP_V ] \
        && rm -rf php-$PHP_V

    _writeline " done."

    ##==================================================
    ##Extract necesary files for PHP +  Suhosin
    ##==================================================
    _write "Extracting files..."
    tar xjf php-$PHP_V.tar.bz2
    _writeline " done."

    cd php-$PHP_V
    ./buildconf --force
#        --disable-pdo
#        --with-pgsql
    ./configure --prefix=/opt/php5 \
        --with-config-file-path=/opt/php5/etc \
        --with-config-file-scan-dir=/opt/php5/etc/conf.d \
        --enable-fpm \
        --with-fpm-user=www-data \
        --with-fpm-group=www-data \
        --with-curl \
        --with-pear \
        --with-gd \
        --with-jpeg-dir \
        --with-png-dir \
        --with-freetype-dir \
        --with-t1lib \
        --with-pdo-mysql \
        --with-mysqli \
        --with-mysql \
        --with-openssl \
        --with-xmlrpc \
        --with-xpm-dir \
        --with-xsl \
        --with-gettext \
        --with-mcrypt \
        --with-zlib \
        --with-bz2 \
        --with-zlib \
        --with-mhash \
        --with-pcre-regex \
        --enable-mbstring \
        --enable-inline-optimization \
        --enable-pcntl \
        --enable-mbregex \
        --enable-sockets \
        --enable-sysvmsg \
        --enable-sysvsem \
        --enable-sysvshm \
        --enable-zip \
        --enable-exif \
        --enable-wddx \
        --enable-zip \
        --enable-bcmath \
        --enable-calendar \
        --enable-ftp \
        --enable-soap \
        --enable-sockets \
        --enable-sqlite-utf8 \
        --enable-shmop \
        --enable-dba \
        --disable-debug \
        --disable-rpath
    _failcheck "PHP configure failed. Check requirements."
    make            ;_failcheck "PHP mke failed."
#    make test       ;_failcheck "PHP make test failed."
    make install    ;_failcheck "PHP make install failed."

    _write "Adding PHP to PATH..."
    export PATH="$PATH:/opt/php5/bin:/opt/php5/sbin"

    APPEND='\nif [ -d "/opt/php5/bin" ] && [ -d "/opt/php5/sbin" ];\n\tthen PATH="$PATH:/opt/php5/bin:/opt/php5/sbin"\nfi\n'
    PATTERN='\nif \Q[ -d "/opt/php5/bin" ] && [ -d "/opt/php5/sbin" ];\E\n\t\Qthen PATH="$PATH:/opt/php5/bin:/opt/php5/sbin"\E\nfi\n'
    [ `pcregrep -cM "$PATTERN" /etc/bash.bashrc` -lt 1 ] \
        && echo -e $APPEND | tee -a /etc/bash.bashrc >/dev/null
    unset APPEND
    unset PATTERN
    _writeline " done"

    _write "Creating logrotate entry for PHP-FPM..."
    [ ! -d /var/log/php-fpm ] && mkdir /var/log/php-fpm

    chown -R www-data:www-data /var/log/php-fpm
    echo '/var/log/php-fpm/*.log {
    weekly
    missingok
    rotate 52
    compress
    delaycompress
    notifempty
    create 640 root admin
    sharedscripts
    postrotate
        [ ! -f /var/run/php-fpm.pid ] || kill -USR1 `cat /var/run/php-fpm.pid`
    endscript
}' | tee /etc/logrotate.d/php-fpm >/dev/null
    _writeline " done."

    _write "Removing symbols from compiled php-fpm binary..."
    strip /opt/php5/sbin/php-fpm
    _writeline " done."

    _write "Copying & fixing configuration files..."
    cp -f php.ini-production /opt/php5/etc/php.ini
    chmod 644 /opt/php5/etc/php.ini
    cp -f /opt/php5/etc/php-fpm.conf.default /opt/php5/etc/php-fpm.conf

    [ ! -d /opt/php5/etc/conf.d ] && mkdir /opt/php5/etc/conf.d
    [ -d /etc/php ] && [ ! -L /etc/php ] && rm -rf /etc/php
    [ ! -e /etc/php ] && ln -s /opt/php5/etc /etc/php

    sed -i \
        -e '/^;pid[ \t]*=.*$/ s//pid = \/var\/run\/php-fpm\.pid/' \
        -e '/^;pm.start_servers.*$/ s//pm.start_servers = 5/' \
        -e '/^;pm.min_spare_servers.*$/ s//pm.min_spare_servers = 3/' \
        -e '/^;pm.max_spare_servers.*$/ s//pm.max_spare_servers = 20/' \
        -e '/^;pm.max_requests.*$/ s//pm.max_requests = 500/' \
        /opt/php5/etc/php-fpm.conf

    _writeline " done."
    pause

    _writeline "Creating, fixing & installing php-fpm init.d script..."
    touch /var/run/php-fpm.pid

    cp -f sapi/fpm/init.d.php-fpm /etc/init.d/php-fpm
    chmod 755 /etc/init.d/php-fpm
    sed -i \
        -e '/^prefix=.*$/ s//prefix=\/opt\/php5/' \
        -e '/^php_fpm_PID=.*$/ s//php_fpm_PID=\/var\/run\/php-fpm\.pid/' \
        /etc/init.d/php-fpm

    update-rc.d -f php-fpm remove
    update-rc.d -f php-fpm defaults

    /etc/init.d/php-fpm start
    _failcheck "Could not start php-fpm."

    popd
    pause
}
