# ansible_setup
This bash script will help to set up Ansible from scrath.
It will take care of the following:
- Installing ansible-core
- creating ansible user on controller node
- Generating and copying ansible user RSA key pair from controller to managed nodes
- Setting up ansible user, authentication, ssh config, etc on managed nodes
- Setting up ansible.cfg and a basic inventory file
- Testing ping module to ensure pong is received
  
Requirements:
- User with sudo privileges on BOTH controller and managed nodes
- Rocky or RHEL OS (Debian-based OS's NOT supported)
- One controller node + at least ONE to-be managed node

Limitations:
- Currently, the script only supports setting up to TWO managed nodes only

NOTE:
- This script must be ran from the controller node.
