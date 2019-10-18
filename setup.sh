#!/bin/bash
#read -p 'Enter hostname for this machine: <?>.iaas.local  ' hname
hname=$1
hostnamectl set-hostname ${hname}.iaas.local
dnf install -y python3 python3-pip at hostname
pip3 install  awscli
yum module enable -y idm:DL1
yum install -y ipa-client at


# Write script for next startup
cat >/root/setup2.sh <<EOF
#!/bin/bash
# Setup ipa client
ipa-client-install --domain=iaas.local --server=ipa.iaas.local --realm=IAAS.LOCAL --principal hostman --password asdfghjkl --unattended
echo "asdfghjkl" | kinit hostman
ipa hostgroup-add-member generalaccess --hosts=`hostname`
touch /tmp/ipadone


#install optional modules
/home/ec2-user/modules/*.sh
sleep 1
systemctl start autofs
EOF

chmod +x /root/setup2.sh
systemctl enable --now atd.service
at now + 1 min -f /root/setup2.sh
echo "setup script complete"

