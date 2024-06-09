Personal Kali Adaptation of [Ippsec's](https://github.com/IppSec/parrot-build/tree/master) Parrot OS Ansible Build

** Make sure to pip install ansible, apt has an older copy **

# Instructions

## Quick deployment 
* Start with Kali
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
