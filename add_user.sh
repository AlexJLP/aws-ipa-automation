#!/bin/bash
source /home/ec2-user/scripts/theme

echo "Checking kerberos tokens"
klist
exitstatus=$?
if [ ! $exitstatus = 0 ] ; then
    echo "Please run kinit first."
    exit 1
fi


username=$(whiptail --inputbox "Please enter username for the new user" 8 78 --title "Add User" 3>&1 1>&2 2>&3)
exitstatus=$?
if [ ! $exitstatus = 0 ] || [[ -z "$username" ]]; then
    echo "Please enter a valid name"
    exit 1
fi
fname=$(whiptail --inputbox "Please enter firstname the new user" 8 78 --title "Add User" 3>&1 1>&2 2>&3)
exitstatus=$?
if [ ! $exitstatus = 0 ] || [[ -z "$fname" ]]; then
    echo "Please enter a valid name"
    exit 1
fi
sname=$(whiptail --inputbox "Please enter surname of the new user" 8 78 --title "Add User" 3>&1 1>&2 2>&3)
exitstatus=$?
if [ ! $exitstatus = 0 ] || [[ -z "$sname" ]] ; then
    echo "Please enter a valid name"
    exit 1
fi


array=()
while IFS= read -r line; do
    array+=( "${line}" )
    done < <( python3 getGroups.py )

choices=$(whiptail --title "Groups" --checklist \
"Please choose any additional groups you want to add the user to." 20 80 10 \
"${array[@]}" 3>&1 1>&2 2>&3)


ipa user-add ${username} --first="${fname}" --last="${sname}"  --password

for grp in $choices; do
    fn=$(echo $grp | xargs )
    ipa group-add-member $fn --users=${username}
done

# create homedir
echo "creating homedirs."
mkdir /homes/${username}
sudo chown ${username}:${username} /homes/${username}


# ask if add to db?
if (whiptail --title "New User - Database" --yesno "Would you like to add this user to be able to use the  database cluster? You need to be a db admin." 8 78); then
    echo "please authenticate as db admin.."
    kinit admin
    echo "create user \"${username}@IAAS.LOCAL\"; CREATE ROLE; \q" | psql admin@IAAS.LOCAL -h db.IAAS.LOCAL -d postgres
    echo "User added to DB."
fi

