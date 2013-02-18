#!/bin/bash
#==============================================================================
# ENTRY: installPSAD
# TEXT: Install PSAD
#==============================================================================

installPSAD() {
    clear
    _title "Installing PSAD"
    apt-get -y install psad

    sed -i \
        -e '/^EMAIL_ADDRESSES.*$/ s//EMAIL_ADDRESSES             jg@jggimenez.net\;/' \
        -e '/^HOME_NET.*$/ s//HOME_NET                    NOT_USED\;/' \
        -e '/^EXTERNAL_NET.*$/ s//EXTERNAL_NET                any\;/' \
        -e '/^EMAIL_ALERT_DANGER_LEVEL.*$/ s//EMAIL_ALERT_DANGER_LEVEL    5\;/' \
        -e '/^ALERT_ALL.*$/ s//ALERT_ALL                   N\;/' \
        -e '/^ENABLE_AUTO_IDS[ \t][ \t]*.*$/ s//ENABLE_AUTO_IDS             Y\;/' \
        -e '/^AUTO_IDS_DANGER_LEVEL.*$/ s//AUTO_IDS_DANGER_LEVEL       3\;/' \
        -e '/^IPTABLES_BLOCK_METHOD.*$/ s//IPTABLES_BLOCK_METHOD       Y\;/' \
        /etc/psad/psad.conf

    #/etc/init.d/psad start
    pause
}
