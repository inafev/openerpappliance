#!/bin/bash
######################################################################################################################################################################
######################################################################################################################################################################
# File: openerp-allinone-setup.sh
# This script automates the setting up of openerp-server-5.0.x & openerp-client-5.0.x & openerp-web-5.0.x for Ubuntu 8.04.3 LTS Desktop or Server
######################################################################################################################################################################
######################################################################################################################################################################
# Author: I. Fernández
# twitter.com/linuxunixmadrid
# Date: October 20th 2010
# Version: 4.1.1
# Version 4.1.1 October 20th 2010. Bug fixed by Jeroen Vet (grep -v grep, line #199)
# License: This script is released into GPLv3 (GNU GENERAL PUBLIC LICENSE Version 3)
# http://opensourceconsulting.wordpress.com/
######################################################################################################################################################################
######################################################################################################################################################################
# Requirements: A fresh installation of Ubuntu 8.04.4 LTS or Ubuntu 9.10
# TIP: test this script within a Virtual Machine after installing Ubuntu 8.04 or 9.10 from
# scratch. Run the virtual machine in a bridged network (host and guest have same subnet and
# can be reached from the LAN).
#
# Tested on
#      Ubuntu 8.04.4 LTS Desktop and Server, computer platform amd64 (64 bits) and i386 (32 bits)
#      Ubuntu 9.10 Desktop, computer platform amd64 (64 bits)	
#
# You can run the script on Ubuntu Desktop through the Graphical User Interface: uncompress the file, make openerp-allinone-setup-stable.sh 
# icon executable with “right click -> properties”, double click on the icon and “Run in a Terminal”.
#
# Additional info:
# 1) OpenERP for Ubuntu Linux is recommended on production systems.
# 2) Desktop Icons for openerp-client and openerpweb URL are made 
# 3) Available IP addresses are shown to ease the IP address input. The first configured IP is marked as default one
# 4) The installation process can be as simple as “Pressing Accept” for each question.
# 5) The script ends pointing out the URL of your OpenERP Web and its corresponding passwords. An OpenERP-README.txt file is created with this information.
#
# Startup/init scripts:
#
#    * /etc/init.d/openerp-server
#    * /etc/init.d/openerp-web
#    * /etc/init.d/openoffice
#
# BAZAAR DOC: http://doc.bazaar-vcs.org/latest/en/user-guide/index.html
######################################################################################################################################################################
######################################################################################################################################################################

# Checking constraints...
OSREQUIREMENT=`awk '/Ubuntu 8.04/ {print $0}' /etc/issue`
OSREQUIREMENT2=`awk '/Ubuntu 9.10/ {print $0}' /etc/issue`
OSREQUIREMENT3=`awk '/Ubuntu 10.04/ {print $0}' /etc/issue`
if [ -z "$OSREQUIREMENT" -a -z "$OSREQUIREMENT2" -a -z "$OSREQUIREMENT3" ];
then
   echo "This program must be executed on Ubuntu 8.04 LTS, Ubuntu 9.10 or Ubuntu 10.04 LTS (Desktop or Server)"
   zenity --error --text="This program must be executed on Ubuntu 8.04 LTS, Ubuntu 9.10 or Ubuntu 10.04 LTS (Desktop or Server)"
   exit 1
fi
if [ -n "$OSREQUIREMENT" ];
then
   # Ubuntu 8.04, python 2.5
   PSQLRELEASE=8.3
   PYTHONRELEASE=python2.5
   UBUNTURELEASE=8.04
   INSTALLPATH=/usr
   SITEPACKAGESPATH=$INSTALLPATH/lib/$PYTHONRELEASE/site-packages
   OPENERPSERVERPATH=$SITEPACKAGESPATH/openerp-server
   ADDONSPATH=$OPENERPSERVERPATH/addons/
   OPENERPSERVERWRONGPATH=/nobugnoworkaround
else
   # Ubuntu 9.10, python 2.6
   PSQLRELEASE=8.4
   PYTHONRELEASE=python2.6
   UBUNTURELEASE=9.10
   INSTALLPATH=/usr/local
   SITEPACKAGESPATH=$INSTALLPATH/lib/$PYTHONRELEASE/dist-packages
   OPENERPSERVERPATH=$SITEPACKAGESPATH/openerp-server
   ADDONSPATH=$OPENERPSERVERPATH/addons/
   OPENERPSERVERWRONGPATH=$INSTALLPATH/lib/$PYTHONRELEASE/site-packages/openerp-server
fi
`dpkg-query -W -f='${Status}\n' xdg-user-dirs > /tmp/dpkg-query.txt`
UBUNTUDESKTOPINSTALLED=`awk '/install ok installed/ {print $0}' /tmp/dpkg-query.txt`
if [ -z "$UBUNTUDESKTOPINSTALLED" ];
then
   clear
   stty erase '^?'
   echo "This system seems to be Ubuntu Server... Installing zenity & xauth"
   echo "If the script ends with this messange \"(zenity:5539): Gtk-WARNING **: cannot open display:\" just exit from your SSH session and try again."
   echo "Remember to enable X11Forwarding with SSH"
   read -p "Press any key to continue…"
   sudo aptitude -f update
   sudo aptitude install -y zenity
   # Ubuntu 8.04.3 LTS Server requires xauth binary to remotely display linux applications like openerp-client:
   sudo aptitude install -y xauth
   MYDESKTOP=$HOME
else
MYDESKTOP=`xdg-user-dir DESKTOP`
fi


##################################################################################################################################
# FUNCTIONS
##################################################################################################################################
function installopenoffice3withreportopenofficelibraries()
{
if [ "$UBUNTURELEASE" = "8.04" -a ! -e /etc/apt/sources.list.d/openoffice3.list ]; then
# INSTALACIÓN DE OPENOFFICE 3 (ubuntu 8.04 viene con OpenOffice 2.4, ubuntu >= 9.04 con OpenOffice 3)
echo "# report-openoffice: Adding openoffice 3 in APT sources list";
echo "report-openoffice: Adding openoffice 3 in APT sources list" >> $MYDESKTOP/OpenERP-updates.txt;
cat > /tmp/openoffice3.list <<"openoffice3EOF"
deb http://ppa.launchpad.net/openoffice-pkgs/ubuntu hardy main
deb-src http://ppa.launchpad.net/openoffice-pkgs/ubuntu hardy main
openoffice3EOF
sudo -v
sudo cp /tmp/openoffice3.list /etc/apt/sources.list.d/
sudo chown root.root /etc/apt/sources.list.d/openoffice3.list
sudo chmod 644 /etc/apt/sources.list.d/openoffice3.list
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 60D11217247D1CFF
#sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 247D1CFF
fi
echo "# report-openoffice: Installing openoffice 3";
echo "report-openoffice: Installing openoffice 3" >> $MYDESKTOP/OpenERP-updates.txt;
sudo aptitude clean
sudo aptitude -f update
sudo aptitude install -y openoffice.org
#if [ "$OPENERPSPAININSTALL" = "y" ]; then 
if [ -d /opt/openerp-spain ]; then
echo "# Instalando openoffice.org-l10n-es";
sudo aptitude install -y openoffice.org-l10n-es
fi
# Checking if java6 is already set up:
showjava6state=$(aptitude show sun-java6-bin | grep State)
JAVA6INSTALL=$(echo $showjava6state | awk '/installed/')
if [ -z "$JAVA6INSTALL" ];
then
echo "# report-openoffice: Installing sun-java6-bin sun-java6-plugin sun-java6-fonts";
echo "report-openoffice: Installing sun-java6-bin sun-java6-plugin sun-java6-fonts" >> $MYDESKTOP/OpenERP-updates.txt;
#Installing java non-interactively
#http://www.davidpashley.com/blog/debian/java-license
cat > /tmp/accept-java-license <<"EOFaccept-java-license"
sun-java5-jdk shared/accepted-sun-dlj-v1-1 select true
sun-java5-jre shared/accepted-sun-dlj-v1-1 select true
sun-java6-jdk shared/accepted-sun-dlj-v1-1 select true
sun-java6-jre shared/accepted-sun-dlj-v1-1 select true
EOFaccept-java-license
sudo /usr/bin/debconf-set-selections /tmp/accept-java-license
sudo aptitude install -y sun-java6-bin sun-java6-plugin sun-java6-fonts
fi
# http://wiki.services.openoffice.org/wiki/Using_Python_on_Linux
# OpenOffice.org on Ubuntu
# Ubuntu installs OpenOffice.org under:
# /usr/lib/openoffice/ 
# Ubuntu installs OpenOffice.org Python package openoffice-uno by default.
# The Ubuntu OOo is built "--with-system-python", which means OOo Python is identical to your System Python (This applies to the most recent stable version at the time of writing, which was 'Feisty').
# All Python scripts will be installed under the program folder.
# You will have to set the PYTHONPATH environment variable to use Python outside of OO.org; if you don't, the python executable will not find the pyuno libraries. 
# From a terminal type: [bash] export PYTHONPATH="/usr/lib/openoffice.org/program" before invoking python. 
# INSTALACIÓN DE PAQUETES REQUERIDOS POR REPORT-OPENOFFICE
sudo -v
echo "# report-openoffice: Installing python-genshi python-yaml python-cairo python-relatorio python-pycha python-openoffice";
echo "report-openoffice: Installing python-genshi python-yaml python-cairo python-relatorio python-pycha python-openoffice" >> $MYDESKTOP/OpenERP-updates.txt;
sudo aptitude install -y python-genshi python-yaml python-cairo
if [ "$UBUNTURELEASE" = "8.04" ]; then
# python-relatorio: http://relatorio.openhex.org/  (DISPONIBLE EN KARMIC 9.10 Y LUCID 10.04)
sudo easy_install relatorio
# python-pycha DISPONIBLE A PARTIR DE Ubuntu Intrepid 8.10
sudo easy_install pycha
# report-openoffice requires lxml >= 2.0, while ubuntu 8.04 provides lxml 1.3.6
# We upgrade lxml (v2.2.4)
sudo aptitude install -y libxml2-dev libxslt1-dev
sudo easy_install "lxml>2.0"
# According to REQUIRES.txt file, report-openoffice requires two packages: 1) relatorio 2)openoffice-python
sudo easy_install openoffice-python
elif [ "$UBUNTURELEASE" = "9.10" ]; then
sudo aptitude install -y python-relatorio python-pycha 
sudo aptitude install -y python-openoffice
fi
sudo -v
}

function enablingopenofficeheadlessserver()
{
echo "# DON'T PRESS ACCEPT/OK !!. Enabling OpenOffice headless server";
sudo /usr/sbin/adduser --quiet --system --group soffice

cat > /tmp/openoffice <<"EOFOOo_init"
#!/bin/sh
### BEGIN INIT INFO
# Provides:             openoffice
# Required-Start:       $syslog
# Required-Stop:        $syslog
# Should-Start:         $network
# Should-Stop:          $network
# Default-Start:        2 3 4 5
# Default-Stop:         0 1 6
# Short-Description:    openoffice.org  headless server script
# Description:          headless openoffice server script
### END INIT INFO

PATH=/bin:/usr/bin:/sbin:/usr/sbin
OOo_HOME=/usr/lib/openoffice
SOFFICE_PATH=$OOo_HOME/program/soffice
VARSOFFICE=`ps uaxww | grep -v grep | grep soffice.bin` 

case "$1" in
    start)
    if [ -n "$VARSOFFICE" ]; then
      echo "OpenOffice headless server has already started."
    else
      echo "Starting OpenOffice headless server"
      sudo -H -u soffice $SOFFICE_PATH -nologo -nofirststartwizard -headless -norestore -invisible -accept="socket,host=localhost,port=8100,tcpNoDelay=1;urp;" & >/dev/null 2>&1
    fi
    ;;
    stop)
    if [ -n "$VARSOFFICE" ]; then
      echo "Stopping OpenOffice headless server."
      killall soffice.bin
    else
    echo "Openoffice headless server is not running, foo."
    fi
    ;;
    *)
    echo "Usage: $0 {start|stop}"
    exit 1
esac
exit 0
EOFOOo_init

sudo cp /tmp/openoffice /etc/init.d/openoffice
sudo chmod 0755 /etc/init.d/openoffice
echo "# Updating RC Services for OpenOffice headless server";
#sudo update-rc.d openoffice start 70 2 3 4 5 . stop 20 0 1 6 .
sudo update-rc.d openoffice defaults
sudo sed -i "s#\(^USER=openerp\)#\1\nPYTHONPATH=/usr/lib/openoffice.org/program/#g" /etc/init.d/openerp-server
}

