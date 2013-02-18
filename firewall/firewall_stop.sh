#!/bin/bash
# Linux Firewall: Simple Shell Script To Stop and Flush All Iptables Rules
iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X
iptables -t mangle -F
iptables -t mangle -X
iptables -P INPUT ACCEPT
iptables -P OUTPUT ACCEPT
iptables -P FORWARD ACCEPT
echo "Firewall stopped."
