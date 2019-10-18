#!/bin/bash
#Installs autofs and automatically mounts homes
yum install -y nfs-utils
yum install -y autofs
echo "/home /etc/auto_home" >> /etc/auto.master
echo "* 10.1.137.234:/mnt/NAS/home/&" > /etc/auto_home
systemctl enable autofs
#systemctl start autofs
