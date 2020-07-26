#!/bin/bash
#script for first boot centOS of Luan's VM
#essential basic steps

yum update -y

yum install -y net-tools
yum install -y bind-utils
yum install -y wget
yum install -y bash-completion

systemctl status firewalld
sleep 3
systemctl stop firewalld
systemctl disable firewalld

ip_var=`shuf -i 10-255 -n 1`
echo -e "TYPE="Ethernet"\nPROXY_METHOD="none"\nBROWSER_ONLY="no"\nBOOTPROTO="static"\nDEFROUTE="yes"\nIPV4_FAILURE_FATAL="no"\nNAME="ens33"\nDEVICE="ens33"\nONBOOT="yes"\nIPADDR=192.168.200.${ip_var}\nNETMASK=255.255.255.0\nGATEWAY=192.168.200.2\nDNS1=8.8.8.8" > /etc/sysconfig/network-scripts/ifcfg-ens33

sed -i s/"SELINUX=enforcing"/"SELINUX=disabled"/ /etc/sysconfig/selinux

reboot