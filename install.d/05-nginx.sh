#!/bin/bash
#==============================================================================
# ENTRY: installNGINX
# TEXT: Install NGINX (from source)
#==============================================================================

installNGINX() {
    NGINX_V=1.2.6
    TEMPLATE=$SOURCE_DIR/nginx
#    UPGRADE=="`[ -x /opt/nginx/sbin/nginx ]; echo "$?"`"

    if [ ! -f $TEMPLATE/nginx.conf ] \
        || [ ! -f $TEMPLATE/fastcgi_params ] \
        || [ ! -f $TEMPLATE/nginx_initd_script ]
    then
        _failcheck "Custom NGINX scripts not found!"
    fi

    clear
    _title "Compiling & Installing NGINX"

    apt-get -y install build-essential binutils make gcc patch \
        autoconf autoconf2.13 \
        libpcre3 libpcre3-dev openssl libssl-dev libcurl4-openssl-dev \
        cpp libc6-dev libpopt-dev zlib1g-dev unzip zip\
        libarchive-zip-perl libcompress-zlib-perl \
        libtool

    pushd .
    cd /usr/local/src/

    ##==================================================
    ##Download necesary files for NGINX
    ##==================================================
    _writeline "Checking & downloading files if needed..."
    [ ! -f nginx-$NGINX_V.tar.gz ] && \
        wget http://nginx.org/download/nginx-$NGINX_V.tar.gz

    _write "Deleting working directory... "
    [ -d nginx-$NGINX_V ] \
        && [ ! -L nginx-$NGINX_V ] \
        && rm -rf nginx-$NGINX_V
    _writeline " done."

    ##==================================================
    ##Extract necesary files for NGINX
    ##==================================================
    _write "Extracting files..."
    tar xzf nginx-$NGINX_V.tar.gz
    _writeline " done"

    cd nginx-$NGINX_V/
    ./configure --prefix=/opt/nginx \
        --conf-path=/etc/nginx/nginx.conf \
        --user=www-data \
        --group=www-data \
        --http-log-path=/var/log/nginx/access.log \
        --error-log-path=/var/log/nginx/error.log \
        --pid-path=/var/run/nginx.pid \
        --lock-path=/var/lock/nginx.lock \
        --with-http_stub_status_module \
        --with-http_flv_module \
        --with-http_ssl_module \
        --with-http_gzip_static_module \
        --with-http_realip_module \
        --with-http_sub_module \
        --without-mail_pop3_module \
        --without-mail_imap_module \
        --without-mail_smtp_module

    _failcheck "NGINX configure failed. Check requirements."
    make            ;_failcheck "NGINX make failed."
    make install    ;_failcheck "NGINGX make install failed."

    _write "Creating logrotate entry for nginx..."
    [ ! -d /var/log/nginx ] && mkdir /var/log/nginx

    chown -R root:admin /var/log/nginx
    echo '/var/log/nginx/*.log {
    daily
    missingok
    rotate 52
    compress
    delaycompress
    notifempty
    create 640 root admin
    sharedscripts
    postrotate
        [ ! -f /var/run/nginx.pid ] || kill -USR1 `cat /var/run/nginx.pid`
    endscript
}' | tee /etc/logrotate.d/nginx >/dev/null
    _writeline " done."

    _writeline "Copying & fixing configuration files..."
    [ ! -d /etc/nginx/conf.d ]          && mkdir -p /etc/nginx/conf.d
    [ ! -d /etc/nginx/sites-available ] && mkdir -p /etc/nginx/sites-available
    [ ! -d /etc/nginx/sites-enabled ]   && mkdir -p /etc/nginx/sites-enabled

    #NO OVERWRITE OF EXISTING FILES...
    if [ -f /etc/nginx/nginx.conf ]; then
        diff /etc/nginx/nginx.conf $TEMPLATE/nginx.conf >/dev/null
        [ $? -ne 0 ] && {
            newFile="nginx_`date +%F`.conf"
            _writeline "\tArchiving new \"nginx.conf\" to \"$newFile\"..."
            cp -f $TEMPLATE/nginx.conf    /etc/nginx/$newFile
        }
    fi

    #NO OVERWRITE OF EXISTING FILES...
    if [ -f /etc/nginx/fastcgi_params ];then
        diff /etc/nginx/fastcgi_params $TEMPLATE/fastcgi_params >/dev/null
        [ $? -ne 0 ] && {
            newFile="fastcgi_params_`date +%F`"
            _writeline "\tArchiving new \"fastcgi_params\" to \"$newFile\"..."
            cp -f $TEMPLATE/fastcgi_params    /etc/nginx/$newFile
        }
    fi

    _writeline " done."
    pause

    _writeline "Creating, fixing & installing nginx init.d script..."
    touch /var/run/nginx.pid

    cp -f $TEMPLATE/nginx_initd_script /etc/init.d/nginx
    chmod 755 /etc/init.d/nginx

    update-rc.d -f nginx remove
    update-rc.d -f nginx defaults

    /etc/init.d/nginx start
    _failcheck "Could not start NGINX."

    popd
    pause
}
