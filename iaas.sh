#!/bin/bash

if ! sudo -u ec2-user whoami >/dev/null ; then
    echo "You are not permitted to run this program."
    exit 1
fi


display_usage()  {
    echo "Use one of the following arguments:"
    echo "    add_user -> Add a new user"
    echo "    start_instance -> Add a new compute node"
    
}

add_user() {
    sudo -u ec2-user /home/ec2-user/scripts/add_user.sh
}

start_instance() {
    sudo -u ec2-user /home/ec2-user/scripts/start_instance_new.sh
}

case "$1" in
     "add_user" )
        add_user;;
     "start_instance" )
	 start_instance;;
    *) display_usage; exit 1;;
esac
