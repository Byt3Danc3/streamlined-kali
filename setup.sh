#!/bin/bash

function line_break () {
    word=$1
    total_length=100
    padding_length=$((($total_length - ${#word})/2))
    printf "%${padding_length}s" | tr ' ' '#'
    if [[ ${#word} -ne 0 ]]; then
        echo -n " $word "
    else
        echo -n "##"
    fi
    printf "%${padding_length}s" | tr ' ' '#'
    printf "\n"
}

line_break "update to ensure we can install"
sudo apt update

line_break "install auto-apt-proxy for those with apt-cacher-ng to drastically speed up rebuilds"
sudo apt install auto-apt-proxy 

line_break "run auto-apt-proxy, if cannot detect apt-cacher-ng then exit. Disable if not available"
auto-apt-proxy  || exit

line_break "Installing ansible via pip"
sudo python3 -m pip install ansible
line_break "Ansible Installed"

line_break "Installing ansible-galaxy roles"
ansible-galaxy install -r requirements.yml
line_break "Roles Installed"

line_break "Enabling ssh service"
sudo systemctl enable --now ssh.service

sudo whoami > /dev/null

line_break "Fixing Docker CE Install (Ainsible is broken)"
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian bookworm stable" | sudo tee /etc/apt/sources.list.d/docker.list 
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io 


line_break "Running playbook"
ansible-playbook main.yml
line_break "Playbook complete!"