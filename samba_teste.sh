#!/bin/bash

# author: Wesley Marques
# describe: Instalar e configurar SAMBA4 para ADDC
# version: 0.1
# license: MIT License

link_pack_samba="https://download.samba.org/pub/samba/stable/samba-4.14.7.tar.gz"
pack_samba="samba-4.14.7.tar.gz"
dir_unpack_samba="samba-4.14.7"

clear

    # CONS
    NICKNAME=$(ip address show | grep -w 2 | awk '{print $2}')

    if [ $USER != 'root' ]
    then
        echo "You need privileges of administrator"
        echo

        exit 1
    fi 

    which apt > /dev/null 2>&1

    if [ $? -ne 0 ]
    then
        echo "Your OS is not compatible with this script"
        echo

        exit 2
    fi

    if [ ! -d /etc/netplan/original ]
    then
        mkdir -p /etc/netplan/original
        mv /etc/netplan/*.yaml /etc/netplan/original || mv /etc/netplan/*.yml /etc/netplan/original
    fi
    
    echo "NETPLAN CONFIGURE"
    echo "Input IP Address"
    echo
    
    read IP

    echo "Input CIDR"
    echo
    echo "Ex:"
    echo ""
    echo "24 = 255.255.255.0"
    echo "16 = 255.255.0.0"
    echo "8 = 255.0.0."
    echo ""
    
    echo 

    read CIDR

    if [ $CIDR -gt 32 -o $CIDR -lt 0 ]
    then
        echo
        echo "Prefix out of range"
        echo

        exit 3
    fi

    echo "Input GATEWAY"

    read GATEWAY

    echo "Input DNS1"

    read DNS1

    echo "Input DNS2"

    read DNS2

    echo "
# This file describes the network interfaces available on your system
# For more information, see netplan(5).
network:
  version: 2
  renderer: networkd
  ethernets:
    $NICKNAME
       dhcp4: no
       dhcp6: no
       addresses: [$IP/$CIDR]
       gateway4: $GATEWAY
       nameservers:
           addresses: [$DNS1,$DNS2]" > /etc/netplan/01-netcfg.yaml
    echo
    echo "checking file syntax"

    netplan --debug generate > /dev/null 2>&1

    if [ $? -ne 0 ]
    then
        echo
        echo "Error of sintax"
        echo

        exit 4

    else
        echo
            netplan apply

        echo "Done"
    fi

    echo 
    echo "Checking internet connection"
    echo

    ping -c 4 8.8.8.8

    sleep 2

    clear

    echo "IP ADDRESS CONFIGURED"
    echo

    networkctl status

    sleep 2

    echo "Starting installation of SAMBA4"

    echo "Adjusting date and time"

    timedatectl set-timezone America/Sao_Paulo

    apt install ntp ntpdate -y

    service ntp stop

    ntpdate a.st1.ntp.br

    service ntp start

    sleep 2

    echo "Generating dependencies for installation"
    echo "!!! IGNORE KERBEROS CONFIGURATION !!!"
    
    apt-get install wget acl attr autoconf bind9utils bison build-essential debhelper dnsutils docbook-xml docbook-xsl flex gdb libjansson-dev krb5-user libacl1-dev libaio-dev libarchive-dev libattr1-dev libblkid-dev libbsd-dev libcap-dev libcups2-dev libgnutls28-dev libgpgme-dev libjson-perl libldap2-dev libncurses5-dev libpam0g-dev libparse-yapp-perl libpopt-dev libreadline-dev nettle-dev perl pkg-config python-all-dev python2-dbg python-dev-is-python2 python3-dnspython python3-gpg python3-markdown python3-dev xsltproc zlib1g-dev liblmdb-dev lmdb-utils libsystemd-dev perl-modules-5.30 libdbus-1-dev libtasn1-bin -y 

    apt-get -y autoremove 
	apt-get -y autoclean 
	apt-get -y clean 

    sleep 2

    clear

    echo "Preparing SAMBA4"

    cd /usr/src/

    wget -c $link_pack_samba

    tar -xf $pack_samba

    cd $dir_unpack_samba

    echo "Configuring SAMBA 01/03 - systemd fhs"

    ./configure --with-systemd --prefix=/usr/local/samba --enable-fhs

    sleep 2

    clear

    echo "Configuring SAMBA 02/03 - make install"

    make && make install

    sleep 2

    clear

    echo "Configuring SAMBA 03/03 - path"

    echo "PATH=$PATH:/usr/local/samba/bin:/usr/local/samba/sbin" >> /root/.bashrc

    source /root/.bashrc

    cp -v /usr/src/samba-4.14.7/bin/default/packaging/systemd/samba.service /etc/systemd/system/samba-ad-dc.service

    mkdir -v /usr/local/samba/etc/sysconfig

    echo 'SAMBAOPTIONS="-D"' > /usr/local/samba/etc/sysconfig/samba

    systemctl daemon-reload

    systemctl enable samba-ad-dc.service

    sleep 2

    clear

    echo "Starting Provisioning"

    systemctl stop systemd-resolved.service

    systemctl disable systemd-resolved.service

    echo "
    # This file describes the network interfaces available on your system
    # For more information, see netplan(5).
    network:
    version: 2
    renderer: networkd
    ethernets:
        $NICKNAME
        dhcp4: no
        dhcp6: no
        addresses: [$IP/$CIDR]
        gateway4: $GATEWAY
        nameservers:
            addresses: [$IP]" > /etc/netplan/01-netcfg.yaml
        echo
        echo "checking file syntax"

        netplan --debug generate > /dev/null 2>&1

        if [ $? -ne 0 ]
        then
            echo
            echo "Error of sintax"
            echo

            exit 4

        else
            echo
                netplan apply

            echo "Done"
        fi

    echo 
    echo "Checking internet connection"
    echo

    ping -c 4 8.8.8.8

    sleep 2

    clear
    
    echo "Configuring ADDC"
    echo
    echo "Input FQDN"
    echo "Ex.: addc01.company.local"
    
    read FQDN

    echo "Input NetBIOS"
    echo "Ex.: addc01"

    read NETBIOS

    echo "Input hostname"
    echo "Ex.: serveraddc"

    read HOSTNAME

    echo "
    127.0.0.0 localhost
    $IP $FQDN $HOSTNAME" > /etc/hosts

    echo "
    $HOSTNAME" > /etc/hostname

    samba-tool domain provision --use-rfc2307 --domain=$NETBIOS --realm=$FQDN

    cp -bv /usr/local/samba/var/lib/samba/private/krb5.conf /etc/krb5.conf

    sleep 2

    echo "Set Password for Samba Administrator"

    read PWSAMBA

    if [ $PWSAMBA -ne 0 ]
        then
            echo
            echo "Error of sintax"
            echo

            exit 4

        else
            echo

                samba-tool user setpassword administrator $PWSAMBA

            echo "Done"
        fi

    systemctl start samba-ad-dc.service

    echo "SAMBA ACTIVE DIRECTORY OK"
    
    clear    

