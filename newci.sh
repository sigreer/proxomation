#!/bin/bash
echo "Please enter the desired id of the VM"
read vmid
echo "Please enter the name of the VM, eg. ubuntu-vm"
read vmname
echo "Please enter the size of the root HD in GB, eg. 64"
read diskcapacity
echo "Please enter the desired memory capacity in MB, eg. 4096"
read memorycapacity
echo "Please enter your github username for SSH keys"
read githubusername
echo "Please enter your SSH password"
read -s cipassword
echo "=============== CREATING VM 	==============="
qm create $vmid --memory $memorycapacity --name $vmname --net0 virtio,bridge=vmbr0
echo "=============== IMPORTING DISK	==============="
qm importdisk $vmid jammy-server-cloudimg-amd64-disk-kvm.img dc1temp -format raw
echo "=============== ATTACHING DISK    ==============="
qm set $vmid --scsihw virtio-scsi-pci --scsi0 /mnt/pve/dc1temp/images/$vmid/vm-$vmid-disk-0.raw
echo "=============== CREATING CLOUDINIT==============="
qm set $vmid --ide2 dc1temp:cloudinit
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
echo "=============== SETTING PASSWORD ================"
qm set $vmid --cipassword $cipassword
echo "=============== SCRIPT COMPLETE ================="
