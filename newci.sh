#!/bin/bash
clear
echo "This wizard will create an Ubuntu Server custom cloud-init image for KVM-based  hypervisors such as Proxmox"
sleep 2
echo "Please enter the desired id of the VM"
read vmid
echo "Please enter the name of the VM, eg. ubuntu-vm"
read vmname
echo "Please enter the size of the root HD in GB, eg. 64"
read diskcapacity
echo "Below is a list of datasets available on this system:"
pvesm status |sed 's/ .*//'
echo "Please type the name of the datastore to output the VM to:"
read storage
echo "Please enter the desired memory capacity in MB, eg. 4096"
read memorycapacity
echo "Please enter your github username to download your SSH pubkeys"
read githubusername
echo "Please enter server username, eg. admin"
read serverusername
echo "Please enter SSH password (enter for none)"
read -s cipassword
echo "============DOWNLOADING CLOUD IMAGE=============="
mkdir /tmp/cloudimage -p
cd /tmp/cloudimage
wget https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64-disk-kvm.img
echo "=============== CREATING VM 	==============="
qm create $vmid --memory $memorycapacity --name $vmname --net0 virtio,bridge=vmbr0
echo "=============== IMPORTING DISK	==============="
qm importdisk $vmid jammy-server-cloudimg-amd64-disk-kvm.img $storage -format raw
echo "=============== ATTACHING DISK    ==============="
qm set $vmid --scsihw virtio-scsi-pci --scsi0 /mnt/pve/${storage}/images/$vmid/vm-$vmid-disk-0.raw,discard=1,ssd=1
echo "=============== CREATING CLOUDINIT==============="
qm set $vmid --ide2 $storage:cloudinit
echo "=============== SETTING BOOTDISK  ==============="
qm set $vmid --boot c --bootdisk scsi0
echo "==============SETTING CONSOLE OUT================"
qm set $vmid --serial0 socket --vga serial0
echo "=============== EXPANDING DISK   ================"
qm resize $vmid scsi0 +${diskcapacity}G
echo "=============== SETTING DHCP     ================"
qm set $vmid --ipconfig0 ip=dhcp
echo "=============== DOWNLOADING SSH KEYS============="
curl https://github.com/${githubusername}.keys | tee $githubusername.pub
echo "=============== ADDING SSH KEYS  ================"
qm set $vmid --sshkey $githubusername.pub
echo "===============SETTING USER & PASS==============="
qm set $vmid --ciuser $serverusername
qm set $vmid --cipassword $cipassword
qm set $vmid --keyboard en-gb
echo "=======VM CREATED WITH FOLLOWING CONFIG:========="
qm config $vmid
echo "=============== SCRIPT COMPLETE ================="
