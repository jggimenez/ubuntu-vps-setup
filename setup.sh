#!/bin/bash
#==============================================================================
# Install a basic system.
#   Based on scripts in install.d
#
# Sources for (01 - 07)
# http://interfacelab.com/nginx-php-fpm-apc-awesome/
# http://www.howtoforge.com/installing-php-5.3-nginx-and-php-fpm-on-ubuntu-debian
# http://www.vladgh.com/blog/installing-firewall
# http://www.vladgh.com/blog/install-nginx-and-php-533-php-fpm-mysql-and-apc
# http://www.corvidworks.com/articles/mail-deliverability-tip
#
# Author:   Jorge Gimenez
# Date:     2010-05-29
# Update:   2011-07-20
#==============================================================================

# Import basic functions
SOURCE_DIR=`dirname $(pwd)/$0`
[ ! -r $SOURCE_DIR/functions.sh ] && {
    echo "Base file \"functions.sh\" not found!"
    exit 1
}

source $SOURCE_DIR/functions.sh

# Is the script running as root?
if [ $(id -u) != "0" ]; then
    __error "ERROR: You must be root to run this script."
    _writeline "Use sudo $0"
    exit 1
fi

# Import all functions & variables from install.d directory.
[ -d $SOURCE_DIR/install.d ] && {
    i=1
    for installFile in `ls -d $SOURCE_DIR/install.d/*.sh`; do
        source $installFile
        ENTRY[i]=`grep ENTRY: $installFile | sed -e '/.*ENTRY:[[:blank:]]/ s///g'`
        TEXT[i]=`grep TEXT: $installFile | sed -e '/.*TEXT:[[:blank:]]/ s///g'`
        [ "`grep -c CLEANUP: $installFile`" != "0" ] && \
            CLEANUP[i]=`grep CLEANUP: $installFile | sed -e '/.*CLEANUP:[[:blank:]]/ s///g'`
        let "i += 1"
    done
}

#==============================================================================

