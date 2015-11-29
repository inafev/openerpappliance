#!/bin/bash
PSQLRELEASE=8.3
PYTHONRELEASE=python2.5
UBUNTURELEASE=8.04
INSTALLPATH=/usr
SITEPACKAGESPATH=$INSTALLPATH/lib/$PYTHONRELEASE/site-packages
OPENERPSERVERPATH=$SITEPACKAGESPATH/openerp-server
ADDONSPATH=$OPENERPSERVERPATH/addons/
OPENERPSERVERWRONGPATH=/nobugnoworkaround
MYDESKTOP=/home/openerp
USER=openerp

function check4newrevisionsfunc()
{
local  __newrevisionsfound=$1
local  newrevisionsfound=0

local  __listbranches=$2
local  listbranches=""

cd /home/openerp/openerp-server
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
cd /home/openerp/openerp-client
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
cd /home/openerp/openerp-web
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
cd /home/openerp/addons
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

cd /home/openerp/extra-addons
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
LISTBRANCHES="TRUE openerp-server TRUE openerp-client TRUE openerp-web TRUE Addons TRUE extra-addons"
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

(

if [ $NEWSERVERREVISIONS -eq 1 ];
then
echo "# Updating OpenERP Server with latest revisions from launchpad.net";
echo ">>>>> OpenERP Server: Updating latest revisions from launchpad.net <<<<<" | tee -a $MYDESKTOP/OpenERP-updates.txt;
cd /home/openerp/openerp-server
sudo bzr pull --overwrite >>$MYDESKTOP/OpenERP-updates.txt 2>&1
sudo bzr update /home/openerp/openerp-server >>$MYDESKTOP/OpenERP-updates.txt 2>&1
sudo -v
fi
if [ $NEWCLIENTREVISIONS -eq 1 ];
then
echo "# Updating OpenERP Client with latest revisions from launchpad.net";
echo ">>>>> OpenERP Client: Updating latest revisions from launchpad.net <<<<<" | tee -a $MYDESKTOP/OpenERP-updates.txt;
cd /home/openerp/openerp-client
sudo bzr pull --overwrite >>$MYDESKTOP/OpenERP-updates.txt 2>&1
sudo bzr update /home/openerp/openerp-client >>$MYDESKTOP/OpenERP-updates.txt 2>&1
sudo -v
fi
if [ $NEWWEBREVISIONS -eq 1 ];
then
echo "# Updating OpenERP Client Web with latest revisions from launchpad.net";
echo ">>>>> OpenERP Client Web: Updating latest revisions from launchpad.net <<<<<" | tee -a $MYDESKTOP/OpenERP-updates.txt;
cd /home/openerp/openerp-web
sudo bzr pull --overwrite >>$MYDESKTOP/OpenERP-updates.txt 2>&1
sudo bzr update /home/openerp/openerp-web >>$MYDESKTOP/OpenERP-updates.txt 2>&1
sudo -v
fi
if [ $NEWADDONSREVISIONS -eq 1 ];
then
echo "# Updating OpenERP Addons with latest revisions from launchpad.net";
echo ">>>>> OpenERP Addons: Updating latest revisions from launchpad.net <<<<<" | tee -a $MYDESKTOP/OpenERP-updates.txt;
cd /home/openerp/addons
sudo bzr pull --overwrite >>$MYDESKTOP/OpenERP-updates.txt 2>&1
sudo bzr update /home/openerp/addons >>$MYDESKTOP/OpenERP-updates.txt 2>&1
sudo -v
fi
if [ $NEWEXTRAADDONSREVISIONS -eq 1 ];
then
   echo "# Updating OpenERP Extra-Addons with latest revisions from launchpad.net";
   echo ">>>>> OpenERP Extra-Addons: Updating latest revisions from launchpad.net <<<<<" | tee -a $MYDESKTOP/OpenERP-updates.txt;
   cd /home/openerp/extra-addons
   sudo bzr pull --overwrite >>$MYDESKTOP/OpenERP-updates.txt 2>&1
   sudo bzr update /home/openerp/extra-addons >>$MYDESKTOP/OpenERP-updates.txt 2>&1
   # Following line fixes this bug: "Import module menu is missing" https://bugs.launchpad.net/openobject-server/+bug/506662?comments=all
   sudo sed -i "s/\(\"active\".*\)\(True,\)/\1False,/g" use_control/__terp__.py 
   sudo -v
fi

echo "# Stopping OpenERP Server and OpenERP Web";
sudo /etc/init.d/openerp-server stop
sudo /etc/init.d/openerp-web stop

if [ $NEWSERVERREVISIONS -eq 1 ];
then
echo "# Reinstalling OpenERP Server";
cd /home/openerp/openerp-server
sudo python setup.py install
fi
if [ $NEWADDONSREVISIONS -eq 1 ];
then
echo "# Reinstalling OpenERP Addons";
if [ ! -d $ADDONSPATH ]; then
sudo mkdir -p $ADDONSPATH
fi
sudo cp -ru /home/openerp/addons/* $ADDONSPATH
sudo chown -R openerp.root $ADDONSPATH
sudo chmod 755 $ADDONSPATH
fi
if [ $NEWEXTRAADDONSREVISIONS -eq 1 ];
then
echo "# Reinstalling OpenERP Extra-Addons";
sudo cp -ru /home/openerp/extra-addons/* $ADDONSPATH
sudo chown -R openerp.root $ADDONSPATH
sudo chmod 755 $ADDONSPATH
fi

echo "# Updating OpenERP Modules";
sudo $INSTALLPATH/bin/openerp-server --stop-after-init --update=all --logfile=/var/log/openerp/openerp.log 
sudo -v

if [ $NEWCLIENTREVISIONS -eq 1 ];
then
echo "# Reinstalling OpenERP Client";
cd /home/openerp/openerp-client
sudo python setup.py install
sudo -v
fi
if [ $NEWWEBREVISIONS -eq 1 ];
then
echo "# Reinstalling OpenERP Web";
cd /home/openerp/openerp-web
#sudo python setup.py install
sudo easy_install -U openerp-web
sudo -v
fi
echo "# Starting OpenERP Server and OpenERP Web";
sudo /etc/init.d/openerp-server start
sudo /etc/init.d/openerp-web start

sudo chown $USER ~/.bzr.log
chmod 644 ~/.bzr.log

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

WHOAMI=$(whoami)
if [ "$WHOAMI" = "openerp" ];
then
echo "############################################################################" >>$MYDESKTOP/OpenERP-updates.txt
echo "DATE:"`date` >>$MYDESKTOP/OpenERP-updates.txt 2>&1
updatefunc
else
echo "This script must be run as openerp user. Script execution aborted"
fi