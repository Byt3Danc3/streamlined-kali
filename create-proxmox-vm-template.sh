#!/bin/bash

# User Variables

KALI_META_PACKAGE="kali-linux-large"
VMHOSTNAME="Streamlined-Kali"
KALIVERSION="2024.2" 
PUBKEYFILE="pubkey"

# Optional variables

# Use Proxmox Template ISO path 
#ISOPATH="`df | grep "/mnt/pve" | sed 's/.* \([^ ]*\)$/\1/'`/template/iso/"
ISOPATH="`pwd`/"
IMAGE_URL="https://cdimage.kali.org/kali-$KALIVERSION/kali-linux-$KALIVERSION-qemu-amd64.7z" IMAGE_NAME="kali-linux-$KALIVERSION-qemu-amd64.7z" 
IMAGE_PATH="$ISOPATH$IMAGE_NAME"
QCOW2_PATH="$ISOPATH/kali-linux-$KALIVERSION-qemu-amd64.qcow2"


## Check necessary packages  
apt install -y libguestfs-tools p7zip-full sudo


# Prompt to delete existing qcow2 image
if [ -f "$QCOW2_PATH" ]; then
    read -p "The qcow2 image already exists. Do you want to delete it? (y/n): " delete_qcow2
    if [ "$delete_qcow2" == "y" ]; then
        rm -f "$QCOW2_PATH"
    fi
fi

# Prompt to create a SHA256 checksum
read -p "Do you want to create a SHA256 checksum of the 7z file? (y/n): " create_checksum
if [ "$create_checksum" == "y" ]; then
    sha256sum "$IMAGE_PATH"
fi

# Check if the image file already exists
if [ -f "$IMAGE_PATH" ]; then
    # Get the local file size
    LOCAL_SIZE=$(stat -c%s "$IMAGE_PATH")
    # Get the remote file size
    REMOTE_SIZE=$(wget --spider "$IMAGE_URL" 2>&1 | grep Length | awk '{print $2}')

    if [ "$LOCAL_SIZE" -eq "$REMOTE_SIZE" ]; then
        echo "The local file size matches the remote file size. Skipping download."
    else
        echo "File size mismatch or partial download detected. Resuming download..."
        wget -c -P "$ISOPATH" "$IMAGE_URL"
    fi
else
    # Download the file
    wget -P "$ISOPATH" "$IMAGE_URL"
fi

# Extract the image 
7z x "$IMAGE_PATH" -o"$ISOPATH"

# Find the next available VMID 
VMID=751 
while qm list | grep -q " $VMID "; do 
	VMID=$((VMID + 1)) 
done 

echo "Using VMID: $VMID"

qm create $VMID \
    --name $VMHOSTNAME \
    --agent 1 \
    --memory 4096 \
    --bios seabios \
    --sockets 1 --cores 4 \
    --cpu host \
    --net0 virtio,bridge=vmbr0,tag=10 \
    --scsihw virtio-scsi-single

# Modify the image for Cloud-init support
virt-customize -a "$ISOPATH/kali-linux-$KALIVERSION-qemu-amd64.qcow2" --install cloud-init
virt-customize -a "$ISOPATH/kali-linux-$KALIVERSION-qemu-amd64.qcow2" --hostname $VMHOSTNAME

# Install the QEMU agent, enable SSH, configure DHCP and SLAAC, and run the setup script
virt-customize -a "$ISOPATH/kali-linux-$KALIVERSION-qemu-amd64.qcow2" --install qemu-guest-agent
virt-customize -a "$ISOPATH/kali-linux-$KALIVERSION-qemu-amd64.qcow2" --run-command 'systemctl enable ssh.service'
virt-customize -a "$ISOPATH/kali-linux-$KALIVERSION-qemu-amd64.qcow2" --run-command 'echo -e "auto eth0\niface eth0 inet dhcp\niface eth0 inet6 auto" >> /etc/network/interfaces'
#virt-customize -v -a "$ISOPATH/kali-linux-$KALIVERSION-qemu-amd64.qcow2" --run-command 'dhclient eth0 && ip a'



# Import the disk image
qm importdisk $VMID "$ISOPATH/kali-linux-$KALIVERSION-qemu-amd64.qcow2" local-zfs --format qcow2

# Attach the disk and configure the VM
qm set $VMID --scsi0 local-zfs:vm-$VMID-disk-0
qm set $VMID --scsi0 local-zfs:cloudinit

# Define boot order and console access
qm set $VMID --boot c --bootdisk scsi0
qm set $VMID --serial0 socket --vga serial0
qm set $VMID --vga std

# Setting Cloud-init parameters
qm set $VMID --ciuser kali --cipassword "kalihax0r"
qm set $VMID --sshkey $PUBKEYFILE
qm set $VMID --ipconfig0 ip=dhcp,ip6=auto #ipv6 configured for slaac

# Select size of Kali Install
virt-customize -a "$ISOPATH/kali-linux-$KALIVERSION-qemu-amd64.qcow2" --run-command 'sudo apt install -y kali-linux-large'

# Main playbook/customisations

virt-customize -a "$ISOPATH/kali-linux-$KALIVERSION-qemu-amd64.qcow2" --run-command 'git clone https://github.com/Byt3Danc3/streamlined-kali.git && cd streamlined-kali && chmod +x setup.sh && ./setup.sh'

# Convert VM to template if needed
qm template $VMID

# Find the next available VMID 
NEXTVMID=$VMID
while qm list | grep -q " $NEXTVMID "; do 
	NEXTVMID=$((NEXTVMID + 1)) 
done 

echo "Using NEXTVMID: $NEXTVMID"

qm clone $VMID $NEXTVMID --name $VMHOSTNAME-$NEXTVMID
