#!/bin/bash
#==============================================================================
# ENTRY: installPHPExtension
# TEXT: Install PHP Extension: APC, Memcache, Imagick
#==============================================================================

installPHPExtension() {
    if [ ! -f /opt/php5/bin/phpize ]; then
        MSG="Can not install PHP extensions until PHP is installed."
        return 1
    fi

    clear
    _title "Installing PHP Extensions"

    [ `echo $PATH | grep -c "/opt/php5"` -lt 1 ] \
        && source /etc/bash.bashrc \
        && source ~/.bashrc

    pushd .
    cd /usr/local/src/

    _writeline "Installing PHP Extensions (Memcache, APC, Imagick)"

    #Enable memcache session handler support? [yes] :
    printf "yes\n" | pecl install memcache
    _failcheck "MEMCACHE pecl failed."

    #Enable per request file info about files used from the APC cache [no] :
    #Enable spin locks (EXPERIMENTAL) [no] :
    printf "no\nno\n" | pecl install apc-beta
    _failcheck "APC pecl failed."

    [ -f /opt/php5/etc/conf.d/memcache.ini ]    && :> /opt/php5/etc/conf.d/memcache.ini
    [ -f /opt/php5/etc/conf.d/apc.ini ]         && :> /opt/php5/etc/conf.d/apc.ini

    echo -e 'extension = memcache.so\n' > /opt/php5/etc/conf.d/memcache.ini
#apc.num_files_hint=1024
    echo -e'extension = apc.so
apc.enabled = 1
apc.shm_size = 64M
apc.rfc1867 = on
apc.write_lock = 1
apc.ttl=7200
apc.user_ttl=7200
apc.mmap_file_mask=/tmp/apc.XXXXXX
apc.enable_cli=0\n' > /opt/php5/etc/conf.d/apc.ini

    _writeline "PHP Extensions installed & configured"

    /etc/init.d/php-fpm reload

    popd
    pause
}
