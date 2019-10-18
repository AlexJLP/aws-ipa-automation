#!/bin/bash
source /home/ec2-user/scripts/theme
hname=$(whiptail --inputbox "Please enter the hostname for thsis new machine (<?>.iaas.local)" 8 78 --title "Hostname" 3>&1 1>&2 2>&3)
# A trick to swap stdout and stderr.

exitstatus=$?
if [ ! $exitstatus = 0 ]; then
    echo "Please enter a valid hostname"
    exit 1
fi

instancename="IAAS-${hname}"

# start the instance
echo -n "Creating instance...."
ec2out=$(/usr/local/bin/aws ec2 run-instances --launch-template LaunchTemplateId=lt-07c697393313cbf9c,Version=1 --region=us-east-1 --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=${instancename}}]")
echo "Done"

# get metadata
iid=$(echo $ec2out | jq -r '.Instances[] | .InstanceId')
iip=$(echo $ec2out |jq -r '.Instances[] | .NetworkInterfaces[] | .PrivateIpAddress')
echo " ID: $iid -- IP: $iip"

# wait til its up
echo -n "Waiting for instance to come up...."
/usr/local/bin/aws ec2 wait instance-running --instance-ids $iid --region=us-east-1
echo -e "\e[92mOK\e[39m"

# optional modules select
modules=(/home/ec2-user/scripts/modules/*.sh)
declare -a array

for m in "${modules[@]}"
do
    array+=($(basename $m) "$(cat $m | sed '2q;d' | cut -c2- )" OFF)
done

choices=$(whiptail --title "Additional Features" --checklist \
"Please choose any additional features you want to have installed." 20 78 10 \
"${array[@]}" 3>&1 1>&2 2>&3)
echo "Selected: $choices"


# wait til ssh available
echo -n "waiting for sshd...."
while ! nc -z $iip 22; do
    sleep 0.1
done
echo -n "port open, waiting for service to accept connections..."
while ! ssh -o StrictHostKeyChecking=no -i /home/ec2-user/scripts/setup_key ec2-user@$iip stat /etc/passwd \> /dev/null 2\>\&1
do
    sleep 1
done
echo -e "\e[92mOK\e[39m"

# and connect
#echo -n "obtaining shell ..."
#ssh -o StrictHostKeyChecking=no -i setup_key ec2-user@$iip
echo -n "pushing setup scripts...."
# main
scp -o StrictHostKeyChecking=no -i /home/ec2-user/scripts/setup_key /home/ec2-user/scripts/setup.sh ec2-user@${iip}:/home/ec2-user/setup.sh

# optional
ssh -o StrictHostKeyChecking=no -i /home/ec2-user/scripts/setup_key ec2-user@$iip "mkdir /home/ec2-user/modules"
for module in $choices; do
    fn=$(echo $module | xargs )
    scp -o StrictHostKeyChecking=no -i /home/ec2-user/scripts/setup_key "/home/ec2-user/scripts/modules/$fn" "ec2-user@${iip}:/home/ec2-user/modules/$fn"
done
echo -e "\e[92mOK\e[39m"

echo -n "running setup script...."
ssh -o StrictHostKeyChecking=no -i /home/ec2-user/scripts/setup_key ec2-user@$iip "sudo /home/ec2-user/setup.sh ${hname}"
echo -e "\e[92mOK\e[39m"

echo "Client has to be rebooted. Doing so now."
ssh -o StrictHostKeyChecking=no -i /home/ec2-user/scripts/setup_key ec2-user@$iip "sudo reboot now"


whiptail --title "Kerberos Setup" --msgbox "Kerberos needs to be installed, and the instance needs to be registered. Please be patient as this might take up to 2 mintues." 8 78

# wait til its up
echo -n "Waiting for instance to come up...."
/usr/local/bin/aws ec2 wait instance-running --instance-ids $iid --region=us-east-1
echo -e "\e[92mOK\e[39m"

echo -n "waiting for kerberos setup..."
while ! ssh -o StrictHostKeyChecking=no -i /home/ec2-user/scripts/setup_key ec2-user@$iip stat /tmp/ipadone \> /dev/null 2\>\&1
do
    sleep 2
done
echo -e "\e[92mOK\e[39m"


cat > /tmp/setup <<EOF
The instance has been successfully set up.

Instance ID: $iid
Instance IP: $iip
Hostname: ${hname}.iaas.local
AWS Name: $instancename
EOF
whiptail --textbox /tmp/setup 12 80
