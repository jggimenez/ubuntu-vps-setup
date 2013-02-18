#!/bin/bash
#==============================================================================
# ENTRY: installFirewall
# TEXT: Install Custom Firewall Script
#
# SRC: http://www.vladgh.com/blog/installing-firewall
#==============================================================================

installFirewall() {
    TEMPLATE=$SOURCE_DIR/firewall
    if [ ! -f $TEMPLATE/firewall_start.sh ] \
        || [ ! -f $TEMPLATE/firewall_stop.sh ] \
        || [ ! -f $TEMPLATE/firewall_initd_script ]
    then
        _failcheck "Custom firewall scripts not found!"
    fi

    clear
    _title "Installing custom firewall script"

    INSTALL_DIR=/srv/scripts/firewall
    #PUBLIC_IP=$(ifconfig eth0 | awk -F: '/inet addr:/ {print $2}' | awk '{ print $1 }')
    PUBLIC_IP=$(ifconfig venet0:0 | awk -F: '/inet addr:/ {print $2}' | awk '{ print $1 }')

    ESCAPED_INSTALL_DIR=$(echo $INSTALL_DIR | sed -e 's/\\/\\\\/g' -e 's/\//\\\//g' -e 's/&/\\\&/g')
    ESCAPED_PUBLIC_IP=$(echo $PUBLIC_IP | sed -e 's/\./\\\./g')

    [ ! -d $INSTALL_DIR ] && mkdir -p $INSTALL_DIR
    cp $TEMPLATE/firewall_start.sh $INSTALL_DIR/
    cp $TEMPLATE/firewall_stop.sh $INSTALL_DIR/
    cp $TEMPLATE/firewall_initd_script /etc/init.d/firewall

    [ ! -f $INSTALL_DIR/badips.list ] && touch $INSTALL_DIR/badips.list

    sed -i \
        -e '/INSTALL_DIR/ s//'$ESCAPED_INSTALL_DIR'/g' \
        -e '/EXTERNAL_IP_ADDRESS$/ s//'$ESCAPED_PUBLIC_IP'/' \
        $INSTALL_DIR/firewall_start.sh

    sed -i -e '/INSTALL_DIR/ s//'$ESCAPED_INSTALL_DIR'/' /etc/init.d/firewall

    chmod +x $INSTALL_DIR/firewall_start.sh
    chmod +x $INSTALL_DIR/firewall_stop.sh
    chmod +x /etc/init.d/firewall

    update-rc.d -f firewall remove
    update-rc.d -f firewall defaults

    /etc/init.d/firewall start
    pause
}
