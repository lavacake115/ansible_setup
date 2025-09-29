#! /bin/bash

###################
# AUTHOR: LAVACAKE115 #
###################

# WISHLIST
# - append to log for every significant event that occurs


# setting up a log
LOG_FILE=/opt/var/log/ansible_starter_$(date +%Y-%m-%d-%H:%M.%S).log

# checking sudo privileges
if [[ $EUID -ne 0 ]] ; then
    echo -e "You must run this script with sudo ... exiting"
    exit 1
else
    echo -e "STARTING SCRIPT!!!"
fi


# detect what OS the controller node is running then install ansible
if [[ -n $(hostnamectl|grep "Rocky Linux") ]] ; then
    echo -e "\n ROCKY OS DETECTED ... CONTINUING \n"
    yum install ansible-core -y
elif
    [[ -n $(hostnamectl|grep "Red Hat Enterprise") ]] ; then
    echo "\n RHEL OS detected ... proceeding to install Ansible \n"
    # rhel has a few extra steps, so will enable the ansible core repo first
    ansible_repo=$(subscription-manager repos --list | grep "Repo ID" | grep "ansible-automation-platform-2.6-for-rhel-9-x86_64-rpms" | awk -F ':' '{print $2}' | awk '{$1=$1; print}')
    subscription-manager repos --enable=$ansible_repo
    yum install ansible-core -y
else
    echo "RHEL-based nor Rocky OS DETECTED ... EXITING ... :("
    exit 1
fi


# create ansible user on controller node and generate an RSA key pair
echo -e "\n CREATING ANSIBLE USER AND GENERATING RSA KEY PAIR \n"

if [[ -z $(cat /etc/passwd | grep -i ansible) ]] ; then
    echo -e "\n CREATING ANSIBLE USERNAME ON CONTROLLER NODE \n "
    useradd ansible
    su - ansible -c "ssh-keygen -t rsa -b 4096 -q -N '' -f /home/ansible/.ssh/id_rsa"
    echo "temp" | passwd ansible --stdin
    # editing sudoer's file so that ansible user has sudo privileges without entering password as well
    touch /etc/sudoers.d/ansible
    echo "ansible ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/ansible
    echo -e "\nAnsible user has been created successfully\n"
else
    echo -e "\n ANSIBLE USERNAME HAS ALREADY BEEN CREATED ... you must delete the current existing ansible user then re-run this script \n"
    exit 1
fi


function node_setup
{
echo -n "Would you like to set up managed nodes? (yes/no): " ; read user_choice
    # setting up an array of the managed nodes
    NODES_ARRAY=()

if [[ $user_choice == "yes" ]] ; then
    echo -n "Please enter the name of the FIRST managed node: " ; read first_node
    echo -e "\n You have entered hostname: $first_node \n"
    NODES_ARRAY[0]=$first_node

    echo -n "Would you like to enter the name of a second managed node? (yes/no): " ; read another_choice

    if [[ $another_choice == "yes" ]] ; then
        echo -n "Enter the name of the SECOND managed node: " ; read second_node
        echo "You have enter hostname: $second_node"
        NODES_ARRAY[1]=$second_node
    else
        echo -e "\n You have entered only 1 managed node ... proceeding\n"
    fi
    echo -n "Please enter a username that has access to the managed nodes: " ; read valid_username
    

    # setting up a loop in order to perform all commands needed to crate ansible user
    echo -e "\n CREATING ANSIBLE USER ON MANAGED NODES ... \n"
    for i in ${NODES_ARRAY[@]} ;
    do
    ssh -t $valid_username@$i "
    sudo useradd ansible
    echo 'ansible ALL=(ALL) NOPASSWD:ALL' | sudo tee /etc/sudoers.d/ansible
    echo "temp" | sudo passwd ansible --stdin
    echo 'PubkeyAuthentication yes' | sudo tee -a /etc/ssh/sshd_config
    sudo systemctl restart sshd.service
    "
    echo -e "\n USE THE PASSWORD \e[1;31m'temp'\e[0m FOR THE FOLLOWING PROMPT \n"
    ssh-copy-id -i /home/ansible/.ssh/id_rsa.pub ansible@$i ; 
    done

else
    echo -e "You have chosen to NOT set up another other Ansible managed nodes ... you will have to manually set them up yourself ... Goodbye"
    exit 1
fi

echo -e "\n SETTING UP ANSIBLE ON THE MANAGED NODES HAS COMPLETED SUCCESSFULLY ..."

echo -e " BEGINNING TO CONFIGURE ansible.cfg, inventory, and ping module ...\n"

}


function ansible_portion
{
# setting up ansible.cfg, inventory hosts file, and performing a ping pong
bash -c 'cat > /etc/ansible/ansible.cfg << '"'EOF'"'
[defaults]
remote_user = ansible
host_key_checking = false
inventory = inventory

[privilege_escalation]
become = True
become_method = sudo
become_user = root
become_ask_pass = False
EOF'

touch /etc/ansible/inventory
export first_node second_node
bash -c 'cat > /etc/ansible/inventory << EOF
[servers]
$first_node
$second_node
EOF'

su - ansible -c "ansible all -m ping"

echo -e "\n SUCCESS. Ansible is now set up on the controller node ... $(hostname) ... and the other managed nodes ... Goodbye! \n"
}

node_setup
ansible_portion