_doCleanup() {
    for element in $(seq 1 $((${#TEXT[@]}))); do
        [ "${CLEANUP[$element]}" != "" ] && ${CLEANUP[$element]}
    done
}
_handler() {
    trap '' HUP INT QUIT ABRT TERM
    _doCleanup
    trap - HUP INT QUIT ABRT TERM
}

showMenu() {
    clear
    showHelp
    [ "$MSG" != "" ] && __error $MSG
    echo -n "Choice: "
}
showHelp() {
    _title "Basic Server Installation" "This machine will be $SERVER@$DOMAIN."

    echo -e "\tN) Change Hostname."
    _writeline "\tF) FULL INSTALL."
    echo -e "\t0) Basic Setup."
    for element in $(seq 1 $((${#TEXT[@]}))); do
        echo -e "\t$element) ${TEXT[$element]}"
    done

    [ "$1" != "false" ] && echo -e  "\tq) Exit."
    echo
}
runChoice() {
    CHOICE=$1
    shift

    case $CHOICE in
        n|N) changeHostname;;
        f|F) fullInstall;;
        0) basicSetup;;
        h) showHelp false;;
        q|Q) break;;
        *) if [ "${TEXT[$CHOICE]}" == "" ]
            then badchoice $CHOICE $@
            else ${ENTRY[$CHOICE]}
        fi
        ;;
    esac

}
badchoice () {
    MSG="Invalid Selection: '$1'."
    if [ "$2" == "false" ]
        then MSG="$MSG Syntax: $0 [--hostname] F | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | A | h"
        else MSG="$MSG Try again..."
    fi
}

basicSetup(){
    clear
    _title "BASIC Server Setup"

    _writeline "Naming server..."

    echo "$SERVER.$DOMAIN" > /etc/hostname
    sed -i '/^[0-2][0-9]*\.[0-2][0-9]*\.[0-2][0-9]*\.[0-2][0-9]*[ \t]*'$SERVER'[ \t]*$/    s/^\([0-2][0-9]*\.[0-2][0-9]*\.[0-2][0-9]*\.[0-2][0-9]*\)[ \t]*'$SERVER'[ \t]*$/\1\t'$SERVER.$DOMAIN"\t"$SERVER'/' /etc/hosts

    id jg >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        _writeline "Creating standard user..."
        adduser jg
        usermod -aG sudo jg
    fi

    _writeline "Securing SSH Server..."
    sed -i \
        -e '/^PermitRootLogin[ \t][ \t]*.*$/ s//PermitRootLogin no/' \
        -e '/^Port[ \t][ \t]*.*$/ s//Port 22000/' \
        -e '/^X11Forwarding[ \t][ \t]*.*$/ s//X11Forwarding no/' \
        -e '/^UsePam[ \t][ \t]*.*$/ s//UsePam no/' \
        -e '/^UseDNS[ \t][ \t]*.*$/ s//UseDNS no/' \
        -e '/^AllowUsers[ \t][ \t]*.*$/ s//AllowUsers jg/' \
        /etc/ssh/sshd_config

    /etc/init.d/ssh restart

    _writeline "Generating locales..."
    /usr/sbin/locale-gen en_US.UTF-8
    /usr/sbin/locale-gen es_VE.UTF-8
    /usr/sbin/locale-gen en_CA.UTF-8
    /usr/sbin/update-locale LANG=en_US.UTF-8

    apt-get update
    apt-get -y dist-upgrade
    _writeline "Installing basic packages..."
    installPostfix
    apt-get -y install \
        wget iptables rsync whiptail \
        psmisc ntp pcregrep subversion dar mutt \
        automake autotools-dev gnu-standards \
        build-essential binutils make gcc patch \
        autoconf autoconf2.13 libtool \
        libpcre3 libpcre3-dev openssl libssl-dev libcurl4-openssl-dev \
        cpp libc6-dev libpopt-dev zlib1g-dev unzip zip\
        libarchive-zip-perl libcompress-zlib-perl \
        locate libxml2-dev libbz2-dev  \
        libmcrypt-dev libmhash-dev libmhash2  libpq-dev \
        libpq5 libevent-dev libmysqlclient-dev \
        libjpeg62-dev libpng3-dev libfreetype6-dev libt1-dev libxslt1-dev \
        libxpm-dev libmagickwand-dev
}
installPostfix() {
    clear
    _title "Installing Postfix"

    #Preseeding some configuration values...
    echo postfix postfix/main_mailer_type select  Internet Site | debconf-set-selections
    echo postfix postfix/mailname string  $SERVER.$DOMAIN | debconf-set-selections
    echo postfix postfix/destinations string  $SERVER.$DOMAIN, localhost.$DOMAIN, , localhost | debconf-set-selections

    apt-get -y install postfix

    sudo /etc/init.d/postfix restart
}

fullInstall () {
    clear
    _title "Installing Everything" "Ctrl-C to abort..."
    pause
    basicSetup

    for element in $(seq 1 $((${#ENTRY[@]}))); do
        ${ENTRY[$element]}
    done

    break
}

#======================================================================
# MAIN LOGIC
#======================================================================
changeHostname() {
    clear
    _title "Basic Server Installation" "Changing hostname"
    _write "Host [server]: "
    read SERVER
    [ "$SERVER" == "" ] && SERVER='server'

    _write "Domain [example.com]: "
    read DOMAIN
    [ "$DOMAIN" == "" ] && DOMAIN='example.com'
}
main() {
    if [ "$1" != "" ]; then
        runChoice $1 false
        if [ "$MSG" != "" ]
            then __error $MSG;
            else _doCleanup
        fi
    else
        while true
        do
            showMenu
            read answer
            MSG=

            runChoice $answer true
        done

        _doCleanup
        _writeline "Goodbye..."
    fi
}

SERVER='server'
DOMAIN='example.com'
MSG=

trap '_handler' HUP INT QUIT ABRT TERM
main "$@"
trap - HUP INT QUIT ABRT TERM
#======================================================================
