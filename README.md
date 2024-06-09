
# Overview
Automated and repeatable Kali build based from [Ippsec's](https://github.com/IppSec/parrot-build/tree/master) excellent Parrot OS Ansible Build.

Intended to be a consistently deployable and disposable Kali VM instance that can be used per engagement or training course). 

# Support
Tested and working on Kali 2024.2 (Rolling as of June 2024). 

Due to rolling nature of Kali, Ainsible and Packages: there are no guarantees in this automated build but aim to keep this frequently updated based on my build requirements.

# Whats included?
All standard Kali packages as well as the raft of things that do not come with Kali by default, but always find myself installing on any fresh build. i.e.
- Docker CE
- VS Code
- Burp Suite
- TireFire
- Flameshot
- pwntools
- flatpak
- golang
- Cloud CLI's (aws/gcp/azure)
- Ghidra
- Gobuster
- Smbclient / krb5 utils 
- Neofetch (depreciated I know)
- Bloodhound
- Ares / name-that-hash / search-that-hash
- SecLists
- Ligolo-ng / Chisel
- Evil-WinRM
- etc

Customisations:
The intent is to keep the build stock, but overlaying non obstructive quality of life tweaks such as:
- Performant yet practical tmux config
- Common terminal aliases
- Initial basic config for apps such as burp and browser integration

Principles:
- Install to default locations, usually /opt or $HOME/.local/bin
- Ensure tools are available in path
- Keep everything installed against the user wherever possible
- Minimise setup wizards/user acceptance policies/time wasters

# Instructions

## Quick deployment 
* Create new Kali VM using official Virtual Machine image
* git clone https://github.com/Byt3Danc3/ultimate-kali.git
* cd ultimate-kali
* chmod +x setup.sh
* ./setup.sh

## Slow  deployment
* Install Ansible (python3 -m pip install ansible)
* Clone and enter the repo (git clone)
* ansible-galaxy install -r requirements.yml
* Make sure we have a sudo token (sudo whoami)
* ansible-playbook main.yml