function installfunc()
{
#if [ -x /usr/sbin/apache2 ] ; then
#        zenity --error --text="Apache package already installed. This script cannot be executed"
#        exit 0 
#fi

#if [ -x /etc/apache2 ] ; then
#        zenity --error --text="/etc/apache2 already exists. This script cannot be executed"
#        exit 0
#fi
if [ -x /var/lib/postgresql ] ; then
        zenity --error --text="Postgres already installed. This script cannot be executed"
        exit 0
fi
###################################################################################################################################

zenitybranch=$(zenity --list --text "Choose OpenERP branch to install" --radiolist  --column "Pick" --column "Branch" TRUE stable FALSE trunk);
if [ $? -eq 1 ]
then
zenity --warning --text="Cancel button pressed. Script execution aborted"
exit 0
fi
if [ "$zenitybranch" = "stable" ]; then 
STABLETRUNKLINK=5.0
STABLETRUNKVAR=stable
else
STABLETRUNKLINK=trunk
STABLETRUNKVAR=trunk
fi

# STABLE BRANCHES:
#lp:openobject-server/5.0
#lp:openobject-client/5.0
#lp:openobject-client-web/5.0
#lp:openobject-addons/5.0
#lp:openobject-addons/extra-5.0

# TRUNK BRANCHES:
#lp:openobject-server/trunk
#lp:openobject-client/trunk
#lp:openobject-client-web/trunk
#lp:openobject-addons/trunk
#lp:openobject-addons/extra-trunk
#lp:magentoerpconnect

APACHEEXTRAADDONSLIST="TRUE apache-https FALSE extra-addons TRUE firewall"
APACHEEXTRAADDONS=$(zenity --list --text "Would you like to set up Apache with HTTP Secure, OpenERP extra-addons and the Firewall?" --checklist --column "Pick" --column "Optional" $APACHEEXTRAADDONSLIST --separator=" ");
if [ $? -eq 1 ]
then
zenity --warning --text="Cancel button pressed. Script execution aborted"
exit 0
fi

APACHEHTTPS=`echo $APACHEEXTRAADDONS | awk '/apache-https/'`
if [ -n "$APACHEHTTPS" ];
then
   APACHEHTTPS=y
   if [ -x /usr/sbin/apache2 -o -x /etc/apache2 ]; then
        zenity --error --text="Apache already installed. Apache with HTTPS will not be setup in front of OpenERP Web"
        APACHEHTTPS=n  
   fi
else
   APACHEHTTPS=n
fi

EXTRAADDONSINSTALL=`echo $APACHEEXTRAADDONS | awk '/extra-addons/'`
if [ -n "$EXTRAADDONSINSTALL" ];
then
   EXTRAADDONSINSTALL=y
else
   EXTRAADDONSINSTALL=n
fi

FIREWALLINSTALL=`echo $APACHEEXTRAADDONS | awk '/firewall/'`
if [ -n "$FIREWALLINSTALL" ];
then
   FIREWALLINSTALL=y
else
   FIREWALLINSTALL=n
fi

TRUNKBRANCHESLIST="FALSE openerp-spain FALSE magentoerpconnect FALSE report-openoffice FALSE openetl"
trunkbranches=$(zenity --list --text "Select TRUNK branches to install" --width 300 --height=275 --checklist --column "Pick" --column "Branch" $TRUNKBRANCHESLIST --separator=" ");
if [ $? -eq 1 ]
then
zenity --warning --text="Cancel button pressed. Script execution aborted"
exit 0
fi

OPENERPSPAININSTALL=`echo $trunkbranches | awk '/openerp-spain/'`
if [ -n "$OPENERPSPAININSTALL" ];
then
   OPENERPSPAININSTALL=y
else
   OPENERPSPAININSTALL=n
fi

MAGENTOCONNECTINSTALL=`echo $trunkbranches | awk '/magentoerpconnect/'`
if [ -n "$MAGENTOCONNECTINSTALL" ];
then
   MAGENTOCONNECTINSTALL=y
else
   MAGENTOCONNECTINSTALL=n
fi

REPORTOPENOFFICEINSTALL=`echo $trunkbranches | awk '/report-openoffice/'`
if [ -n "$REPORTOPENOFFICEINSTALL" ];
then
   REPORTOPENOFFICEINSTALL=y
else
   REPORTOPENOFFICEINSTALL=n
fi

OPENETLINSTALL=`echo $trunkbranches | awk '/openetl/'`
if [ -n "$OPENETLINSTALL" ];
then
   OPENETLINSTALL=y
else
   OPENETLINSTALL=n
fi

url=$(zenity --entry \
   --title="OpenERP URL" \
   --text="Enter DNS name for your URL:" \
   --entry-text "openerpweb.com"); 
if [ $? -eq 1 ]
then
zenity --warning --text="Cancel button pressed. Script execution aborted"
exit 0
fi

# Modifying /etc/hosts file
for lang in `/sbin/ifconfig  | egrep 'inet |inet:'| cut -d: -f2 | awk '{ print $1}'`;
do
array=( "${array[@]}" "$lang" )
done


element_count=${#array[@]}
# Special syntax to extract number of elements in array.
index=0
LISTOPTIONS=""
while [ "$index" -lt "$element_count" ];
do    # List all the elements in the array.
  LISTOPTIONS=$LISTOPTIONS"FALSE ${array[$index]} "
  #    ${array[index]} also works because it's within ${ ... } brackets.
  let "index+=1"
done

if [ $element_count -lt 1 ];
then
zenity --error --text="No IP addresses available on your Ubuntu !! At least one IP address configured on Ubuntu is required. Script execution aborted."
#read -p "Press any key to continue…"
exit
fi
LISTOPTIONS=`echo $LISTOPTIONS | sed 's/FALSE/TRUE/i'`
ipaddrvar=$(zenity  --list  --text "List of IP addresses already configured on your Ubuntu system" --radiolist  --column "Pick" --column "IP address" $LISTOPTIONS); 
if [ $? -eq 1 ]
then
zenity --warning --text="Cancel button pressed. Script execution aborted"
exit 0
fi
passwvar=$(zenity --entry \
   --title="OpenERP Database" \
   --text="Please enter the Administrator Password:" \
   --entry-text "openerp");
if [ $? -eq 1 ]
then
zenity --warning --text="Cancel button pressed. Script execution aborted"
exit 0
fi

# SUDO issue:
CHECKSUDOPASSWORD=""
while [ -z $CHECKSUDOPASSWORD ]; do
zenity --entry --title="Temporary update of /etc/sudoers" --text="Enter your user password (sudo):" --hide-text --width=400 | sudo -S cp -fp /etc/sudoers /root/sudoers.backup
if [ $? -ne 0 ]; 
then
    zenity --error --text="Sorry, bad password"
else
CHECKSUDOPASSWORD="1"
fi
done


# MODIFY SUDOERS FILE TO ADD timestamp_timeout=60
cat > /tmp/sudoers <<"EOFSUDOERS"
# /etc/sudoers
#
# This file MUST be edited with the 'visudo' command as root.
#
# See the man page for details on how to write a sudoers file.
#

Defaults	env_reset,timestamp_timeout=60

# Uncomment to allow members of group sudo to not need a password
# %sudo ALL=NOPASSWD: ALL

# Host alias specification

# User alias specification

# Cmnd alias specification

# User privilege specification
root	ALL=(ALL) ALL

# Members of the admin group may gain root privileges
%admin ALL=(ALL) ALL


EOFSUDOERS

sudo cp -f /tmp/sudoers /etc/sudoers
sudo chmod 440 /etc/sudoers
sudo chown root.root /etc/sudoers
##################################################################################################################################
sudo -v
# sudo -v: "validate" option, sudo will update the user’s timestamp, prompting for the user’s password if necessary.  
# This extends the sudo timeout for another 15 minutes (or whatever the timeout is set to in sudoers) but does not run a command
##################################################################################################################################

#/usr/sbin/adduser --no-create-home --quiet --system --group openerp (ubuntu)
sudo /usr/sbin/adduser --quiet --system --group openerp 

(
PATH=/usr/bin:/sbin:/bin:/usr/sbin
echo "# DON'T PRESS ACCEPT/OK !!. Downloading and installing bzr";
if [ "$UBUNTURELEASE" = "8.04" -a ! -e /etc/apt/sources.list.d/bzr2.list ]; then
# Checking if bzr 2.0+ is already set up:
showbzr2state=$(aptitude show bzr | grep -i Version)
BZR2INSTALL=$(echo $showbzr2state | awk '/ 2./')
if [ -z "$BZR2INSTALL" ];
then
# BZR 2.0+ INSTALLATION (ubuntu 8.04 provides bzr 1.6)
# We are going to upgrade the repositories format to the 2a version. This will hopefully reduce the size of the checkout, speed up some operations and make it possible to use stacked branches reliably.
# From now on, Bazaar 2.0+ will be required to contribute to OpenERP. 
# http://julienthewys.blogspot.com/2010/02/code-repository-upgrade.html
echo "# Installing bzr 2.0+ in APT sources list";
echo "Installing bzr 2.0+ in APT sources list" >> $MYDESKTOP/OpenERP-updates.txt;
cat > /tmp/bzr2.list <<"bzrEOF"
deb http://ppa.launchpad.net/bzr/ubuntu hardy main
deb-src http://ppa.launchpad.net/bzr/ubuntu hardy main
bzrEOF
sudo cp /tmp/bzr2.list /etc/apt/sources.list.d/
sudo chown root.root /etc/apt/sources.list.d/bzr2.list
sudo chmod 644 /etc/apt/sources.list.d/bzr2.list
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys D702BF6B8C6C1EFD
sudo aptitude clean
sudo aptitude -f update
fi
fi
sudo aptitude install -y bzr

echo "# DON'T PRESS ACCEPT/OK !!. Downloading OpenERP Software from launchpad.net";
cd /opt
echo "# OpenERP Server: Downloading latest $STABLETRUNKVAR branch from launchpad.net";
echo "OpenERP Server: Downloading latest $STABLETRUNKVAR branch from launchpad.net" >> $MYDESKTOP/OpenERP-updates.txt;
sudo bzr branch lp:openobject-server/$STABLETRUNKLINK openerp-server >>$MYDESKTOP/OpenERP-updates.txt 2>&1
sudo -v
echo "# OpenERP Client: Downloading latest $STABLETRUNKVAR branch from launchpad.net";
echo "OpenERP Client: Downloading latest $STABLETRUNKVAR branch from launchpad.net" >> $MYDESKTOP/OpenERP-updates.txt;
sudo bzr branch lp:openobject-client/$STABLETRUNKLINK openerp-client >>$MYDESKTOP/OpenERP-updates.txt 2>&1
sudo -v
echo "# OpenERP Client Web: Downloading latest $STABLETRUNKVAR branch from launchpad.net";
echo "OpenERP Client Web: Downloading latest $STABLETRUNKVAR branch from launchpad.net" >> $MYDESKTOP/OpenERP-updates.txt;
sudo bzr branch lp:openobject-client-web/$STABLETRUNKLINK openerp-web >>$MYDESKTOP/OpenERP-updates.txt 2>&1
sudo -v
echo "# OpenERP Addons: Downloading latest $STABLETRUNKVAR branch from launchpad.net";
echo "OpenERP Addons: Downloading latest $STABLETRUNKVAR branch from launchpad.net" >> $MYDESKTOP/OpenERP-updates.txt;
sudo bzr branch lp:openobject-addons/$STABLETRUNKLINK addons >>$MYDESKTOP/OpenERP-updates.txt 2>&1
sudo -v
if [ "$EXTRAADDONSINSTALL" = "y" ]; then 
echo "# OpenERP Extra-Addons: Downloading latest $STABLETRUNKVAR branch from launchpad.net";
echo "OpenERP Extra-Addons: Downloading latest $STABLETRUNKVAR branch from launchpad.net" >> $MYDESKTOP/OpenERP-updates.txt;
sudo bzr branch lp:openobject-addons/extra-$STABLETRUNKLINK extra-addons >>$MYDESKTOP/OpenERP-updates.txt 2>&1
# Following line fixes this bug: "Import module menu is missing" https://bugs.launchpad.net/openobject-server/+bug/506662?comments=all
sudo sed -i "s/\(\"active\".*\)\(True,\)/\1False,/g" extra-addons/use_control/__terp__.py 
sudo -v
fi

if [ "$OPENERPSPAININSTALL" = "y" ]; then 
if [ "$EXTRAADDONSINSTALL" = "n" ]; then 
echo "# OpenERP Extra-Addons: Downloading latest $STABLETRUNKVAR branch from launchpad.net";
echo "OpenERP Extra-Addons: Downloading latest $STABLETRUNKVAR branch from launchpad.net" >> $MYDESKTOP/OpenERP-updates.txt;
sudo bzr branch lp:openobject-addons/extra-$STABLETRUNKLINK extra-addons >>$MYDESKTOP/OpenERP-updates.txt 2>&1
# Following line fixes this bug: "Import module menu is missing" https://bugs.launchpad.net/openobject-server/+bug/506662?comments=all
sudo sed -i "s/\(\"active\".*\)\(True,\)/\1False,/g" extra-addons/use_control/__terp__.py 
sudo -v
fi
echo "# Descargando OpenERP Spain con las últimas revisiones TRUNK de launchpad.net";
echo "OpenERP Spain: Descargando últimas revisiones TRUNK de launchpad.net" >> $MYDESKTOP/OpenERP-updates.txt;
sudo bzr branch lp:openerp-spain >>$MYDESKTOP/OpenERP-updates.txt 2>&1
sudo -v
fi

if [ "$MAGENTOCONNECTINSTALL" = "y" ]; then 
echo "# Magento OpenERP Connector: Downloading latest TRUNK branch from launchpad.net";
echo "Magento OpenERP Connector: Downloading latest TRUNK branch from launchpad.net" >> $MYDESKTOP/OpenERP-updates.txt;
sudo bzr branch lp:magentoerpconnect >>$MYDESKTOP/OpenERP-updates.txt 2>&1
sudo -v
fi

if [ "$REPORTOPENOFFICEINSTALL" = "y" ]; then 
echo "# report-openoffice: Downloading latest TRUNK branch from launchpad.net";
echo "report-openoffice: Downloading latest TRUNK branch from launchpad.net" >> $MYDESKTOP/OpenERP-updates.txt;
sudo bzr branch lp:report-openoffice >>$MYDESKTOP/OpenERP-updates.txt 2>&1
sudo -v
fi

if [ "$OPENETLINSTALL" = "y" ]; then 
echo "# openetl: Downloading latest TRUNK branch from launchpad.net";
echo "openetl: Downloading latest TRUNK branch from launchpad.net" >> $MYDESKTOP/OpenERP-updates.txt;
sudo bzr branch lp:openetl >>$MYDESKTOP/OpenERP-updates.txt 2>&1
sudo -v
fi

#########################################################################################################
# Stopping periodic command scheduler crond, i.e.:
# 	/etc/cron.daily/aptitude
#	/etc/cron.daily/apt  
#	/etc/apt/apt.conf.d/10periodic
echo "# DON'T PRESS ACCEPT/OK !!. Stopping periodic command scheduler crond";
sudo /etc/init.d/cron stop
#########################################################################################################

sudo aptitude -f update
echo "# DON'T PRESS ACCEPT/OK !!. Downloading and installing Python libraries";
sudo aptitude install -y python python-dev build-essential python-setuptools python-psycopg2 python-reportlab python-egenix-mxdatetime python-tz python-pychart python-pydot python-lxml python-libxslt1 python-vobject graphviz python-libxml2 python-imaging python-profiler;
# openerp-client requirements:
sudo aptitude install -y python-gtk2 python-glade2 xpdf; 
# Matplotlib & hippocanvas still required by openerp-client (not listed as a dependency for the package):
sudo aptitude install -y python-matplotlib python-hippocanvas;
# Required by openerp v6:
sudo aptitude install -y python-yaml python-mako
sudo -v

# required by openerp-server trunk V6:
if [ "$UBUNTURELEASE" = "8.04" ]; then
easy_install pywebdav
else 
# if ubuntu >= karmic 9.10 use this instead:
apt-get install -y python-webdav
fi

if [ "$OPENERPSPAININSTALL" = "y" ]; then 
echo "# DON'T PRESS ACCEPT/OK !!. Instalando language-pack-es";
sudo aptitude install -y language-pack-es language-support-es
fi

if [ "$UBUNTURELEASE" = "8.04" -o "$UBUNTURELEASE" = "9.10" ]; then
# To fix a new error "The required version of setuptools (>=0.6c11) is not available", march 11th 2010
echo "# DON'T PRESS ACCEPT/OK !!. Installing setuptools >=0.6c11";
sudo easy_install -U setuptools
fi

if [ "$REPORTOPENOFFICEINSTALL" = "y" ]; then 
installopenoffice3withreportopenofficelibraries
fi

echo "# DON'T PRESS ACCEPT/OK !!. Downloading and installing Postgres Database";
sudo aptitude install -y postgresql-$PSQLRELEASE postgresql-client-$PSQLRELEASE pgadmin3;
sudo -v
#sudo aptitude install postgresql-8.3 postgresql-client-8.3 -y
#Postgres Database configuration:
#sudo vi /etc/postgresql/8.3/main/pg_hba.conf
#Replace the following line:
    ## “local” is for Unix domain socket connections only
    #local all all ident sameuser
#with:
    ##”local” is for Unix domain socket connections only
    #local all all trust
#Please, note that "local all all md5" was set up in previous versions of this script, but database backup failed from openerp-web and
#openerp-client with this config (with an empty file as result)
sudo sed -i 's/\(local[[:space:]]*all[[:space:]]*all[[:space:]]*\)\(ident[[:space:]]*sameuser\)/\1trust/g' /etc/postgresql/$PSQLRELEASE/main/pg_hba.conf

#Restart Postgres:
echo "# DON'T PRESS ACCEPT/OK !!. Restarting Postgres Database";
sudo /etc/init.d/postgresql-$PSQLRELEASE restart
#Create a user account called openerp with password “openerp” and with privileges to create Postgres databases:
#sudo su postgres
#createuser openerp -P
#    Enter password for new role: (openerp)
#    Enter it again:
#    Shall the new role be a superuser? (y/n) n
#    Shall the new role be allowed to create databases? (y/n) y
#    Shall the new role be allowed to create more new roles? (y/n) n
echo "# DON'T PRESS ACCEPT/OK !!. Creating user openerp on Postgres Database";
sudo -u postgres createuser openerp --no-superuser --createdb --no-createrole 
sudo -u postgres psql template1 -U postgres -c "alter user openerp with password '$passwvar'"

echo "# DON'T PRESS ACCEPT/OK !!. Installing OpenERP Software";
cd /opt/openerp-server
sudo python setup.py install
sudo -v
cd /opt/openerp-client
sudo python setup.py install
cd /opt/openerp-web
#sudo easy_install -U openerp-web
sudo python setup.py install
sudo -v
cd /opt
sudo mkdir -p $ADDONSPATH
sudo cp -ru /opt/addons/* $ADDONSPATH
if [ "$EXTRAADDONSINSTALL" = "y" ]; then 
sudo cp -ru /opt/extra-addons/* $ADDONSPATH
fi
if [ "$UBUNTURELEASE" = "9.10" -a -d $OPENERPSERVERWRONGPATH/addons ]; then
# Adding workaround for bug in /opt/openerp-server/setup.py that puts import_xml.rng and base.sql into the wrong location
sudo cp -ru $OPENERPSERVERWRONGPATH/* $OPENERPSERVERPATH/
sudo chown -R openerp.root $ADDONSPATH
sudo chmod 755 $ADDONSPATH
fi
if [ "$OPENERPSPAININSTALL" = "y" ]; then 
if [ "$EXTRAADDONSINSTALL" = "n" ]; then 
sudo cp -ru /opt/extra-addons/* $ADDONSPATH
fi
sudo cp -ru /opt/openerp-spain/l10n_es/* $ADDONSPATH
sudo cp -ru /opt/openerp-spain/l10n_es_extras/* $ADDONSPATH
sudo cp -ru /opt/openerp-spain/extra_addons/* $ADDONSPATH
sudo cp -ru /opt/openerp-spain/l10n_ca_ES/* $ADDONSPATH
[ "$(ls -A /opt/openerp-spain/l10n_es_ES/)" ] && sudo cp -ru /opt/openerp-spain/l10n_es_ES/* $ADDONSPATH # "Not Empty" 
[ "$(ls -A /opt/openerp-spain/l10n_gl_ES/)" ] && sudo cp -ru /opt/openerp-spain/l10n_gl_ES/* $ADDONSPATH # "Not Empty"
[ "$(ls -A /opt/openerp-spain/l10n_gl_ES/)" ] && sudo cp -ru /opt/openerp-spain/l10n_eu_ES/* $ADDONSPATH # "Not Empty"
fi

if [ "$MAGENTOCONNECTINSTALL" = "y" ]; then 
sudo cp -ru /opt/magentoerpconnect $ADDONSPATH
fi
if [ "$REPORTOPENOFFICEINSTALL" = "y" ]; then 
sudo cp -ru /opt/report-openoffice/* $ADDONSPATH
fi
if [ "$OPENETLINSTALL" = "y" ]; then 
sudo cp -ru $ADDONSPATH/etl/lib/etl/ $SITEPACKAGESPATH/
sudo cp -ru /opt/openetl/lib/openetl/ $SITEPACKAGESPATH/
sudo cp -ru /opt/openetl/lib/etl_test/ $SITEPACKAGESPATH/
sudo chown -R root.root $SITEPACKAGESPATH/etl/
sudo chown -R root.root $SITEPACKAGESPATH/etl_test/
sudo chown -R root.root $SITEPACKAGESPATH/openetl/
fi

sudo chown -R openerp.root $ADDONSPATH
sudo -v
#####################
# Extending Open ERP
# To extend Open ERP you’ll need to copy modules into the addons directory. That’s in your server’s openerp-server directory (which differs between Windows, 
# Mac and some of the various Linux distributions and not available at all in the Windows all-in-one installer).
# You can add modules in two main ways – through the server, or through the client.
# To add new modules through the server is a conventional systems administration task. As rootuser or other suitable user, you’d put the module in the 
# addons directory and change its permissions to match those of the other modules.
# To add new modules through the client you must first change the permissions of the addonsdirectory of the server, so that it is writable by the server. 
# That will enable you to install Open ERP modules using the Open ERP client (a task ultimately carried out on the application server by the server software).
#
sudo chmod 755 $ADDONSPATH
###########################################
# Document Management Permissions: http://openobject.com/forum/topic13021.html?highlight=ftp
# sudo chown openerp $INSTALLPATH/lib/$PYTHONRELEASE/site-packages/openerp-server
sudo chown openerp $OPENERPSERVERPATH
#
echo "# DON'T PRESS ACCEPT/OK !!. Adding openerp-server and openerp-web init scripts and config files";
#####################################################################################
# openerp-server init script
#####################################################################################
cat > /tmp/openerp-server <<"EOF"
#!/bin/sh

### BEGIN INIT INFO
# Provides:		openerp-server
# Required-Start:	$syslog
# Required-Stop:	$syslog
# Should-Start:		$network
# Should-Stop:		$network
# Default-Start:	2 3 4 5
# Default-Stop:		0 1 6
# Short-Description:	Enterprise Resource Management software
# Description:		OpenERP is a complete ERP and CRM software.
### END INIT INFO

PATH=/sbin:/bin:/usr/sbin:/usr/bin
DAEMON=/usr/bin/openerp-server
NAME=openerp-server
DESC=openerp-server
USER=openerp

test -x ${DAEMON} || exit 0

set -e

case "${1}" in
	start)
		echo -n "Starting ${DESC}: "

		start-stop-daemon --start --quiet --pidfile /var/run/${NAME}.pid \
			--chuid ${USER} --background --make-pidfile \
			--exec ${DAEMON} -- --config=/etc/openerp-server.conf

		echo "${NAME}."
		;;

	stop)
		echo -n "Stopping ${DESC}: "

		start-stop-daemon --stop --quiet --pidfile /var/run/${NAME}.pid \
			--oknodo

		echo "${NAME}."
		;;

	restart|force-reload)
		echo -n "Restarting ${DESC}: "

		start-stop-daemon --stop --quiet --pidfile /var/run/${NAME}.pid \
			--oknodo

		sleep 1

		start-stop-daemon --start --quiet --pidfile /var/run/${NAME}.pid \
			--chuid ${USER} --background --make-pidfile \
			--exec ${DAEMON} -- --config=/etc/openerp-server.conf

		echo "${NAME}."
		;;

	*)
		N=/etc/init.d/${NAME}
		echo "Usage: ${NAME} {start|stop|restart|force-reload}" >&2
		exit 1
		;;
esac

exit 0

EOF

sudo cp /tmp/openerp-server /etc/init.d/
sudo chmod 0755 /etc/init.d/openerp-server
#Create /var/log/openerp with proper ownership:
sudo mkdir -p /var/log/openerp
sudo touch /var/log/openerp/openerp.log
sudo chown -R openerp.root /var/log/openerp/

sudo sed -i "s#/usr/bin/openerp-server#$INSTALLPATH/bin/openerp-server#g" /etc/init.d/openerp-server

#####################################################################################
# openerp-server config file
#####################################################################################
cat > /tmp/openerp-server.conf <<"EOF2"
# /etc/openerp-server.conf(5) - configuration file for openerp-server(1)

[options]
# Enable the debugging mode (default False).
#verbose = True 

# The file where the server pid will be stored (default False).
#pidfile = /var/run/openerp.pid

# The file where the server log will be stored (default False).
logfile = /var/log/openerp/openerp.log

# The IP address on which the server will bind.
# If empty, it will bind on all interfaces (default empty).
#interface = localhost
interface = 
# The TCP port on which the server will listen (default 8069).
port = 8069

# Enable debug mode (default False).
#debug_mode = True 

# Launch server over https instead of http (default False).
secure = False

# Specify the SMTP server for sending email (default localhost).
smtp_server = localhost

# Specify the SMTP user for sending email (default False).
smtp_user = False

# Specify the SMTP password for sending email (default False).
smtp_password = False

# Specify the database name.
db_name =

# Specify the database user name (default None).
db_user = openerp

# Specify the database password for db_user (default None).
db_password = 

# Specify the database host (default localhost).
db_host =

# Specify the database port (default None).
db_port = 5432

EOF2

sudo cp /tmp/openerp-server.conf /etc/
sudo chown root.root /etc/openerp-server.conf
sudo chmod 644 /etc/openerp-server.conf

sudo sed -i "s/db_password =/db_password = $passwvar/g" /etc/openerp-server.conf

#####################################################################################
# openerp-web init script and openerp-web.cfg
#####################################################################################
cat > /tmp/openerp-web <<"EOF7"
#!/bin/sh

### BEGIN INIT INFO
# Provides:             openerp-web
# Required-Start:       $syslog
# Required-Stop:        $syslog
# Should-Start:         $network
# Should-Stop:          $network
# Default-Start:        2 3 4 5
# Default-Stop:         0 1 6
# Short-Description:    OpenERP Web - the Web Client of the OpenERP
# Description:          OpenERP is a complete ERP and CRM software.
### END INIT INFO

PATH=/sbin:/bin:/usr/sbin:/usr/bin
DAEMON=/usr/bin/openerp-web
NAME=openerp-web
DESC=openerp-web

# Specify the user name (Default: openerp).
USER="openerp"

# Specify an alternate config file (Default: /etc/openerp-web.cfg).
CONFIGFILE="/etc/openerp-web.cfg"

# pidfile
PIDFILE=/var/run/$NAME.pid

# Additional options that are passed to the Daemon.
DAEMON_OPTS="-c $CONFIGFILE"

[ -x $DAEMON ] || exit 0
[ -f $CONFIGFILE ] || exit 0

checkpid() {
    [ -f $PIDFILE ] || return 1
    pid=`cat $PIDFILE`
    [ -d /proc/$pid ] && return 0
    return 1
}

if [ -f /lib/lsb/init-functions ] || [ -f /etc/gentoo-release ] ; then

    do_start() {
        start-stop-daemon --start --quiet --pidfile $PIDFILE \
            --chuid $USER  --background --make-pidfile \
            --exec $DAEMON -- $DAEMON_OPTS
        
        RETVAL=$?
        sleep 5         # wait for few seconds

        return $RETVAL
    }

    do_stop() {
        start-stop-daemon --stop --quiet --pidfile $PIDFILE --oknodo

        RETVAL=$?
        sleep 2         # wait for few seconds
        rm -f $PIDFILE  # remove pidfile

        return $RETVAL
    }

    do_restart() {
        start-stop-daemon --stop --quiet --pidfile $PIDFILE --oknodo

        sleep 2         # wait for few seconds
        rm -f $PIDFILE  # remove pidfile

        start-stop-daemon --start --quiet --pidfile $PIDFILE \
            --chuid $USER --background --make-pidfile \
            --exec $DAEMON -- $DAEMON_OPTS

        RETVAL=$?
        sleep 5         # wait for few seconds

        return $RETVAL
    }

else
    
    do_start() {
        $DAEMON $DAEMON_OPTS > /dev/null 2>&1 &
        
        RETVAL=$?
        sleep 5         # wait for few seconds

        echo $! > $PIDFILE  # create pidfile

        return $RETVAL
    }

    do_stop() {

        pid=`cat $PIDFILE`
        kill -15 $pid

        RETVAL=$?
        sleep 2         # wait for few seconds
        rm -f $PIDFILE  # remove pidfile

        return $RETVAL
    }

    do_restart() {

        if [ -f $PIDFILE ]; then
            do_stop
        fi

        do_start

        return $?
    }

fi

start_daemon() {

    if [ -f $PIDFILE ]; then
        echo "pidfile already exists: $PIDFILE"
        exit 1
    fi

    echo -n "Starting $DESC: "

    do_start

    checkpid

    if [ $? -eq 1 ]; then                
        rm -f $PIDFILE
        echo "failed."
        exit 1
    fi

    echo "done."
}

stop_daemon() {

    checkpid

    if [ $? -eq 1 ]; then
        exit 0
    fi

    echo -n "Stopping $DESC: "

    do_stop

    if [ $? -eq 1 ]; then
        echo "failed."
        exit 1
    fi

    echo "done."
}

restart_daemon() {

    echo -n "Reloading $DESC: "

    do_restart

    checkpid

    if [ $? -eq 1 ]; then                
        rm -f $PIDFILE
        echo "failed."
        exit 1
    fi

    echo "done."
}

status_daemon() {

    echo -n "Checking $DESC: "

    checkpid

    if [ $? -eq 1 ]; then
        echo "stopped."
    else
        echo "running."
    fi
}

case "$1" in
    start) start_daemon ;;
    stop) stop_daemon ;;
    restart|force-reload) restart_daemon ;;
    status) status_daemon ;;
    *)
        N=/etc/init.d/$NAME
        echo "Usage: $N {start|stop|restart|force-reload|status}" >&2
        exit 1
        ;;
esac

exit 0
EOF7

#sudo cp /usr/lib/python2.5/site-packages/openerp_web-5.0.1_0-py2.5.egg/scripts/openerp-web /etc/init.d/
sudo cp /tmp/openerp-web /etc/init.d/
sudo chmod 0755 /etc/init.d/openerp-web
sudo sed -i "s#/usr/bin/openerp-web#$INSTALLPATH/bin/openerp-web#g" /etc/init.d/openerp-web

cat > /tmp/openerp-web.cfg <<"EOF8"
[global]

# Some server parameters that you may want to tweak
server.socket_host = "0.0.0.0"
server.socket_port = 8080

# Sets the number of threads the server uses
server.thread_pool = 10

server.environment = "development"

# Simple code profiling
server.profile_on = False
server.profile_dir = "profile"

# if this is part of a larger site, you can set the path
# to the TurboGears instance here
#server.webpath = ""

# Set to True if you are deploying your App behind a proxy
# e.g. Apache using mod_proxy
tools.proxy.on = True

# If your proxy does not add the X-Forwarded-Host header, set
# the following to the *public* host url.
#tools.proxy.base = 'http://mydomain.com'

# logging
#log.access_file = "/var/log/openerp-web/access.log"
#log.error_file = "/var/log/openerp-web/error.log"

# OpenERP Server
[openerp]
host = 'localhost'
port = '8070'
protocol = 'socket'

# Web client settings
[openerp-web]
# filter dblists based on url pattern?
# NONE: No Filter
# EXACT: Exact Hostname
# UNDERSCORE: Hostname_
# BOTH: Exact Hostname or Hostname_

dblist.filter = 'NONE'

# whether to show Databases button on Login screen or not
dbbutton.visible = True

# will be applied on company logo
company.url = ''

# options to limit data rows in M2M/O2M lists, will be overriden 
# with limit="5", min_rows="5" attributes in the tree view definitions
child.listgrid.limit = 5
child.listgrid.min_rows = 5
EOF8


sudo sed -i "s#\#tools.proxy.base = \'http://mydomain.com\'#tools.proxy.base = \'http://$url\'#g" /tmp/openerp-web.cfg
#sudo cp /usr/lib/python2.5/site-packages/openerp_web-5.0.1_0-py2.5.egg/config/default.cfg /etc/openerp-web.cfg
sudo cp /tmp/openerp-web.cfg /etc/openerp-web.cfg
sudo chown root.root /etc/openerp-web.cfg
sudo chmod 644 /etc/openerp-web.cfg

#OpenERP Web configuration:
#    tools.proxy.on = True
#sudo sed -i "s/^#tools\.proxy\.on.*/tools.proxy.on = True/g" /etc/openerp-web.cfg 

#Create /var/log/openerp-web.log with proper ownership:
sudo mkdir -p /var/log/openerp-web
sudo touch /var/log/openerp-web/access.log
sudo touch /var/log/openerp-web/error.log
sudo chown -R openerp.root /var/log/openerp-web/

echo "# DON'T PRESS ACCEPT/OK !!. Updating RC Services";
#Now run following command to start the OpenERP Web automatically on system startup (Debian/Ubuntu):
sudo update-rc.d openerp-server start 21 2 3 4 5 . stop 21 0 1 6 .
sudo update-rc.d openerp-web start 70 2 3 4 5 . stop 20 0 1 6 .

############################################################################################
if [ "$APACHEHTTPS" = "y" ]; then 
echo "# DON'T PRESS ACCEPT/OK !!. Downloading and Installing Apache";
#HTTPS and Proxy with Apache
sudo aptitude -y install apache2

if [ "$UBUNTURELEASE" = "9.10" ];
then
sudo a2enmod ssl
sudo a2ensite default-ssl
sudo a2enmod rewrite
sudo a2enmod suexec
sudo a2enmod include
sudo a2enmod proxy
sudo a2enmod proxy_http
sudo a2enmod proxy_connect
sudo a2enmod proxy_ftp

sudo sed -i "s/\(^ServerRoot.*\)/\1\nServerName localhost/g" /etc/apache2/apache2.conf
#Forcing Apache to redirect HTTP traffic to HTTPS
sudo sed -i "s/\(ServerAdmin.*\)/\1\nServerName $url\nRedirect \/ https:\/\/$url\//g" /etc/apache2/sites-available/default
sudo sed -i "s/\(ServerAdmin.*\)/\1\nServerName $url\n\<Proxy \*\>\nOrder deny,allow\nAllow from all\n\<\/Proxy\>\nProxyRequests Off\nProxyPass        \/   http:\/\/127.0.0.1:8080\/\nProxyPassReverse \/   http:\/\/127.0.0.1:8080\/\nSetEnv proxy-nokeepalive 1/g" /etc/apache2/sites-available/default-ssl
sudo sed -i "s/\(^127\.0\.1\.1[[:space:]]*\)\([[:alnum:]].*\)/#\0\n$ipaddrvar $url \2/g" /etc/hosts
else
# ubuntu 8.04
############################################################################################
# /etc/apache2/sites-available/default-ssl (Available in Ubuntu9.04, but not in Ubuntu8.04)
# apache2-ssl-certificate script/package is missing in Ubuntu8.04
############################################################################################
echo "# DON'T PRESS ACCEPT/OK !!. Configuring Apache";
cat > /tmp/default <<"EOF3"
NameVirtualHost *:80
<VirtualHost *:80>
        ServerAdmin webmaster@localhost
        ServerName openerpweb.com
        Redirect / https://openerpweb.com/

        DocumentRoot /var/www/
        <Directory />
                Options FollowSymLinks
                AllowOverride None
        </Directory>
        <Directory /var/www/>
                Options Indexes FollowSymLinks MultiViews
                AllowOverride None
                Order allow,deny
                allow from all
        </Directory>

        ScriptAlias /cgi-bin/ /usr/lib/cgi-bin/
        <Directory "/usr/lib/cgi-bin">
                AllowOverride None
                Options +ExecCGI -MultiViews +SymLinksIfOwnerMatch
                Order allow,deny
                Allow from all
        </Directory>

        ErrorLog /var/log/apache2/error.log

        # Possible values include: debug, info, notice, warn, error, crit,
        # alert, emerg.
        LogLevel warn

        CustomLog /var/log/apache2/access.log combined
        ServerSignature On

    Alias /doc/ "/usr/share/doc/"
    <Directory "/usr/share/doc/">
        Options Indexes MultiViews FollowSymLinks
        AllowOverride None
        Order deny,allow
        Deny from all
        Allow from 127.0.0.0/255.0.0.0 ::1/128
    </Directory>

</VirtualHost>
EOF3

sudo cp /tmp/default /etc/apache2/sites-available/default
sudo chown root.root /etc/apache2/sites-available/default
sudo chmod 644 /etc/apache2/sites-available/default

cat > /tmp/default-ssl <<"EOF4"
NameVirtualHost *:443
<VirtualHost *:443>
	ServerName openerpweb.com
        ServerAdmin webmaster@localhost
	SSLEngine on
	SSLOptions +FakeBasicAuth +ExportCertData +StrictRequire	
	SSLCertificateFile /etc/ssl/certs/ssl-cert-snakeoil.pem
	SSLCertificateKeyFile /etc/ssl/private/ssl-cert-snakeoil.key
                
	<Proxy *>
	  Order deny,allow
	  Allow from all
	</Proxy>
	ProxyRequests Off
	ProxyPass        /   http://127.0.0.1:8080/
	ProxyPassReverse /   http://127.0.0.1:8080/

        RequestHeader set "X-Forwarded-Proto" "https"

        # Fix IE problem (http error 408/409)
        SetEnv proxy-nokeepalive 1

        ErrorLog /var/log/apache2/error-ssl.log
        # Possible values include: debug, info, notice, warn, error, crit,
        # alert, emerg.
        LogLevel warn
        CustomLog /var/log/apache2/access-ssl.log combined
        ServerSignature On
</VirtualHost>
EOF4

sudo cp /tmp/default-ssl /etc/apache2/sites-available/default-ssl
sudo chown root.root /etc/apache2/sites-available/default-ssl
sudo chmod 644 /etc/apache2/sites-available/default-ssl
echo "# DON'T PRESS ACCEPT/OK !!. Making SSL certificate for Apache";
# sudo mkdir /etc/apache2/ssl
# sudo /usr/sbin/make-ssl-cert /usr/share/ssl-cert/ssleay.cnf /etc/apache2/ssl/apache.pem
sudo /usr/sbin/make-ssl-cert generate-default-snakeoil --force-overwrite
# Snakeoil certificate files:
# /usr/share/ssl-cert/ssleay.cnf
# /etc/ssl/certs/ssl-cert-snakeoil.pem
# /etc/ssl/private/ssl-cert-snakeoil.key
echo "# DON'T PRESS ACCEPT/OK !!. Enabling Apache Modules";
# Apache Modules:
sudo a2enmod ssl
# We enable default-ssl site after creating "/etc/apache2/sites-available/default-ssl" file (not available in Ubuntu8.04)
sudo a2ensite default-ssl
sudo a2enmod rewrite
sudo a2enmod suexec
sudo a2enmod include
sudo a2enmod proxy
sudo a2enmod proxy_http
sudo a2enmod proxy_connect
sudo a2enmod proxy_ftp
sudo a2enmod headers
#Add your server’s IP address and URL in /etc/hosts:
#    $ sudo vi /etc/hosts
#Replace
#    127.0.0.1 localhost
#    127.0.0.1 yourhostname yourhostnamealias
#With
#
#    127.0.0.1 localhost
#    192.168.x.x openerpweb.com yourhostname yourhostnamealias
sudo sed -i "s/\(^127\.0\.1\.1[[:space:]]*\)\([[:alnum:]].*\)/#\0\n$ipaddrvar $url \2/g" /etc/hosts
sudo sed -i "s/openerpweb\.com/$url/g" /etc/apache2/sites-available/default
sudo sed -i "s/openerpweb\.com/$url/g" /etc/apache2/sites-available/default-ssl
fi

echo "# DON'T PRESS ACCEPT/OK !!. Restarting Apache";
sudo /etc/init.d/apache2 restart
fi

#########################################################################################################
if [ "$REPORTOPENOFFICEINSTALL" = "y" ]; then 
enablingopenofficeheadlessserver
fi
if [ -e /etc/init.d/openoffice ]; then
echo "# Starting OpenOffice headless server";
# Sin hacer primero un stop, soffice.bin no es arrancado con el "openoffice start" en este script
sudo /etc/init.d/openoffice stop >/dev/null 2>&1
sudo /etc/init.d/openoffice start >/dev/null 2>&1
fi
#########################################################################################################
if [ "$FIREWALLINSTALL" = "y" ]; then 
echo "# DON'T PRESS ACCEPT/OK !!. Enabling Firewall settings";
# FIREWALL:
sudo ufw enable
sudo ufw allow ssh

if [ "$APACHEHTTPS" = "y" ]; then 
sudo ufw allow http
sudo ufw allow https
else
sudo ufw allow 8080/tcp 
fi
# OpenERP port (GTK client):
sudo ufw allow 8069/tcp 
# OpenERP port (GTK client):
sudo ufw allow 8070/tcp 
fi

echo "# DON'T PRESS ACCEPT/OK !!. Starting openerp-server and openerp-web services";
sudo /etc/init.d/openerp-server start
sudo /etc/init.d/openerp-web start
echo "# DON'T PRESS ACCEPT/OK !!. Making Desktop Icons for openerp-client and openerp-web URL";
#################################################################################
#echo "# DON'T PRESS ACCEPT/OK !!. aptitude autoremove";
#sudo -v
#sudo apt-get autoremove -y 
#########################################################################################################
# Starting periodic command scheduler crond, i.e.:
# 	/etc/cron.daily/aptitude
#	/etc/cron.daily/apt  
#	/etc/apt/apt.conf.d/10periodic
echo "# DON'T PRESS ACCEPT/OK !!. Starting periodic command scheduler crond";
sudo /etc/init.d/cron start
#########################################################################################################
echo "# DON'T PRESS ACCEPT/OK !!. Restoring original /etc/sudoers with default timestamp_timeout";
sudo cp -fp /root/sudoers.backup /etc/sudoers 
sudo -v
#################################################################################
# This code makes links in your Desktop for openerp-client and openerpweb URL :
#################################################################################
cat > $MYDESKTOP/openerp-client.desktop <<"EOF5"
[Desktop Entry]
Version=1.0
Encoding=UTF-8
Name=openerp-client
Type=Application
Terminal=false
Name[es_ES]=openerp-client
Exec=/usr/bin/openerp-client
Comment[es_ES]=OpenERP GTK client
Comment=OpenERP GTK client
GenericName[en_US]=
EOF5

sed -i "s#/usr/bin/openerp-client#$INSTALLPATH/bin/openerp-client#g" $MYDESKTOP/openerp-client.desktop

##########################################################################################################################
# Bug #484657: 5.0.6 pixmaps location wrong in same cases (Ubuntu 9.10)
# https://bugs.launchpad.net/openobject-client/+bug/484657
# Adding workaround for bug in $HOME/.openerprc on Ubuntu 9.10
if [ "$UBUNTURELEASE" = "9.10" ]; then
# Ubuntu 9.10 requires execution properties on openerp-client icon:
chmod +x $MYDESKTOP/openerp-client.desktop
# have to run openerp-client for first time to creat $HOME/.openerpc (but fails due to the bug)
$INSTALLPATH/bin/openerp-client /dev/null 2>&1 
# apply the workaround
sed -i "s#/usr/share#/usr/local/share#g" $HOME/.openerprc
fi
##########################################################################################################################

cat > $MYDESKTOP/OpenERPweb.desktop <<"EOF6"
[Desktop Entry]
Version=1.0
Encoding=UTF-8
Name=link to OpenERP Web
Type=Link
URL=http://openerpweburl
Icon=gnome-fs-bookmark
EOF6
if [ "$APACHEHTTPS" = "y" ]; then
sed -i "s/openerpweburl/$url/g" $MYDESKTOP/OpenERPweb.desktop
else
sed -i "s/openerpweburl/$url:8080/g" $MYDESKTOP/OpenERPweb.desktop
fi
###################################################################################################
# Workaround for this error 'No handlers could be found for logger “bzr”' when user runs bzr after this script is executed
# This usually just means you don’t have permission to write to the log. Sometimes it ends up belonging to root (because of sudo bzr)
sudo chown $USER ~/.bzr.log
chmod 644 ~/.bzr.log
###################################################################################################
echo "# Installation of OpenERP Completed. PRESS ACCEPT";
clear
echo > $MYDESKTOP/OpenERP-README.txt
echo "------------------------------------------------------------------------------------------------------------------------------------------------" >> $MYDESKTOP/OpenERP-README.txt
echo " THE REMAINING STEPS CAN BE CONFIGURED FROM THE WEB INTERFACE (OPENERP WEB)" >> $MYDESKTOP/OpenERP-README.txt
echo >> $MYDESKTOP/OpenERP-README.txt
if [ "$APACHEHTTPS" = "y" ]; then 
echo " 1. Register the DNS Name \"$url\" with its corresponding IP address ($ipaddrvar)." >> $MYDESKTOP/OpenERP-README.txt
echo "   \"$url\" is the external URL of OpenERP Web. Make sure this URL is reachable by your Web clients (Open ERP users)" >> $MYDESKTOP/OpenERP-README.txt
echo "    In Linux this can be done locally by adding the following line to /etc/hosts file:" >> $MYDESKTOP/OpenERP-README.txt
echo >> $MYDESKTOP/OpenERP-README.txt
echo "    	$ipaddrvar $url" >> $MYDESKTOP/OpenERP-README.txt
echo >> $MYDESKTOP/OpenERP-README.txt
echo "    The hosts file is located in different locations in different operating systems and versions: \"http://en.wikipedia.org/wiki/Hosts_file\"" >> $MYDESKTOP/OpenERP-README.txt
echo "    The hosts file is a computer file used to store information on where to find a node on a computer network. " >> $MYDESKTOP/OpenERP-README.txt
echo "    This file maps hostnames to IP addresses. The hosts file is used as a supplement to (or a replacement of) the Domain Name System (DNS) on " >> $MYDESKTOP/OpenERP-README.txt
echo "    networks of varying sizes. Unlike DNS, the hosts file is under the control of the local computer's administrator" >> $MYDESKTOP/OpenERP-README.txt
echo >> $MYDESKTOP/OpenERP-README.txt
echo " 2. Your OpenERP Web Service can now be reached with a web browser at: \"http://$url\"" >> $MYDESKTOP/OpenERP-README.txt
else
echo " 1. Your OpenERP Web Service can now be reached with a web browser at: \"http://$ipaddrvar:8080\"" >> $MYDESKTOP/OpenERP-README.txt
echo " 2. Your OpenERP Web Service can now be reached with a web browser at: \"http://localhost:8080\"" >> $MYDESKTOP/OpenERP-README.txt
fi
echo >> $MYDESKTOP/OpenERP-README.txt
echo " 3. WELCOME TO OPENERP: -> Click on \"Databases\" -> CREATE A NEW DATABASE:" >> $MYDESKTOP/OpenERP-README.txt
echo "    3.1  Super Administrator Password: admin" >> $MYDESKTOP/OpenERP-README.txt
echo "    3.2  New Name of the database: xxx " >> $MYDESKTOP/OpenERP-README.txt
echo "    3.3  Load Demo Data (y/n)" >> $MYDESKTOP/OpenERP-README.txt
echo "    3.4  Default language: ... " >> $MYDESKTOP/OpenERP-README.txt
echo "    3.5  Administrator Password: $passwvar" >> $MYDESKTOP/OpenERP-README.txt
echo "    3.6  Confirm Administrator Password: $passwvar" >> $MYDESKTOP/OpenERP-README.txt
echo  >> $MYDESKTOP/OpenERP-README.txt
echo " 4. WELCOME TO OPENERP:" >> $MYDESKTOP/OpenERP-README.txt
echo "    4.1 Database: xxx " >> $MYDESKTOP/OpenERP-README.txt
echo "    4.2 Administrator Username: admin " >> $MYDESKTOP/OpenERP-README.txt
echo "    4.3 Administrator Password: $passwvar" >> $MYDESKTOP/OpenERP-README.txt
echo "    4.4 Click on \"Login\"" >> $MYDESKTOP/OpenERP-README.txt
echo >> $MYDESKTOP/OpenERP-README.txt
echo " 5. INSTALLATION & CONFIGURATION. You will now be asked to install and configure modules and users required by your Enterprise" >> $MYDESKTOP/OpenERP-README.txt
echo "    5.1 Click on \"Logout\"" >> $MYDESKTOP/OpenERP-README.txt
echo >> $MYDESKTOP/OpenERP-README.txt
echo " 6. WELCOME TO OPENERP: You can now log in with the following users" >> $MYDESKTOP/OpenERP-README.txt
echo "    6.1 User \"demo\" / Password \"demo\", in case you clicked on \"Load Demo Data\"" >> $MYDESKTOP/OpenERP-README.txt
echo "    6.2 User \"admin\" / Password \"$passwvar\"" >> $MYDESKTOP/OpenERP-README.txt
echo "    6.3 Users created by you during step #4" >> $MYDESKTOP/OpenERP-README.txt
echo "------------------------------------------------------------------------------------------------------------------------------------------------" >> $MYDESKTOP/OpenERP-README.txt
echo " Notes:" >> $MYDESKTOP/OpenERP-README.txt
echo "    * OpenERP GTK Client can be run as non-root with the command \"openerp-client\"" >> $MYDESKTOP/OpenERP-README.txt
echo "        (Make sure you enable X11 Forwarding on your SSH remote session)" >> $MYDESKTOP/OpenERP-README.txt
echo "    * Ports 8069 & 8070 are open for remote access of OpenERP GTK clients " >> $MYDESKTOP/OpenERP-README.txt
echo "    * Database backup/restore can be done with pg_dump and pg_restore (CLI) or pgAdmin3 (GUI)" >> $MYDESKTOP/OpenERP-README.txt
echo "      Check http://www.postgresql.org/docs/$PSQLRELEASE/interactive/index.html" >> $MYDESKTOP/OpenERP-README.txt
echo >> $MYDESKTOP/OpenERP-README.txt 
echo " DATABASE BACKUP WITH PGADMIN:" >> $MYDESKTOP/OpenERP-README.txt
echo " pgAdmin3 : pgAdmin is the leading graphical Open Source management, development and administration tool for PostgreSQL. " >> $MYDESKTOP/OpenERP-README.txt
echo "            Run \"pgAdmin3\": Applications -> System Tools -> pgAdmin III :" >> $MYDESKTOP/OpenERP-README.txt
echo "            Name=XXX   Database:postgres   Server:localhost   User:openerp   Password:$passwvar" >> $MYDESKTOP/OpenERP-README.txt 
echo " Run pgadmin3 locally, then connect to the database server, right click on the database name and select Backup from the contextual menu. " >> $MYDESKTOP/OpenERP-README.txt
echo " Use COMPRESS mode (native and efficient) to save the backup. Still using pgadmin3, connect on the destination server, " >> $MYDESKTOP/OpenERP-README.txt
echo " create a new database, right click on its name and select Restore." >> $MYDESKTOP/OpenERP-README.txt
echo >> $MYDESKTOP/OpenERP-README.txt
if [ "$FIREWALLINSTALL" = "y" ]; then 
echo " DOCUMENT MODULE: the “Browse Files Using FTP” option is setup by default for localhost (server side) on port 8021. " >> $MYDESKTOP/OpenERP-README.txt
echo " This can be configured with the wizard and by opening that port on the firewall (sudo ufw allow 8021/tcp) " >> $MYDESKTOP/OpenERP-README.txt
echo >> $MYDESKTOP/OpenERP-README.txt
fi
echo " MAIL SERVER SETUP:" >> $MYDESKTOP/OpenERP-README.txt
echo " Remember to set up your mail server specified in /etc/openerp-server.conf file if you want OpenERP to send emails" >> $MYDESKTOP/OpenERP-README.txt
echo >> $MYDESKTOP/OpenERP-README.txt
echo " REPORT-OPENOFFICE SETUP:" >> $MYDESKTOP/OpenERP-README.txt
echo " URL: http://kndati.lv/index.php/en/openerp/open-erp-addons/reporting-engine" >> $MYDESKTOP/OpenERP-README.txt
echo " Startup script for openoffice headless mode:" >> $MYDESKTOP/OpenERP-README.txt 
echo " 	    sudo /etc/init.d/openoffice stop" >> $MYDESKTOP/OpenERP-README.txt
echo " 	    sudo /etc/init.d/openoffice start" >> $MYDESKTOP/OpenERP-README.txt
echo >> $MYDESKTOP/OpenERP-README.txt
echo " OPENETL SETUP:" >> $MYDESKTOP/OpenERP-README.txt
echo "      Install the module \"etl_interface\"" >> $MYDESKTOP/OpenERP-README.txt
echo >> $MYDESKTOP/OpenERP-README.txt 
echo " More information at http://opensourceconsulting.wordpress.com/2009/09/15/openerp-all-in-one-installer-update-for-dummies/" >> $MYDESKTOP/OpenERP-README.txt
echo >> $MYDESKTOP/OpenERP-README.txt
cat $MYDESKTOP/OpenERP-README.txt | zenity --title="Installation of OpenERP Completed. Content of OpenERP-README.txt" --text-info --width 1000 --height=700
) |  (if $(zenity --progress \
  --title="Installing OpenERP on Ubuntu" \
  --text="Downloading OpenERP Software from launchpad.net" \
  --pulsate);
then
  echo "Installation of OpenERP Completed.";
else
  # zenity's "--auto-kill" opcion does not work due to a bug. This is a workaround
  kill -9 $$
fi)
}


function check4newrevisionsfunc()
{
local  __newrevisionsfound=$1
local  newrevisionsfound=0

local  __listbranches=$2
local  listbranches=""

cd /opt/openerp-server
sudo bzr missing > /tmp/check4newrevisions.txt
tail -1 /tmp/check4newrevisions.txt > /tmp/newrevisions.txt
NEWREVISIONS=`awk '/Branches are up to date/ {print $0}' /tmp/newrevisions.txt`
if [ -z "$NEWREVISIONS" ];
then
   newrevisionsfound=1
   listbranches=$listbranches"TRUE openerp-server "
else
   listbranches=$listbranches"FALSE openerp-server "
fi
cd /opt/openerp-client
sudo bzr missing > /tmp/check4newrevisions.txt
tail -1 /tmp/check4newrevisions.txt > /tmp/newrevisions.txt
NEWREVISIONS=`awk '/Branches are up to date/ {print $0}' /tmp/newrevisions.txt`
if [ -z "$NEWREVISIONS" ];
then
   newrevisionsfound=1
   listbranches=$listbranches"TRUE openerp-client "
else
   listbranches=$listbranches"FALSE openerp-client "
fi
cd /opt/openerp-web
sudo bzr missing > /tmp/check4newrevisions.txt
tail -1 /tmp/check4newrevisions.txt > /tmp/newrevisions.txt
NEWREVISIONS=`awk '/Branches are up to date/ {print $0}' /tmp/newrevisions.txt`
if [ -z "$NEWREVISIONS" ];
then
   newrevisionsfound=1
   listbranches=$listbranches"TRUE openerp-web "
else
   listbranches=$listbranches"FALSE openerp-web "
fi
cd /opt/addons
sudo bzr missing > /tmp/check4newrevisions.txt
tail -1 /tmp/check4newrevisions.txt > /tmp/newrevisions.txt
NEWREVISIONS=`awk '/Branches are up to date/ {print $0}' /tmp/newrevisions.txt`
if [ -z "$NEWREVISIONS" ];
then
   newrevisionsfound=1
   listbranches=$listbranches"TRUE Addons "
else
   listbranches=$listbranches"FALSE Addons "
fi

if [ -d /opt/extra-addons ];
then
cd /opt/extra-addons
sudo bzr missing > /tmp/check4newrevisions.txt
tail -1 /tmp/check4newrevisions.txt > /tmp/newrevisions.txt
NEWREVISIONS=`awk '/Branches are up to date/ {print $0}' /tmp/newrevisions.txt`
if [ -z "$NEWREVISIONS" ];
then
   newrevisionsfound=1
   listbranches=$listbranches"TRUE extra-addons "
else
   listbranches=$listbranches"FALSE extra-addons "
fi
else
   listbranches=$listbranches"FALSE extra-addons "
fi

if [ -d /opt/openerp-spain ];
then
cd /opt/openerp-spain
sudo bzr missing > /tmp/check4newrevisions.txt
tail -1 /tmp/check4newrevisions.txt > /tmp/newrevisions.txt
NEWREVISIONS=`awk '/Branches are up to date/ {print $0}' /tmp/newrevisions.txt`
if [ -z "$NEWREVISIONS" ];
then
   newrevisionsfound=1
   listbranches=$listbranches"TRUE openerp-spain "
else
   listbranches=$listbranches"FALSE openerp-spain "
fi
else
   listbranches=$listbranches"FALSE openerp-spain "
fi

if [ -d /opt/magentoerpconnect ];
then
cd /opt/magentoerpconnect
sudo bzr missing > /tmp/check4newrevisions.txt
tail -1 /tmp/check4newrevisions.txt > /tmp/newrevisions.txt
NEWREVISIONS=`awk '/Branches are up to date/ {print $0}' /tmp/newrevisions.txt`
if [ -z "$NEWREVISIONS" ];
then
   newrevisionsfound=1
   listbranches=$listbranches"TRUE magentoerpconnect "
else
   listbranches=$listbranches"FALSE magentoerpconnect "
fi
else
   listbranches=$listbranches"FALSE magentoerpconnect "
fi

if [ -d /opt/report-openoffice ];
then
cd /opt/report-openoffice
sudo bzr missing > /tmp/check4newrevisions.txt
tail -1 /tmp/check4newrevisions.txt > /tmp/newrevisions.txt
NEWREVISIONS=`awk '/Branches are up to date/ {print $0}' /tmp/newrevisions.txt`
if [ -z "$NEWREVISIONS" ];
then
   newrevisionsfound=1
   listbranches=$listbranches"TRUE report-openoffice "
else
   listbranches=$listbranches"FALSE report-openoffice "
fi
else
   listbranches=$listbranches"FALSE report-openoffice "
fi

if [ -d /opt/openetl ];
then
cd /opt/openetl
sudo bzr missing > /tmp/check4newrevisions.txt
tail -1 /tmp/check4newrevisions.txt > /tmp/newrevisions.txt
NEWREVISIONS=`awk '/Branches are up to date/ {print $0}' /tmp/newrevisions.txt`
if [ -z "$NEWREVISIONS" ];
then
   newrevisionsfound=1
   listbranches=$listbranches"TRUE openetl "
else
   listbranches=$listbranches"FALSE openetl "
fi
else
   listbranches=$listbranches"FALSE openetl "
fi

eval $__newrevisionsfound="'$newrevisionsfound'"
eval $__listbranches="'$listbranches'"
}

function updatefunc()
{
# SUDO issue:
CHECKSUDOPASSWORD2=""
while [ -z $CHECKSUDOPASSWORD2 ]; do
zenity --entry --title="Superuser privileges" --text="Enter your user password (sudo):" --hide-text | sudo -S echo
if [ $? -ne 0 ]; 
then
    zenity --error --text="Sorry, bad password"
else
CHECKSUDOPASSWORD2="1"
fi
done

# When you use pipelines with built-in commands, the shell generally spawns a subshell to execute them.
# Unfortunately any change to a subshell variable is lost when you go back to the upper shell.
# Try this:
#     foo=0;
#     echo $foo;
#     { foo=1;echo $foo; } | cat;
#     echo $foo;
# Workaround: use i/o redirection like this (en lugar de "func | zenity --progress")
#    exec 3> >(zenity --progress --pulsate)
#    func >&3
#    exec 3>&-
# References: http://ubuntuforums.org/showthread.php?t=686757
# http://www.aero.jussieu.fr/services/INFO/documentation/mendel/HTML/io-redirection.html#FDREF
exec 3> >(if ! $(zenity --progress --title="OpenERP Updater" --text="Checking for new OpenERP revisions" --pulsate --auto-close); then  kill -9 $$;fi)
check4newrevisionsfunc NEWREVISIONSFOUND LISTBRANCHES >&3
exec 3>&-

if [ $NEWREVISIONSFOUND -eq 1 ]; 
then
zenity --info --text="New Revisions found. Press OK to continue"
else
zenity --question --text="Your OpenERP installation is already up to date. Press OK to exit or Cancel to reinstall OpenERP"
if [ $? -eq 0 ]; # 0 = ACCEPT
then
exit
else
zenity --info --text="OpenERP will be reinstalled. Press OK"
if [ -d /opt/extra-addons ]; 
then 
LISTBRANCHES="TRUE openerp-server TRUE openerp-client TRUE openerp-web TRUE Addons TRUE extra-addons"
else
LISTBRANCHES="TRUE openerp-server TRUE openerp-client TRUE openerp-web TRUE Addons FALSE extra-addons"
fi

if [ -d /opt/openerp-spain ]; 
then 
LISTBRANCHES="$LISTBRANCHES TRUE openerp-spain"
else
LISTBRANCHES="$LISTBRANCHES FALSE openerp-spain"
fi

if [ -d /opt/magentoerpconnect ]; 
then 
LISTBRANCHES="$LISTBRANCHES TRUE magentoerpconnect"
else
LISTBRANCHES="$LISTBRANCHES FALSE magentoerpconnect"
fi 
if [ -d /opt/report-openoffice ]; 
then 
LISTBRANCHES="$LISTBRANCHES TRUE report-openoffice"
else
LISTBRANCHES="$LISTBRANCHES FALSE report-openoffice"
fi 
if [ -d /opt/openetl ]; 
then 
LISTBRANCHES="$LISTBRANCHES TRUE openetl"
else
LISTBRANCHES="$LISTBRANCHES FALSE openetl"
fi 
fi
fi

BRANCHESTOREINSTALL=$(zenity  --list  --text "OpenERP Branches for updating and reinstalling" --width 300 --height=413 --checklist  --column "Pick" --column "Branch" $LISTBRANCHES --separator=" "); 
if [ $? -eq 1 ]
then
zenity --warning --text="Cancel button pressed. Script execution aborted"
exit 0
fi

NEWSERVERREVISIONS=`echo $BRANCHESTOREINSTALL | awk '/openerp-server/'`
if [ -n "$NEWSERVERREVISIONS" ];
then
   NEWSERVERREVISIONS=1
else
   NEWSERVERREVISIONS=0
fi

NEWCLIENTREVISIONS=`echo $BRANCHESTOREINSTALL | awk '/openerp-client/'`
if [ -n "$NEWCLIENTREVISIONS" ];
then
   NEWCLIENTREVISIONS=1
else
   NEWCLIENTREVISIONS=0
fi

NEWWEBREVISIONS=`echo $BRANCHESTOREINSTALL | awk '/openerp-web/'`
if [ -n "$NEWWEBREVISIONS" ];
then
   NEWWEBREVISIONS=1
else
   NEWWEBREVISIONS=0
fi

NEWADDONSREVISIONS=`echo $BRANCHESTOREINSTALL | awk '/Addons/'`
if [ -n "$NEWADDONSREVISIONS" ];
then
   NEWADDONSREVISIONS=1
else
   NEWADDONSREVISIONS=0
fi

NEWEXTRAADDONSREVISIONS=`echo $BRANCHESTOREINSTALL | awk '/extra-addons/'`
if [ -n "$NEWEXTRAADDONSREVISIONS" ];
then
   NEWEXTRAADDONSREVISIONS=1
else
   NEWEXTRAADDONSREVISIONS=0
fi

NEWOPENERPSPAINREVISIONS=`echo $BRANCHESTOREINSTALL | awk '/openerp-spain/'`
if [ -n "$NEWOPENERPSPAINREVISIONS" ];
then
   NEWOPENERPSPAINREVISIONS=1
else
   NEWOPENERPSPAINREVISIONS=0
fi

NEWMAGENTOCONNECTREVISIONS=`echo $BRANCHESTOREINSTALL | awk '/magentoerpconnect/'`
if [ -n "$NEWMAGENTOCONNECTREVISIONS" ];
then
   NEWMAGENTOCONNECTREVISIONS=1
else
   NEWMAGENTOCONNECTREVISIONS=0
fi

NEWREPORTOPENOFFICEREVISIONS=`echo $BRANCHESTOREINSTALL | awk '/report-openoffice/'`
if [ -n "$NEWREPORTOPENOFFICEREVISIONS" ];
then
   NEWREPORTOPENOFFICEREVISIONS=1
else
   NEWREPORTOPENOFFICEREVISIONS=0
fi

NEWOPENETLREVISIONS=`echo $BRANCHESTOREINSTALL | awk '/openetl/'`
if [ -n "$NEWOPENETLREVISIONS" ];
then
   NEWOPENETLREVISIONS=1
else
   NEWOPENETLREVISIONS=0
fi

# Inside parentheses, and therefore a subshell . . .
# http://tldp.org/LDP/abs/html/subshells.html
# Variable operations inside a subshell, even to a GLOBAL variable do not affect the value of the variable outside the subshell!
(
#########################################################################################################
# Stopping periodic command scheduler crond, i.e.:
# 	/etc/cron.daily/aptitude
#	/etc/cron.daily/apt  
#	/etc/apt/apt.conf.d/10periodic
echo "# DON'T PRESS ACCEPT/OK !!. Stopping periodic command scheduler crond";
sudo /etc/init.d/cron stop
#########################################################################################################
if [ "$UBUNTURELEASE" = "8.04" -a ! -e /etc/apt/sources.list.d/bzr2.list ]; then
# Checking if bzr 2.0+ is already set up:
showbzr2state=$(aptitude show bzr | grep -i Version)
BZR2INSTALL=$(echo $showbzr2state | awk '/ 2./')
if [ -z "$BZR2INSTALL" ];
then
# BZR 2.0+ INSTALLATION (ubuntu 8.04 provides bzr 1.6)
# We are going to upgrade the repositories format to the 2a version. This will hopefully reduce the size of the checkout, speed up some operations and make it possible to use stacked branches reliably.
# From now on, Bazaar 2.0+ will be required to contribute to OpenERP. 
# http://julienthewys.blogspot.com/2010/02/code-repository-upgrade.html
echo "# Installing bzr 2.0+ in APT sources list";
echo "Installing bzr 2.0+ in APT sources list" >> $MYDESKTOP/OpenERP-updates.txt;
cat > /tmp/bzr2.list <<"bzrEOF"
deb http://ppa.launchpad.net/bzr/ubuntu hardy main
deb-src http://ppa.launchpad.net/bzr/ubuntu hardy main
bzrEOF
sudo cp /tmp/bzr2.list /etc/apt/sources.list.d/
sudo chown root.root /etc/apt/sources.list.d/bzr2.list
sudo chmod 644 /etc/apt/sources.list.d/bzr2.list
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys D702BF6B8C6C1EFD
sudo aptitude clean
sudo aptitude -f update
sudo aptitude install -y bzr
fi
fi
################################################################################################################
if [ $NEWSERVERREVISIONS -eq 1 ];
then
echo "# Updating OpenERP Server with latest revisions from launchpad.net";
echo ">>>>> OpenERP Server: Updating latest revisions from launchpad.net <<<<<" | tee -a $MYDESKTOP/OpenERP-updates.txt;
cd /opt/openerp-server
sudo bzr pull --overwrite >>$MYDESKTOP/OpenERP-updates.txt 2>&1
sudo bzr update /opt/openerp-server >>$MYDESKTOP/OpenERP-updates.txt 2>&1
sudo -v
fi
if [ $NEWCLIENTREVISIONS -eq 1 ];
then
echo "# Updating OpenERP Client with latest revisions from launchpad.net";
echo ">>>>> OpenERP Client: Updating latest revisions from launchpad.net <<<<<" | tee -a $MYDESKTOP/OpenERP-updates.txt;
cd /opt/openerp-client
sudo bzr pull --overwrite >>$MYDESKTOP/OpenERP-updates.txt 2>&1
sudo bzr update /opt/openerp-client >>$MYDESKTOP/OpenERP-updates.txt 2>&1
sudo -v
fi
if [ $NEWWEBREVISIONS -eq 1 ];
then
echo "# Updating OpenERP Client Web with latest revisions from launchpad.net";
echo ">>>>> OpenERP Client Web: Updating latest revisions from launchpad.net <<<<<" | tee -a $MYDESKTOP/OpenERP-updates.txt;
cd /opt/openerp-web
sudo bzr pull --overwrite >>$MYDESKTOP/OpenERP-updates.txt 2>&1
sudo bzr update /opt/openerp-web >>$MYDESKTOP/OpenERP-updates.txt 2>&1
sudo -v
fi
if [ $NEWADDONSREVISIONS -eq 1 ];
then
echo "# Updating OpenERP Addons with latest revisions from launchpad.net";
echo ">>>>> OpenERP Addons: Updating latest revisions from launchpad.net <<<<<" | tee -a $MYDESKTOP/OpenERP-updates.txt;
cd /opt/addons
sudo bzr pull --overwrite >>$MYDESKTOP/OpenERP-updates.txt 2>&1
sudo bzr update /opt/addons >>$MYDESKTOP/OpenERP-updates.txt 2>&1
sudo -v
fi

if [ $NEWEXTRAADDONSREVISIONS -eq 1 ];
then
if [ -d /opt/extra-addons ]; 
then    
   echo "# Updating OpenERP Extra-Addons with latest revisions from launchpad.net";
   echo ">>>>> OpenERP Extra-Addons: Updating latest revisions from launchpad.net <<<<<" | tee -a $MYDESKTOP/OpenERP-updates.txt;
   cd /opt/extra-addons
   sudo bzr pull --overwrite >>$MYDESKTOP/OpenERP-updates.txt 2>&1
   sudo bzr update /opt/extra-addons >>$MYDESKTOP/OpenERP-updates.txt 2>&1
   # Following line fixes this bug: "Import module menu is missing" https://bugs.launchpad.net/openobject-server/+bug/506662?comments=all
   sudo sed -i "s/\(\"active\".*\)\(True,\)/\1False,/g" use_control/__terp__.py 
   sudo -v
else
   #zenity --info --text="extra-addons will be installed for first time"
   echo "# Downloading OpenERP Extra-Addons with latest revisions from launchpad.net";
   echo ">>>>> OpenERP Extra-Addons: Downloading latest revisions from launchpad.net <<<<<" | tee -a $MYDESKTOP/OpenERP-updates.txt;
   cd /opt
   sudo bzr branch lp:openobject-addons/extra-5.0 extra-addons >>$MYDESKTOP/OpenERP-updates.txt 2>&1
   sudo bzr update /opt/extra-addons >>$MYDESKTOP/OpenERP-updates.txt 2>&1
   # Following line fixes this bug: "Import module menu is missing" https://bugs.launchpad.net/openobject-server/+bug/506662?comments=all
   sudo sed -i "s/\(\"active\".*\)\(True,\)/\1False,/g" extra-addons/use_control/__terp__.py 
   sudo -v
fi
fi

##############################################################################################################################################
if [ $NEWOPENERPSPAINREVISIONS -eq 1 ];
then
if [ -d /opt/openerp-spain ];
then
   echo "# Actualizando OpenERP Spain con las últimas revisiones de launchpad.net";
   echo ">>>>> OpenERP Spain: Actualizando últimas revisiones de launchpad.net <<<<<" | tee -a $MYDESKTOP/OpenERP-updates.txt;
   cd /opt/openerp-spain
   sudo bzr pull --overwrite >>$MYDESKTOP/OpenERP-updates.txt 2>&1
   sudo bzr update /opt/openerp-spain >>$MYDESKTOP/OpenERP-updates.txt 2>&1
   sudo -v
elif [ ! -d /opt/extra-addons ];
then
   #zenity --info --text="openerp-spain y extra-addons van a ser instalados por primera vez" --width 300 --height=300
   echo "# Descargando OpenERP Extra-Addons con las últimas revisiones de launchpad.net";
   echo ">>>>> OpenERP Extra-Addons: Descargando últimas revisiones de launchpad.net <<<<<" | tee -a $MYDESKTOP/OpenERP-updates.txt;
   cd /opt
   sudo bzr branch lp:openobject-addons/extra-5.0 extra-addons >>$MYDESKTOP/OpenERP-updates.txt 2>&1
   sudo bzr update /opt/extra-addons >>$MYDESKTOP/OpenERP-updates.txt 2>&1
   # Following line fixes this bug: "Import module menu is missing" https://bugs.launchpad.net/openobject-server/+bug/506662?comments=all
   sudo sed -i "s/\(\"active\".*\)\(True,\)/\1False,/g" extra-addons/use_control/__terp__.py 

   echo "# Descargando OpenERP Spain con las últimas revisiones de launchpad.net";
   echo ">>>>> OpenERP Spain: Descargando últimas revisiones de launchpad.net <<<<<" | tee -a $MYDESKTOP/OpenERP-updates.txt;
   cd /opt
   sudo bzr branch lp:openerp-spain >>$MYDESKTOP/OpenERP-updates.txt 2>&1
   sudo bzr update /opt/openerp-spain >>$MYDESKTOP/OpenERP-updates.txt 2>&1
   sudo -v
   echo "# DON'T PRESS ACCEPT/OK !!. Instalando language-pack-es";
   sudo aptitude install -y language-pack-es language-support-es
else  
   #zenity --info --text="openerp-spain va a ser instalado por primera vez" --width 300 --height=300
   echo "# Descargando OpenERP Spain con las últimas revisiones de launchpad.net";
   echo ">>>>> OpenERP Spain: Descargando últimas revisiones de launchpad.net <<<<<" | tee -a $MYDESKTOP/OpenERP-updates.txt;
   cd /opt
   sudo bzr branch lp:openerp-spain openerp-spain >>$MYDESKTOP/OpenERP-updates.txt 2>&1
   sudo bzr update /opt/openerp-spain >>$MYDESKTOP/OpenERP-updates.txt 2>&1
   sudo -v
   echo "# DON'T PRESS ACCEPT/OK !!. Instalando language-pack-es";
   sudo aptitude install -y language-pack-es language-support-es
fi
fi
##############################################################################################################################################

if [ $NEWMAGENTOCONNECTREVISIONS -eq 1 ];
then
if [ -d /opt/magentoerpconnect ]; 
then    
   echo "# Updating Magento OpenERP Connector with latest revisions from launchpad.net";
   echo ">>>>> Magento OpenERP Connector: Updating latest revisions from launchpad.net <<<<<" | tee -a $MYDESKTOP/OpenERP-updates.txt;
   cd /opt/magentoerpconnect
   sudo bzr pull --overwrite >>$MYDESKTOP/OpenERP-updates.txt 2>&1
   sudo bzr update /opt/magentoerpconnect >>$MYDESKTOP/OpenERP-updates.txt 2>&1
   sudo -v
else
   #zenity --info --text="Magento OpenERP Connector will be installed for first time"
   echo "# Downloading Magento OpenERP Connector with latest revisions from launchpad.net";
   echo ">>>>> Magento OpenERP Connector: Downloading latest revisions from launchpad.net <<<<<" | tee -a $MYDESKTOP/OpenERP-updates.txt;
   cd /opt
   sudo bzr branch lp:magentoerpconnect >>$MYDESKTOP/OpenERP-updates.txt 2>&1
   sudo bzr update /opt/magentoerpconnect >>$MYDESKTOP/OpenERP-updates.txt 2>&1
   sudo -v
fi
fi

if [ $NEWREPORTOPENOFFICEREVISIONS -eq 1 ];
then
if [ -d /opt/report-openoffice ]; 
then    
   echo "# Updating report-openoffice with latest revisions from launchpad.net";
   echo ">>>>> report-openoffice: Updating latest revisions from launchpad.net <<<<<" | tee -a $MYDESKTOP/OpenERP-updates.txt;
   cd /opt/report-openoffice
   sudo bzr pull --overwrite >>$MYDESKTOP/OpenERP-updates.txt 2>&1
   sudo bzr update /opt/report-openoffice >>$MYDESKTOP/OpenERP-updates.txt 2>&1
   sudo -v
else
   #zenity --info --text="report-openoffice will be installed for first time"
   echo "# Downloading report-openoffice with latest revisions from launchpad.net";
   echo ">>>>> report-openoffice: Downloading latest revisions from launchpad.net <<<<<" | tee -a $MYDESKTOP/OpenERP-updates.txt;
   cd /opt
   sudo bzr branch lp:report-openoffice >>$MYDESKTOP/OpenERP-updates.txt 2>&1
   sudo bzr update /opt/report-openoffice >>$MYDESKTOP/OpenERP-updates.txt 2>&1
   sudo -v
   installopenoffice3withreportopenofficelibraries
   enablingopenofficeheadlessserver
fi
fi

if [ $NEWOPENETLREVISIONS -eq 1 ];
then
if [ -d /opt/openetl ]; 
then    
   echo "# Updating openetl with latest revisions from launchpad.net";
   echo ">>>>> openetl: Updating latest revisions from launchpad.net <<<<<" | tee -a $MYDESKTOP/OpenERP-updates.txt;
   cd /opt/openetl
   sudo bzr pull --overwrite >>$MYDESKTOP/OpenERP-updates.txt 2>&1
   sudo bzr update /opt/openetl >>$MYDESKTOP/OpenERP-updates.txt 2>&1
   sudo -v
else
   #zenity --info --text="openetl will be installed for first time"
   echo "# Downloading openetl with latest revisions from launchpad.net";
   echo ">>>>> openetl: Downloading latest revisions from launchpad.net <<<<<" | tee -a $MYDESKTOP/OpenERP-updates.txt;
   cd /opt
   sudo bzr branch lp:openetl >>$MYDESKTOP/OpenERP-updates.txt 2>&1
   sudo bzr update /opt/openetl >>$MYDESKTOP/OpenERP-updates.txt 2>&1
   sudo -v
fi
fi

echo "# Stopping OpenERP Server and OpenERP Web";
sudo /etc/init.d/openerp-server stop
sudo /etc/init.d/openerp-web stop

if [ -e /etc/init.d/openoffice ]; then
echo "# Stopping OpenOffice headless server";
sudo /etc/init.d/openoffice stop >/dev/null 2>&1
fi

if [ $NEWSERVERREVISIONS -eq 1 ];
then
echo "# Reinstalling OpenERP Server";
cd /opt/openerp-server
sudo python setup.py install
fi
if [ $NEWADDONSREVISIONS -eq 1 ];
then
echo "# Reinstalling OpenERP Addons";
if [ ! -d $ADDONSPATH ]; then
sudo mkdir -p $ADDONSPATH
fi
sudo cp -ru /opt/addons/* $ADDONSPATH
sudo chown -R openerp.root $ADDONSPATH
sudo chmod 755 $ADDONSPATH
fi
if [ $NEWEXTRAADDONSREVISIONS -eq 1 ];
then
echo "# Reinstalling OpenERP Extra-Addons";
sudo cp -ru /opt/extra-addons/* $ADDONSPATH
sudo chown -R openerp.root $ADDONSPATH
sudo chmod 755 $ADDONSPATH
fi
if [ "$UBUNTURELEASE" = "9.10" -a -d $OPENERPSERVERWRONGPATH/addons ]; then
# Adding workaround for bug in /opt/openerp-server/setup.py that puts import_xml.rng and base.sql into the wrong location
sudo cp -ru $OPENERPSERVERWRONGPATH/* $OPENERPSERVERPATH/
sudo chown -R openerp.root $ADDONSPATH
sudo chmod 755 $ADDONSPATH
fi
if [ $NEWOPENERPSPAINREVISIONS -eq 1 ];
then
echo "# Reinstalando openerp-spain";
sudo cp -ru /opt/openerp-spain/l10n_es/* $ADDONSPATH
sudo cp -ru /opt/openerp-spain/l10n_es_extras/* $ADDONSPATH
sudo cp -ru /opt/openerp-spain/extra_addons/* $ADDONSPATH
sudo cp -ru /opt/openerp-spain/l10n_ca_ES/* $ADDONSPATH
[ "$(ls -A /opt/openerp-spain/l10n_es_ES/)" ] && sudo cp -ru /opt/openerp-spain/l10n_es_ES/* $ADDONSPATH # "Not Empty" 
[ "$(ls -A /opt/openerp-spain/l10n_gl_ES/)" ] && sudo cp -ru /opt/openerp-spain/l10n_gl_ES/* $ADDONSPATH # "Not Empty"
[ "$(ls -A /opt/openerp-spain/l10n_gl_ES/)" ] && sudo cp -ru /opt/openerp-spain/l10n_eu_ES/* $ADDONSPATH # "Not Empty"
sudo chown -R openerp.root $ADDONSPATH
sudo chmod 755 $ADDONSPATH
fi
if [ $NEWMAGENTOCONNECTREVISIONS -eq 1 ];
then
echo "# Reinstalling Magento OpenERP Connector";
sudo cp -ru /opt/magentoerpconnect $ADDONSPATH
sudo chown -R openerp.root $ADDONSPATH
sudo chmod 755 $ADDONSPATH
fi
if [ $NEWREPORTOPENOFFICEREVISIONS -eq 1 ]; 
then 
sudo cp -ru /opt/report-openoffice/* $ADDONSPATH
sudo chown -R openerp.root $ADDONSPATH
sudo chmod 755 $ADDONSPATH
fi
if [ $NEWOPENETLREVISIONS -eq 1 ];
then
sudo cp -ru $ADDONSPATH/etl/lib/etl/ $SITEPACKAGESPATH/
sudo cp -ru /opt/openetl/lib/openetl/ $SITEPACKAGESPATH/
sudo cp -ru /opt/openetl/lib/etl_test/ $SITEPACKAGESPATH/
sudo chown -R root.root $SITEPACKAGESPATH/etl/
sudo chown -R root.root $SITEPACKAGESPATH/etl_test/
sudo chown -R root.root $SITEPACKAGESPATH/openetl/
fi

# UPDATES AND UPGRADES:
# http://doc.openerp.com/book/8/8_21_Implem/8_21_Implem_support.html
# http://doc.openerp.com/install/windows/server/index.html
# First time run with an upgraded version of Open ERP Server
# Execute the command with an option that updates the data structures:
# --update=all
# sudo /etc/init.d/openerp-server stop

# sudo /usr/bin/openerp-server --stop-after-init --update=all --logfile=/var/log/openerp/openerp.log --db_host=localhost --db_port=5432 -d mydb -r openerp -w openerp
# sudo /usr/bin/openerp-server --stop-after-init --update=all --logfile=/var/log/openerp/openerp.log --db_host=localhost --db_port=5432 -r openerp -w openerp
# --update=mymodule --stop-after-init --log-level=debug
echo "# Updating OpenERP Modules";
sudo $INSTALLPATH/bin/openerp-server --stop-after-init --update=all --logfile=/var/log/openerp/openerp.log 
sudo -v
# UPDATE:
# - downloaded the openerp-server file and extracted it 
# - python setup.py install 
# - I stopped all the services and ran openerp-server --update=all 
# - I updated the web client with easy_install -U openerp-web 
# - Restarted all the services 

# UPGRADE:
# Make a backup of the database from the old version of Open ERP
# Stop the server running the old version
# Start the script called pre.py for the versions you’re moving between.
# Start the new version of the server using the option –update=all
# Stop the server running the new version.
# Start the script called post.py for the versions you’re moving between.
# Start the new version of the server and test it.
if [ $NEWCLIENTREVISIONS -eq 1 ];
then
echo "# Reinstalling OpenERP Client";
cd /opt/openerp-client
sudo python setup.py install
sudo -v
fi
if [ $NEWWEBREVISIONS -eq 1 ];
then
echo "# Reinstalling OpenERP Web";
cd /opt/openerp-web
sudo python setup.py install
#sudo easy_install -U openerp-web
sudo -v
fi
echo "# Starting OpenERP Server and OpenERP Web";
sudo /etc/init.d/openerp-server start
sudo /etc/init.d/openerp-web start

if [ -e /etc/init.d/openoffice ]; then
echo "# Starting OpenOffice headless server";
sudo /etc/init.d/openoffice start >/dev/null 2>&1
fi

###################################################################################################
# Workaround for this error 'No handlers could be found for logger “bzr”' when user runs bzr after this script is executed
# This usually just means you don’t have permission to write to the log. Sometimes it ends up belonging to root (because of sudo bzr)
sudo chown $USER ~/.bzr.log
chmod 644 ~/.bzr.log
###################################################################################################

#########################################################################################################
# Starting periodic command scheduler crond, i.e.:
# 	/etc/cron.daily/aptitude
#	/etc/cron.daily/apt  
#	/etc/apt/apt.conf.d/10periodic
echo "# DON'T PRESS ACCEPT/OK !!. Starting periodic command scheduler crond";
sudo /etc/init.d/cron start
#########################################################################################################

echo "# OpenERP has been updated. Press OK to exit";
) |  (if $(zenity --progress \
  --title="updating OpenERP on Ubuntu" \
  --text="Downloading OpenERP Software from launchpad.net" \
  --pulsate);
then
  echo "update of OpenERP Completed.";
else
  # zenity's "--auto-kill" opcion does not work due to a bug. This is a workaround
  kill -9 $$
fi)
}
########################################################################################################################
# END OF FUNCTIONS
########################################################################################################################
if [ -x /etc/init.d/openerp-web ] ; then    
	zenity --question --text="OpenERP already installed. Would you like to update it?"
	if [ $? -eq 0 ]; # 0 = ACCEPT
	then
	#zenity --info --text="OpenERP will be updated"  
        echo "############################################################################" >>$MYDESKTOP/OpenERP-updates.txt
        echo "DATE:"`date` >>$MYDESKTOP/OpenERP-updates.txt 2>&1
	updatefunc
	else
	zenity --info --text="OpenERP will NOT be updated. Press OK to exit"
	fi
else
zenity --info --text="OpenERP will be installed for first time"
echo "############################################################################" >>$MYDESKTOP/OpenERP-updates.txt
echo "DATE:"`date` >>$MYDESKTOP/OpenERP-updates.txt 2>&1
installfunc
fi

