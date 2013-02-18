#!/bin/bash
#==============================================================================
# ENTRY: installMySQL
# TEXT: Install MySQL
# CLEANUP: showMySQLWarning
#==============================================================================

MYSQL_TMP_PASSWORD="MYSQL_NOT_INSTALLED"
MYSQL_INSTALLED=0

installMySQL() {
    clear
    _title "Installing MySQL"

    MYSQL_TMP_PASSWORD=`head -c 200 /dev/urandom | tr -cd '[:alnum:]' | head -c 20`
    echo mysql-server-5.1 mysql-server/root_password password $MYSQL_TMP_PASSWORD | debconf-set-selections
    echo mysql-server-5.1 mysql-server/root_password_again password $MYSQL_TMP_PASSWORD | debconf-set-selections

    apt-get -y install mysql-server mysql-client libmysqlclient-dev
    MYSQL_INSTALLED=1

    stop mysql
    pause
}

showMySQLWarning() {
    [ $MYSQL_INSTALLED -eq 1 ] && {
        _writeline "MySQL was installed, but the service is *NOT* running..."
        _writeline "\tRemember to run 'mysql_secure_installation'."
        _writeline "\tYour MySQL password is: '$MYSQL_TMP_PASSWORD'"
    }
}
