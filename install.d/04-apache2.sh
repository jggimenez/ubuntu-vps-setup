#!/bin/bash
#==============================================================================
# ENTRY: installApache2
# TEXT: Install Apache2 (backend for dav_svn) on 8080.
# CLEANUP: showFastCGIVirtualHostConfig
#==============================================================================

installApache2() {
    clear
    _title "Installing Apache2"
    apt-get -y install apache2 libapache2-svn

    echo
    _write "Updating Apache2 configuration..."
    sed -i \
        -e '/[ :]80$/ s/\([ :]\)80$/\18080/' \
        -e '/[ :]443$/ s/\([ :]\)443$/\18443/' \
        /etc/apache2/ports.conf

    sed -i \
        -e '/:80.*$/ s/:80\(.*\)$/:8080\1/' \
        -e '/:443.*$/ s/:443\(.*\)$/:8443\1/' \
        /etc/apache2/sites-available/*

    sed -i \
        -e '/^Timeout .*$/ s//Timeout 45/' \
        -e '/^KeepAliveTimeout .*$/ s//KeepAliveTimeout 5/' \
        /etc/apache2/apache2.conf


#    configureFastCGI
    a2dismod ssl >/dev/null
    a2enmod headers >/dev/null
    _writeline " done."

    echo
    _writeline "Restarting Apache2"
    /etc/init.d/apache2 restart
    pause
}

configureFastCGI() {
    apt-get -y install libapache2-mod-fastcgi

    echo -e '<IfModule mod_fastcgi.c>
    AddHandler php5-fcgi .php
    Action php5-fcgi /php5.fcgi
    Alias /php5.fcgi /var/www/fastcgi/php5.fcgi
    FastCGIExternalServer /var/www/fastcgi/php5.fcgi -host 127.0.0.1:9000 -pass-header Authorization
    <Directory "/var/www/fastcgi">
        Order Deny,Allow
        Deny from All
        <Files "php5.fcgi">
            Order Deny,Allow
            Deny from All
            Allow from env=REDIRECT_STATUS
        </Files>
    </Directory>
</IfModule>' > /etc/apache2/mods-available/fastcgi.conf

    mkdir -p /var/www/fastcgi   # Create folder path for mod_fastcgi

    a2enmod rewrite fastcgi actions >/dev/null
}

showFastCGIVirtualHostConfig() {
    return

	echo "Add the following lines to enable PHP-FPM from Apache2:"
	echo -e "\tAlias /fcgi-bin/ {ROOT_DIR}/fcgi-bin/"
	echo -e "\tFastCGIExternalServer {ROOT_DIR}/fcgi-bin/php-cgi -host 127.0.0.1:9000 -pass-header Authorization"
	echo -e "\tFastCGIExternalServer {ROOT_DIR}/fcgi-bin/php-cgi -socket /var/www/.socket/site.sock"
}
