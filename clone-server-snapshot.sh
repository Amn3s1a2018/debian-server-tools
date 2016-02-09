#!/bin/bash --version
#
# Clone a Debian-based server by a snapshot.
#

exit 0

# On the "donor" before snapshoting
# Switch to DHCP
cp -a /etc/network/interfaces /etc/network/interfaces.clone
cp -a /etc/resolv.conf /etc/resolv.conf.clone
editor /etc/network/interfaces
apt-get install isc-dhcp-client isc-dhcp-common
ifdown eth0 && ifup eth0
# Revert after snapshoting
mv -f /etc/network/interfaces.clone /etc/network/interfaces
ifdown eth0 && ifup eth0
apt-get purge isc-dhcp-client isc-dhcp-common
mv -f /etc/resolv.conf.clone /etc/resolv.conf


# On the "clone"
# IP address
editor /etc/network/interfaces
rm -f /etc/network/interfaces.clone
ifdown eth0 && ifup eth0
apt-get purge isc-dhcp-client isc-dhcp-common
mv -f /etc/resolv.conf.clone /etc/resolv.conf

# Hostname
# See: ${D}/debian-setup.sh

# DNS A
host -t A "$H"

# DNS PTR
host -t PTR "$IP"

# DNS MX
host -t MX "$H"

# SSH host keys (needs new hostname)
rm -vf /etc/ssh/ssh_host_*
dpkg-reconfigure -f noninteractive openssh-server

# Server data
editor /root/server.yml

# Cron jobs
mc /etc/ /etc/cron.d/

# Courier MTA
editor /etc/courier/me
host -t MX $(cat /etc/courier/me)
editor /etc/courier/defaultdomain
editor /etc/courier/dsnfrom
editor /etc/courier/aliases/system
editor /etc/courier/aliases/system-user
courier-restart.sh

# Add clone on the smart host !!!
#     alias
#     smtpaccess

# Apache "prg" site URL

# Reconfigure other services

# When finished
reboot

# @TODO Develop dpkg-way