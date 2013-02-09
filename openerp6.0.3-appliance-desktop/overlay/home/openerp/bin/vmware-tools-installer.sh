#!/bin/bash
###########################
# VMWARE TOOLS INSTALLER
###########################
clear
stty erase '^?'
echo "Make sure your have installed VMware Tools ('Virtual Machine' tab)"
echo "while your OpenERP Appliance is running."
echo "VMware documentation describes how to do this."
echo
read -p "Press any key to continue..."

sudo apt-get update
sudo apt-get install -y fakeroot build-essential crash kexec-tools makedumpfile kernel-wedge
sudo apt-get build-dep linux
sudo apt-get install -y git-core libncurses5 libncurses5-dev libelf-dev asciidoc binutils-dev
sudo apt-get install -y linux-headers-`uname -r`
sudo mount /dev/cdrom /mnt
cd /home/openerp
tar xvzf /mnt/VMwareTools* -C .
cd vmware-tools-distrib/
sudo ./vmware-install.pl -d  # the -d switch accepts the defaults 
echo "Adding VMware Shared folders to /etc/fstab (commented to avoid potential problems)"
sudo su -c "echo '#.host:/ /mnt/hgfs vmhgfs defaults,user,ttl=5,uid=1000,gid=1001 0 0' >>/etc/fstab"
echo "Your OpenERP Appliance will be restarted"
read -p "Press any key to continue..."
sudo init 6
