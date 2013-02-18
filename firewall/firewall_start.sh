#!/bin/bash
# A Linux Shell Script with common rules for IPTABLES Firewall.
# VladGh.com.
# -------------------------------------------------------------------------

IPT="/sbin/iptables"
#PUB_IF="eth0"
[ -f INSTALL_DIR/badips.list ] && BADIPS=$(grep -v -E "^#|^$" INSTALL_DIR/badips.list)

echo "Starting IPv4 Wall..."
$IPT -F
$IPT -X
$IPT -t nat -F
$IPT -t nat -X
$IPT -t mangle -F
$IPT -t mangle -X

# Counter
$IPT -I INPUT -d 127.0.0.1
$IPT -I OUTPUT -s 127.0.0.1
$IPT -I INPUT -d EXTERNAL_IP_ADDRESS
$IPT -I OUTPUT -s EXTERNAL_IP_ADDRESS

#unlimited
$IPT -A INPUT -i lo -j ACCEPT
$IPT -A OUTPUT -o lo -j ACCEPT

# block all bad ips
echo "Blocking bad ips..."
for ip in $BADIPS; do
	$IPT -A INPUT -s $ip -j DROP
done

# sync
$IPT -A INPUT -p tcp ! --syn -m state --state NEW  -m limit --limit 5/m --limit-burst 7 -j LOG --log-level 4 --log-prefix "IPT -- Drop Syn - "
$IPT -A INPUT -p tcp ! --syn -m state --state NEW -j DROP

# Fragments
$IPT -A INPUT -f  -m limit --limit 5/m --limit-burst 7 -j LOG --log-level 4 --log-prefix "IPT -- Fragments Packets - "
$IPT -A INPUT -f -j DROP

# block bad stuff
$IPT  -A INPUT -p tcp --tcp-flags ALL FIN,URG,PSH -j DROP
$IPT  -A INPUT -p tcp --tcp-flags ALL ALL -j DROP

$IPT  -A INPUT -p tcp --tcp-flags ALL NONE -m limit --limit 5/m --limit-burst 7 -j LOG --log-level 4 --log-prefix "IPT -- NULL Packets - "
$IPT  -A INPUT -p tcp --tcp-flags ALL NONE -j DROP # NULL packets

$IPT  -A INPUT -p tcp --tcp-flags SYN,RST SYN,RST -j DROP

$IPT  -A INPUT -p tcp --tcp-flags SYN,FIN SYN,FIN -m limit --limit 5/m --limit-burst 7 -j LOG --log-level 4 --log-prefix "IPT -- XMAS Packets - "
$IPT  -A INPUT -p tcp --tcp-flags SYN,FIN SYN,FIN -j DROP #XMAS

$IPT  -A INPUT -p tcp --tcp-flags FIN,ACK FIN -m limit --limit 5/m --limit-burst 7 -j LOG --log-level 4 --log-prefix "IPT -- Fin Packets Scan - "
$IPT  -A INPUT -p tcp --tcp-flags FIN,ACK FIN -j DROP # FIN packet scans

$IPT  -A INPUT -p tcp --tcp-flags ALL SYN,RST,ACK,FIN,URG -j DROP

# Allow full outgoing connection but no incomming stuff
$IPT -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
$IPT -A OUTPUT -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT

# Allow Ports:
$IPT -A INPUT -p tcp --destination-port 22 -j ACCEPT
$IPT -A INPUT -p tcp --destination-port 22000 -j ACCEPT
$IPT -A INPUT -p tcp --destination-port 80 -j ACCEPT
$IPT -A INPUT -p tcp --destination-port 443 -j ACCEPT

# allow incoming ICMP ping pong stuff
$IPT -A INPUT -p icmp --icmp-type 8 -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
$IPT -A OUTPUT -p icmp --icmp-type 0 -m state --state ESTABLISHED,RELATED -j ACCEPT

# No smb/windows sharing packets - too much logging
$IPT -A INPUT -p tcp --dport 137:139 -j REJECT
$IPT -A INPUT -p udp --dport 137:139 -j REJECT

# Log everything else
# *** Required for psad ****
$IPT -A INPUT -j LOG --log-level 4 --log-prefix "IPT -- Input Traffic - "
$IPT -A FORWARD -j LOG --log-level 4 --log-prefix "IPT -- Forward Traffic - "
#$IPT -A INPUT -j DROP
#$IPT -A FORWARD -j DROP

# DROP all incomming traffic
$IPT -P INPUT DROP
# $IPT -P OUTPUT DROP
$IPT -P FORWARD DROP


echo "Firewall started"
exit 0
