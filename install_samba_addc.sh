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
        echo "------------------------------------"
        echo "You need privileges of administrator"
        echo "------------------------------------"

   exit 1
fi 

which apt > /dev/null 2>&1
if [ $? -ne 0 ]
    then
        echo "------------------------------------------"
        echo "Your OS is not compatible with this script"
        echo "------------------------------------------"
        echo

        exit 2
fi
if [ ! -d /etc/netplan/original ]
    then
        mkdir -p /etc/netplan/original
        mv /etc/netplan/*.yaml /etc/netplan/original || mv /etc/netplan/*.yml /etc/netplan/original
    fi
    echo "------------------------------------"
    echo "        NETPLAN CONFIGURE           "
    echo "        Input IP Address            "
    echo "------------------------------------"
    echo
    
    read IP

    echo "------------------------------------"
    echo "Input CIDR"
    echo
    echo "Ex:"
    echo ""
    echo "24 = 255.255.255.0"
    echo "16 = 255.255.0.0"
    echo "8 = 255.0.0."
    echo ""
    echo "------------------------------------"
    echo

    
    echo 

    read CIDR
    
    if [ $CIDR -gt 32 -o $CIDR -lt 0 ]
    	then
		echo
		echo "------------------------------------"
		echo "Prefix out of range"
		echo "------------------------------------"
		echo
        exit 3
    fi

    echo "------------------------------------"
    echo "           Input GATEWAY"
    echo "------------------------------------"

    read GATEWAY

    echo "------------------------------------"
    echo "           Input DNS1"
    echo "------------------------------------"

    read DNS1

    echo "------------------------------------"
    echo "           Input DNS2"
    echo "------------------------------------"

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
    echo "------------------------------------"
    echo "Checking internet connection"
    echo "------------------------------------"
    echo

    ping -c 4 8.8.8.8

    sleep 2

    clear

    echo "------------------------------------"
    echo "IP ADDRESS CONFIGURED"
    echo "------------------------------------"
    echo

    #networkctl status

    sleep 2
    
    echo "------------------------------------"
    echo "------------------------------------"
    echo "------ UPDATING REPOSITORIES -------"
    echo "------------------------------------"
    echo "------------------------------------"
    
    apt update && apt upgrade -y
    
    sleep 10

    echo "------------------------------------"
    echo "------------------------------------"
    echo "Starting installation of SAMBA4"
    echo "------------------------------------"
    echo "------------------------------------"

    echo "------------------------------------"
    echo "Adjusting date and time"
    echo "------------------------------------"

    timedatectl set-timezone America/Sao_Paulo

    apt install ntp ntpdate -y

    service ntp stop

    ntpdate a.st1.ntp.br

    service ntp start

    sleep 5

    clear

    echo "----------------------------------------"
    echo "----------------------------------------"
    echo "Generating dependencies for installation"
    echo " !!! IGNORE KERBEROS CONFIGURATION !!!  "
    echo "----------------------------------------"
    echo "----------------------------------------"
    
    sleep 10
    
    apt-get install wget acl attr autoconf bind9utils bison build-essential debhelper dnsutils docbook-xml docbook-xsl flex gdb libjansson-dev krb5-user libacl1-dev libaio-dev libarchive-dev libattr1-dev libblkid-dev libbsd-dev libcap-dev libcups2-dev libgnutls28-dev libgpgme-dev libjson-perl libldap2-dev libncurses5-dev libpam0g-dev libparse-yapp-perl libpopt-dev libreadline-dev nettle-dev perl pkg-config python-all-dev python2-dbg python-dev-is-python2 python3-dnspython python3-gpg python3-markdown python3-dev xsltproc zlib1g-dev liblmdb-dev lmdb-utils libsystemd-dev perl-modules-5.30 libdbus-1-dev libtasn1-bin -y 
    
    sleep 2
    
    apt-get -y autoremove
    apt-get -y autoclean
    apt-get -y clean 

    sleep 2

    clear

    echo "------------------------------------"
    echo "Preparing SAMBA4"
    echo "------------------------------------"

    cd /usr/src/

    wget -c $link_pack_samba
    
    sleep 2

    tar -xf $pack_samba
    
    sleep 10

    cd $dir_unpack_samba

    echo "-------------------------------------"
    echo "Configuring SAMBA 01/03 - systemd fhs"
    echo "-------------------------------------"

    ./configure --with-systemd --prefix=/usr/local/samba --enable-fhs

    sleep 30

    clear

    echo "--------------------------------------"
    echo "Configuring SAMBA 02/03 - make install"
    echo "--------------------------------------"

    make && make install

    sleep 10

    clear

    echo "------------------------------------"
    echo "Configuring SAMBA 03/03 - path"
    echo "------------------------------------"

    echo "PATH=$PATH:/usr/local/samba/bin:/usr/local/samba/sbin" >> /root/.bashrc

    source /root/.bashrc

    cp -v /usr/src/samba-4.14.7/bin/default/packaging/systemd/samba.service /etc/systemd/system/samba-ad-dc.service

    mkdir -v /usr/local/samba/etc/sysconfig

    echo 'SAMBAOPTIONS="-D"' > /usr/local/samba/etc/sysconfig/samba

    systemctl daemon-reload

    systemctl enable samba-ad-dc.service

    sleep 10

    clear

    echo "------------------------------------"
    echo "Starting Provisioning"
    echo "------------------------------------"

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
    
    netplan apply

    echo 
    echo "------------------------------------"
    echo "Checking internet connection"
    echo "------------------------------------"
    echo

    ping -c 4 8.8.8.8

    sleep 2

    clear
    
    echo "------------------------------------"
    echo "Configuring ADDC"
    echo
    echo "Input FQDN"
    echo "Ex.: addc01.company.local"
    echo "------------------------------------"
    
    read FQDN

    echo "------------------------------------"
    echo "Input NetBIOS"
    echo "Ex.: addc01"
    echo "hostname must not to be equal HOSTNAME"
    echo "use FQDN without PREFIX"
    echo "ex.: FQDN - addc01.intra"
    echo "FQDN remove PREFIX -> addc01"
    echo "------------------------------------"

    read NETBIOS

    echo "------------------------------------"
    echo "Input hostname"
    echo "Ex.: serveraddc"
    echo "hostname must not to be equal NetBIOS"
    echo "------------------------------------"

    read HOSTNAME

    echo "
    127.0.0.0 localhost
    $IP $FQDN $HOSTNAME" > /etc/hosts

    echo "
    $HOSTNAME" > /etc/hostname

    samba-tool domain provision --use-rfc2307 --domain=$NETBIOS --realm=$FQDN
	
    rm /etc/krb5.conf

    cp -bv /usr/local/samba/var/lib/samba/private/krb5.conf /etc/krb5.conf

    sleep 2
    
    FQDN=${FQDN,,}
    
    echo "
        [global]
            dns forwarder = 8.8.8.8
            netbios name = $NETBIOS
            realm = $FQDN
            server role = active directory domain controller
            workgroup = $NETBIOS
            idmap_ldb:use rfc2307 = yes
            ldap server require strong auth = No

        [netlogon]
            path = /usr/local/samba/var/lib/samba/${FQDN}/scripts
            read only = No

        [sysvol]
            path = /usr/local/samba/var/lib/samba/sysvol
            read only = No
        " > /usr/local/samba/etc/samba/smb.conf

    systemctl start samba-ad-dc.service

    echo "
        +------------------------------------+
        |       SAMBA SERVICE INSTALLED      |    
        +------------------------------------+
        
	
	FQND - $FQDN -> To connect on Active Directory.
	
	HOSTNAME - $HOSTNAME 
	
	NETBIOS - $NETBIOS -> To configure chgrp file server.
	
	
	
        "
    echo
