#!/bin/bash
# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

set -e
set -x

function install_vhd_util() {
  [[ -f /bin/vhd-util ]] && return

  wget --no-check-certificate http://download.cloud.com.s3.amazonaws.com/tools/vhd-util -O /bin/vhd-util
  chmod a+x /bin/vhd-util
}

function debconf_packages() {
#TODO Check these configs.
  echo 'sysstat sysstat/enable boolean true' | debconf-set-selections
  echo "openswan openswan/install_x509_certificate boolean false" | debconf-set-selections
  echo "openswan openswan/install_x509_certificate seen true" | debconf-set-selections
  echo "iptables-persistent iptables-persistent/autosave_v4 boolean true" | debconf-set-selections
  echo "iptables-persistent iptables-persistent/autosave_v6 boolean true" | debconf-set-selections
}

function install_packages() {
  DEBIAN_FRONTEND=noninteractive
  DEBIAN_PRIORITY=critical
  local arch=`dpkg --print-architecture`

  debconf_packages
  install_vhd_util

  local apt_get="apt-get --no-install-recommends -q -y --force-yes"

  #32 bit architecture support:: not required for 32 bit template
  if [ "${arch}" != "i386" ]; then
    dpkg --add-architecture i386
    apt-get update
    ${apt_get} install links:i386 libuuid1:i386 libc6:i386
  fi

  ${apt_get} install \
rsyslog #Installed
logrotate #Installed
cron #Installed
chkconfig #Use systemd in Debian 8.1
insserv #Installed
net-tools #Installed
ifupdown #Installed
vim-tiny #Installed
netbase #Installed
iptables #Installed
openssh-server #Installed
e2fsprogs #Installed
dhcp3-client #Installed => isc-dhcp-client
tcpdump #Never used
socat #Added to preseed
wget #Installed
python #Installed
bzip2 #Added to preseed
sed #Installed
gawk #Installed => mawk /never used
diffutils #Installed
grep #Installed
gzip #Installed
less #Installed
tar #Installed
telnet #Never used
ftp #Added to preseed
rsync #Never used
traceroute #Installed
psmisc #Installed
lsof #Never used
procps #Installed
inetutils-ping #Installed => iputils-ping
iputils-arping #Added to preseed
httping #Never used
curl #Added to preseed
dnsutils #Never used
zip #Added to preseed
unzip #Added to preseed
ethtool #Never used
uuid #Installed
file #Problem?
iproute #Installed iproute2
acpid #Installed
virt-what #Added to preseed
sudo #Installed
sysstat #Never used
python-netaddr #Added to preseed
apache2 #Added to preseed -> disabled in cleanup.
ssl-cert #Never used
dnsmasq #Added to preseed
dnsmasq-utils #Added to preseed
nfs-common #Added to preseed
samba-common #Never used
cifs-utils #Added to preseed
xl2tpd #Added to preseed
bcrelay #Never used
ppp #Installed
ipsec-tools #Added to preseed
tdb-tools #Added to preseed \
openswan=1:2.6.37-3 #Added to preseed -> strongswan
xenstore-utils #Added to preseed
libxenstore3.0 #Added to preseed
conntrackd #Added to preseed
ipvsadm #Added to preseed
libnetfilter-conntrack3 #Added to preseed
libnl-3-200 #Installed with ipvsadm
libnl-genl-3-200 #Installed with ipvsadm
ipcalc #Never used
openjdk-7-jre-headless #Added to preseed -> openjdk-8-jre-headless
iptables-persistent #Added to preseed
libtcnative-1 #Never used?
libssl-dev #Added to preseed
libapr1-dev #Added to preseed
python-flask #Added to preseed
haproxy #Added to preseed
radvd #Added to preseed
sharutils #Never used? -> For sysvm template creation.

  ${apt_get} -t wheezy-backports install 
keepalived #Never used
irqbalance #Never used / unnecesarry
open-vm-tools #Never used

  # hold on installed openswan version, upgrade rest of the packages (if any)
  apt-mark hold openswan
  apt-get update
  apt-get -y --force-yes upgrade

  if [ "${arch}" == "amd64" ]; then
    # Hyperv  kvp daemon - 64bit only
    # Download the hv kvp daemon
    wget http://people.apache.org/~rajeshbattala/hv-kvp-daemon_3.1_amd64.deb
    dpkg -i hv-kvp-daemon_3.1_amd64.deb
    rm -f hv-kvp-daemon_3.1_amd64.deb
    # XS tools
    wget https://raw.githubusercontent.com/bhaisaab/cloudstack-nonoss/master/xe-guest-utilities_6.5.0_amd64.deb
    dpkg -i xe-guest-utilities_6.5.0_amd64.deb
    rm -f xe-guest-utilities_6.5.0_amd64.deb
  fi
}

return 2>/dev/null || install_packages
