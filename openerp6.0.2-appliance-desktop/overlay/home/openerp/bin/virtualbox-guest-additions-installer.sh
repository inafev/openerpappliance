#!/bin/bash
##########################################
# VIRTUALBOX GUEST ADDITIONS INSTALLER
##########################################
clear
stty erase '^?'
echo "Make sure your have installed VirtualBox 'Guest Additions' ('Devices' tab)"
echo "while your OpenERP Appliance is running."
echo "VirtualBox documentation describes how to do this."
echo
read -p "Press any key to continue..."
echo
sudo apt-get update
sudo apt-get install -y fakeroot build-essential crash kexec-tools makedumpfile kernel-wedge
sudo apt-get build-dep linux
sudo apt-get install -y git-core libncurses5 libncurses5-dev libelf-dev asciidoc binutils-dev
sudo apt-get install -y linux-headers-`uname -r`
sudo mount /dev/cdrom /mnt
cd /mnt
sudo ./VBoxLinuxAdditions.run
echo "Your OpenERP Appliance will be restarted"
read -p "Press any key to continue..."
sudo init 6 
