#!/bin/bash

# author: Wesley Marques
# describe: Instalar e configurar SAMBA4 para ADDC
# version: 0.1
# license: MIT License

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

    #networkctl status

    sleep 2

    echo 
        "
        +---------------------------------+
        |      Adjusting date and time    |    
        +---------------------------------+
        "

    timedatectl set-timezone America/Sao_Paulo

    apt install ntp ntpdate -y

    service ntp stop

    ntpdate a.st1.ntp.br

    service ntp start

    sleep 2

    clear

    echo 
        "
        +----------------------------------------------------+
        |      Starting installation of SAMBA4 & KERBEROS    |    
        +----------------------------------------------------+
        "

    apt install samba samba-libs smbclient winbind -y

    systemctl enable smbd.service nmbd.service

    apt install krb5-user libnss-winbind libwbclient0 -y

    echo
        "
        +---------------------------------+
        |         Input FQDN Company      |    
        +---------------------------------+
        Ex.: addc01.intra
        "
    echo
    
    read FQDN

    echo
        "
        [libdefaults]
            default_realm = $FQDN
            dns_lookup_realm = false
            dns_lookup_kdc = true" > /etc/krb5.conf

    echo
        "
        +-----------------------------+
        |         Input hostname      |    
        +-----------------------------+
        Ex.: serveraddc01
        "
    echo
    
    read HOSTNAME

     echo
        "
        +--------------------------+
        |       Input NetBIOS      |    
        +--------------------------+
        Ex.: addc01
        "
    echo
    
    read NETBIOS

     echo
        "
        +------------------------------+
        |       Input folder name      |    
        +------------------------------+
        Ex.: FILES
        "
    echo
    
    read DIRECTORY

    mkdir -v -m 1770 /$DIRECTORY

    echo
        "
        [global]
            security = ads
            realm = $FQDN
            workgroup = $HOSTNAME
            idmap uid = 10000-15000
            idmap gid = 10000-15000
            winbind enum users = yes
            winbind enum groups = yes
            template homedir = /home/%D/%U
            template shell = /bin/bash
            client use spnego = yes
            winbind use default domain = yes
            restrict anonymous = 2
            winbind refresh tickets = yes

        [$DIRECTORY]
            writeable = yes
            path = /$DIRECTORY
            read only = no" > /etc/samba/smb.conf

     echo "
    127.0.0.0 localhost
    $IP $FQDN $HOSTNAME" > /etc/hosts

    echo "
    $HOSTNAME" > /etc/hostname

    systemctl start smbd.service nmbd.service

    sleep 2

    clear

    echo
        "
        +------------------------------------+
        |       SAMBA SERVICE INSTALLED      |
        |                                    |
        |     \ \ $FQDN \ $DIRECTORY         |    
        +------------------------------------+
        "

# \\FS-SERVER.INTRA\storage\files\unity\users-profile\sector\%USERNAME%\Desktop\
