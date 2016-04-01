#!/bin/bash

set -x

install_vhd_util () {
  [[ -f /bin/vhd-util ]] && return

  wget --no-check-certificate http://download.cloud.com.s3.amazonaws.com/tools/vhd-util -O /bin/vhd-util
  chmod a+x /bin/vhd-util
}

debconf_packages () {
  echo 'sysstat sysstat/enable boolean true' | debconf-set-selections
  echo "openswan openswan/install_x509_certificate boolean false" | debconf-set-selections
  echo "openswan openswan/install_x509_certificate seen true" | debconf-set-selections
  echo "iptables-persistent iptables-persistent/autosave_v4 boolean true" | debconf-set-selections
  echo "iptables-persistent iptables-persistent/autosave_v6 boolean true" | debconf-set-selections
}

install_packages () {
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
    rsyslog logrotate cron chkconfig insserv net-tools ifupdown vim netbase iptables \
    openssh-server e2fsprogs dhcp3-client tcpdump socat wget \
    python bzip2 sed gawk diffutils grep gzip less tar telnet ftp rsync traceroute psmisc lsof procps \
    inetutils-ping iputils-arping httping  curl \
    dnsutils zip unzip ethtool uuid file iproute acpid virt-what sudo \
    sysstat python-netaddr \
    apache2 ssl-cert \
    dnsmasq dnsmasq-utils \
    nfs-common \
    samba-common cifs-utils \
    xl2tpd bcrelay ppp ipsec-tools tdb-tools \
    openswan=1:2.6.37-3 \
    xenstore-utils libxenstore3.0 \
    conntrackd ipvsadm libnetfilter-conntrack3 libnl-3-200 libnl-genl-3-200 \
    ipcalc \
    openjdk-7-jre-headless \
    iptables-persistent \
    libtcnative-1 libssl-dev libapr1-dev \
    python-flask \
    haproxy \
    radvd \
    sharutils

  ${apt_get} -t wheezy-backports install keepalived irqbalance open-vm-tools

  # hold on installed openswan version, upgrade rest of the packages (if any)
  apt-mark hold openswan
  apt-get update
  apt-get -y --force-yes upgrade

  if [ "${arch}" == "amd64" ]; then
    # XS tools
    wget https://raw.githubusercontent.com/bhaisaab/cloudstack-nonoss/master/xe-guest-utilities_6.5.0_amd64.deb
    dpkg -i xe-guest-utilities_6.5.0_amd64.deb
    rm -f xe-guest-utilities_6.5.0_amd64.deb
  fi
}

return 2>/dev/null || install_packages
