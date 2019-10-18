#!/bin/bash
read -p 'Enter the IP address for the machine you want to register: ' iip
read -p 'Enter hostname for this machine: <?>.iaas.local  ' hname
instancename="IAAS-${hname}"
#mac=$(cat /sys/class/net/eth0/address)
#iid=$(curl http://169.254.169.254/latest/meta-data/network/interfaces/macs/${mac}/interface-id)
# get metadata
#iid=$(echo $ec2out | jq -r '.Instances[] | .InstanceId')
#echo " ID: $iid -- IP: $iip"
# wait til its up
#echo -n "Waiting for instance to come up...."
#aws ec2 wait instance-running --instance-ids $iid --region=us-east-1
#echo "OK"
# push private ey
#echo -n "Pushing private key...."
#sleep 5
#aws ec2-instance-connect send-ssh-public-key --region us-east-1 --availability-zone us-east-1b --instance-id $iid --instance-os-user ec2-user --ssh-public-key file://setup_rsa_key.pub
#echo "Done"

# wait til ssh available
echo -n "waiting for sshd...."
while ! nc -z $iip 22; do
    sleep 0.1
done
echo -n "port open, waiting for service to accept connections..."
while ! ssh -o StrictHostKeyChecking=no -i ./setup_key ec2-user@$iip stat /etc/passwd \> /dev/null 2\>\&1
do
    sleep 1
done
echo "OK"

# and connect
#echo -n "obtaining shell ..."
#ssh -o StrictHostKeyChecking=no -i setup_key ec2-user@$iip
echo -n "pushing setup script...."
scp -o StrictHostKeyChecking=no -i ./setup_key setup.sh ec2-user@${iip}:/home/ec2-user/setup.sh
echo "Done"

echo -n "running setup script...."
ssh -o StrictHostKeyChecking=no -i ./setup_key ec2-user@$iip "sudo /home/ec2-user/setup.sh ${hname}"
echo "Done"

# wait til its up
#echo -n "Waiting for instance to come up...."
#aws ec2 wait instance-running --instance-ids $iid --region=us-east-1
#echo "OK"

#
echo -n "waiting for kerberos setup...This usually takes ~ 2 minnutes!"
while ! ssh -o StrictHostKeyChecking=no -i ./setup_key ec2-user@$iip stat /tmp/ipadone \> /dev/null 2\>\&1
do
    sleep 2
done
echo "Done"
