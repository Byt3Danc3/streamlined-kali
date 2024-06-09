#!/bin/bash

ADMIN_PASSWORD=kalihax0r
ENC_PASSWORD=$(htpasswd -nb -B admin $ADMIN_PASSWORD | cut -d ":" -f 2)

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

line_break "Fixing Docker CE Permissions"
sudo usermod -aG docker $USER

line_break "Enabling Docker Service"
sudo systemctl enable --now docker.service

line_break "Installing portainer (Accessible via 9000)"
sudo docker volume create portainer_data
sudo docker run -d -p 127.0.0.1:8000:8000 -p 127.0.0.1:9000:9000 --name portainer -e ADMIN_USERNAME=admin -e ADMIN_PASSWORD=$ENC_PASSWORD --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce:latest

line_break "Running playbook"
ansible-playbook main.yml
line_break "Playbook complete!"