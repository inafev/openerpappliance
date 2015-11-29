#!/bin/bash 
######################################################################################################################################################################
######################################################################################################################################################################
# File: openerp-updater.sh
# This script eases the update of openerp v5 on OpenERP turnkeylinux based virtual appliance (http://www.turnkeylinux.org/)
# Script based on http://opensourceconsulting.wordpress.com/2009/09/15/openerp-all-in-one-installer-update-for-dummies/
# Date: April 18th 2010
# Version: 1.0
# License: This script is released into GPLv3 (GNU GENERAL PUBLIC LICENSE Version 3)
######################################################################################################################################################################
######################################################################################################################################################################
# Author: Inaki Fernandez
# Senior IT Systems Engineer
# Madrid, Spain
# Skype: linuxunixmadrid
# MSN Messenger: linuxunixmadrid_at_hotmail_dot_com
# E-mail & Google Talk: linuxunixmadrid_at_gmail_dot_com
# Twitter: twitter.com/linuxunixmadrid
# Blog: http://opensourceconsulting.wordpress.com/
######################################################################################################################################################################
######################################################################################################################################################################

PSQLRELEASE=8.3
PYTHONRELEASE=python2.5
UBUNTURELEASE=8.04
INSTALLPATH=/usr
#SITEPACKAGESPATH=$INSTALLPATH/lib/$PYTHONRELEASE/site-packages
#OPENERPSERVERPATH=$SITEPACKAGESPATH/openerp-server
#ADDONSPATH=$OPENERPSERVERPATH/addons/
SITEPACKAGESPATH=/home/openerp/production/site-packages/
OPENERPSERVERPATH=/home/openerp/production/openerp-server
ADDONSPATH=$OPENERPSERVERPATH/bin/addons/
OPENERPSERVERWRONGPATH=/nobugnoworkaround
MYDESKTOP=/home/openerp
USER=openerp
DIALOG=dialog
background="OpenERP updater"
SERVERNOPROMPTFORCE=off
CLIENTNOPROMPTFORCE=off
ADDONSNOPROMPTFORCE=off
EXTRAADDONSNOPROMPTFORCE=off
WEBCLIENTNOPROMPTFORCE=off
FORCEUPDATE=0

function check4newrevisionsfunc()
{
local  __newrevisionsfound=$1
local  newrevisionsfound=0

local  __listbranches=$2
local  listbranches=""

SERVERSTATUS=7
CLIENTSTATUS=7
WEBSTATUS=7
ADDONSSTATUS=7
EXTRAADDONSSTATUS=7

for i in 5 10 20 30 40 50 60 70 80 90 100
do
$DIALOG --backtitle "$background" \
        --title "Checking for new OpenERP revisions" \
        --mixedgauge "OpenERP-updates.txt file is created with records of installed or updated OpenERP revisions.This is useful for controlling your updates.\n\nCommand-line options: openerp-updater.sh --help" \
                0 0 $i \
                "OpenERP Server"        "$SERVERSTATUS" \
                "OpenERP Client"        "$CLIENTSTATUS" \
                "OpenERP Web"   	"$WEBSTATUS" \
                "OpenERP addons"        "$ADDONSSTATUS" \
                "OpenERP extra-addons"  "$EXTRAADDONSSTATUS" \
                #"Process nine" "-$i"
# break
sleep 1 
case $i in
  5)
  cd /home/openerp/production/openerp-server
  bzr missing > /tmp/check4newrevisions.txt 2>&1
  tail -1 /tmp/check4newrevisions.txt > /tmp/newrevisions.txt
  NEWREVISIONS=`awk '/Branches are up to date/ {print $0}' /tmp/newrevisions.txt`
  if [ -z "$NEWREVISIONS" ];
  then
    newrevisionsfound=1
    listbranches=$listbranches'openerp-server branch on '
  else
    listbranches=$listbranches'openerp-server branch off '
  fi
  SERVERSTATUS=3;
  ;;
  20)
  cd /home/openerp/production/openerp-client
  bzr missing > /tmp/check4newrevisions.txt 2>&1
  tail -1 /tmp/check4newrevisions.txt > /tmp/newrevisions.txt
  NEWREVISIONS=`awk '/Branches are up to date/ {print $0}' /tmp/newrevisions.txt`
  if [ -z "$NEWREVISIONS" ];
  then
    newrevisionsfound=1
    listbranches=$listbranches'openerp-client branch on '
  else
    listbranches=$listbranches'openerp-client branch off '
  fi
  CLIENTSTATUS=3;
  ;;
  40)
  cd /home/openerp/production/openerp-web
  bzr missing > /tmp/check4newrevisions.txt 2>&1
  tail -1 /tmp/check4newrevisions.txt > /tmp/newrevisions.txt
  NEWREVISIONS=`awk '/Branches are up to date/ {print $0}' /tmp/newrevisions.txt`
  if [ -z "$NEWREVISIONS" ];
  then
    newrevisionsfound=1
    listbranches=$listbranches'openerp-web branch on '
  else
    listbranches=$listbranches'openerp-web branch off '
  fi
  WEBSTATUS=3;
  ;;
  60)
  cd /home/openerp/production/addons
  bzr missing > /tmp/check4newrevisions.txt 2>&1
  tail -1 /tmp/check4newrevisions.txt > /tmp/newrevisions.txt
  NEWREVISIONS=`awk '/Branches are up to date/ {print $0}' /tmp/newrevisions.txt`
  if [ -z "$NEWREVISIONS" ];
  then
    newrevisionsfound=1
    listbranches=$listbranches'Addons branch on '
  else
    listbranches=$listbranches'Addons branch off '
  fi
  ADDONSSTATUS=3;
  ;;
  80)
  cd /home/openerp/production/extra-addons
  bzr missing > /tmp/check4newrevisions.txt 2>&1
  tail -1 /tmp/check4newrevisions.txt > /tmp/newrevisions.txt
  NEWREVISIONS=`awk '/Branches are up to date/ {print $0}' /tmp/newrevisions.txt`
  if [ -z "$NEWREVISIONS" ];
  then
    newrevisionsfound=1
    listbranches=$listbranches'extra-addons branch on '
  else
    listbranches=$listbranches'extra-addons branch off '
  fi
  EXTRAADDONSSTATUS=3;
  ;;
esac
done 

eval $__newrevisionsfound="'$newrevisionsfound'"
eval $__listbranches="'$listbranches'"
}


function updatefunc()
{
CHECKSUDOPASSWORD2=""
while [ -z $CHECKSUDOPASSWORD2 ]; do
tempfile=/tmp/test$$
$DIALOG --title "Superuser privileges" --clear \
        --insecure \
        --passwordbox "Enter your user password (sudo)" 16 51 2> $tempfile
retval=$?
case $retval in
  0)
    #echo "Input string is `cat $tempfile`"
    sudopasswd=$(cat $tempfile)
    (echo "$sudopasswd" | sudo -S echo 2> /dev/null) 
    if [ "$?" -eq "1" ];
    then
      CHECKSUDOPASSWORD2=""
    else
      CHECKSUDOPASSWORD2="1"
    fi
    ;;
  1)
    echo "Cancel pressed."
    exit 0;;
  255)
    echo "ESC pressed."
    exit 0
    ;;
esac
rm -f /tmp/test$$
done


if [ "$SERVERNOPROMPTFORCE" = "on" -o "$CLIENTNOPROMPTFORCE" = "on" -o "$ADDONSNOPROMPTFORCE" = "on" -o "$EXTRAADDONSNOPROMPTFORCE" = "on" -o "$WEBCLIENTNOPROMPTFORCE" = "on" ];
then
NEWREVISIONSFOUND=1
#FORCEUPDATE=1
LISTBRANCHES="openerp-server branch $SERVERNOPROMPTFORCE openerp-client branch $CLIENTNOPROMPTFORCE openerp-web branch $WEBCLIENTNOPROMPTFORCE Addons branch $ADDONSNOPROMPTFORCE extra-addons branch $EXTRAADDONSNOPROMPTFORCE"
else
check4newrevisionsfunc NEWREVISIONSFOUND LISTBRANCHES
fi

if [ $NEWREVISIONSFOUND -eq 1 -a $FORCEUPDATE -eq 0 ]; 
then
$DIALOG --title "New Revisions found" --clear \
        --msgbox "Press OK to continue or ESC to exit" 10 41
case $? in
  0)
    #echo "OK"
    ;;
  255)
    echo "ESC pressed."
    exit 0;;
  *)
    echo "Unexpected code $?"
    exit 0
    ;;
esac
else if [ $NEWREVISIONSFOUND -eq 0 ];
then
$DIALOG --title "Your OpenERP installation is already up to date" --clear \
        --yesno "Press YES to exit or NO to reinstall OpenERP " 7 55
case $? in
  0)
    echo "Yes chosen."
    exit 0;;
  1)
    echo "No chosen."
    dialog --title "OpenERP update" --msgbox "OpenERP will be reinstalled" 7 55
    LISTBRANCHES='openerp-server branch on openerp-client branch on openerp-web branch on Addons branch on extra-addons branch on'
    #Dialog "" on Readline "" off Gnome "" off Kde "" off Editor "" off Noninteractive "" on 
    ;;
  255)
    echo "ESC pressed."
    exit 0;;
  *)
    echo "Unexpected code $?"
    exit 0
    ;;
esac
fi
fi

if [ $FORCEUPDATE -eq 0 ]; 
then
tempfile=`tempfile 2>/dev/null` || tempfile=/tmp/test$$
trap "rm -f $tempfile" 0 1 2 5 15
$DIALOG \
        --backtitle "$background" \
        --title "OpenERP Branches for updating and reinstalling" \
        --checklist "Which of the following OpenERP branches would you like to update and reinstall? \n\n\
Hi, this is a checklist box. You can use the \n\
UP/DOWN arrow keys, the first letter of the choice as a \n\
hot key, or the number keys 1-9 to choose an option. \n\
Press SPACE to toggle an option on/off. \n\n\
Which of the following OpenERP branches would you like to update and reinstall?" 30 61 5 \
	$LISTBRANCHES 2> $tempfile
retval=$?
choice=`cat $tempfile`
case $retval in
  0)
    #echo "'$choice' chosen."
    ;;
  1)
    echo "Cancel pressed."
    exit 0
    ;;
  255)
    echo "ESC pressed."
    exit 0
    ;;
  *)
    echo "Unexpected code $retval"
    exit 0
    ;;
esac
BRANCHESTOREINSTALL=$choice
else
if [ "$SERVERNOPROMPTFORCE" = "on" ];
then
BRANCHESTOREINSTALL="openerp-server "
fi
if [ "$CLIENTNOPROMPTFORCE" = "on" ];
then
BRANCHESTOREINSTALL="$BRANCHESTOREINSTALL openerp-client "
fi
if [ "$ADDONSNOPROMPTFORCE" = "on" ];
then
BRANCHESTOREINSTALL="$BRANCHESTOREINSTALL Addons "
fi
if [ "$EXTRAADDONSNOPROMPTFORCE" = "on" ];
then  
BRANCHESTOREINSTALL="$BRANCHESTOREINSTALL extra-addons "
fi
if [ "$WEBCLIENTNOPROMPTFORCE" = "on" ];
then
BRANCHESTOREINSTALL="$BRANCHESTOREINSTALL openerp-web "
fi
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

SERVERSTATUS=7
CLIENTSTATUS=7
WEBSTATUS=7
ADDONSSTATUS=7
EXTRAADDONSSTATUS=7

for i in 5 10 20 30 40 50 60 70 80 90 100
do
$DIALOG --backtitle "$background" \
        --title "Updating OpenERP with latest revisions from launchpad.net" \
        --mixedgauge "OpenERP-updates.txt file is created with records of installed or updated OpenERP revisions.This is useful for controlling your updates.\n\nCommand-line options: openerp-updater.sh --help" \
                0 0 $i \
                "OpenERP Server"        "$SERVERSTATUS" \
                "OpenERP Client"        "$CLIENTSTATUS" \
                "OpenERP Web"   	"$WEBSTATUS" \
                "OpenERP addons"        "$ADDONSSTATUS" \
                "OpenERP extra-addons"  "$EXTRAADDONSSTATUS" \
                #"Process nine" "-$i"
sleep 1 
case $i in
  5)
  if [ $NEWSERVERREVISIONS -eq 1 ];
  then
  cd /home/openerp/production/openerp-server
  bzr pull --overwrite >>$MYDESKTOP/OpenERP-updates.txt 2>&1
  bzr update /home/openerp/production/openerp-server >>$MYDESKTOP/OpenERP-updates.txt 2>&1
  fi
  SERVERSTATUS=3;
  ;;
  20)
  if [ $NEWCLIENTREVISIONS -eq 1 ];
  then
  cd /home/openerp/production/openerp-client
  bzr pull --overwrite >>$MYDESKTOP/OpenERP-updates.txt 2>&1
  bzr update /home/openerp/production/openerp-client >>$MYDESKTOP/OpenERP-updates.txt 2>&1
  fi
  CLIENTSTATUS=3;
  ;;
  40)
  if [ $NEWWEBREVISIONS -eq 1 ];
  then
  cd /home/openerp/production/openerp-web
  bzr pull --overwrite >>$MYDESKTOP/OpenERP-updates.txt 2>&1
  bzr update /home/openerp/production/openerp-web >>$MYDESKTOP/OpenERP-updates.txt 2>&1
  fi
  WEBSTATUS=3;
  ;;
  60)
  if [ $NEWADDONSREVISIONS -eq 1 ];
  then
  cd /home/openerp/production/addons
  bzr pull --overwrite >>$MYDESKTOP/OpenERP-updates.txt 2>&1
  bzr update /home/openerp/production/addons >>$MYDESKTOP/OpenERP-updates.txt 2>&1
  fi
  ADDONSSTATUS=3;
  ;;
  80)
  if [ $NEWEXTRAADDONSREVISIONS -eq 1 ];
  then
  cd /home/openerp/production/extra-addons
  bzr pull --overwrite >>$MYDESKTOP/OpenERP-updates.txt 2>&1
  bzr update /home/openerp/production/extra-addons >>$MYDESKTOP/OpenERP-updates.txt 2>&1
  # Following line fixes this bug: "Import module menu is missing" https://bugs.launchpad.net/openobject-server/+bug/506662?comments=all
  sed -i "s/\(\"active\".*\)\(True,\)/\1False,/g" use_control/__terp__.py 
  fi
  EXTRAADDONSSTATUS=3;
  ;;
esac
done 

STOPSTATUS=7
SERVERREINSTALLSTATUS=7
ADDONSINSTALLSTATUS=7
EXTRAADDONSINSTALLSTATUS=7
MODULESUPDATESTATUS=7
CLIENTINSTALLSTATUS=7
WEBINSTALLSTATUS=7
STARTSTATUS=7

for i in 5 15 30 45 60 75 90 99 100
do
$DIALOG --backtitle "$background" \
        --title "Reinstalling OpenERP" \
        --mixedgauge "OpenERP-updates.txt file is created with records of installed or updated OpenERP revisions.This is useful for controlling your updates.\n\nCommand-line options: openerp-updater.sh --help" \
                0 0 $i \
                "Stopping OpenERP Server and OpenERP Web"       "$STOPSTATUS" \
                "Reinstalling OpenERP Server"        		"$SERVERREINSTALLSTATUS" \
                "Reinstalling OpenERP Addons"		   	"$ADDONSINSTALLSTATUS" \
                "Reinstalling OpenERP Extra-Addons"             "$EXTRAADDONSINSTALLSTATUS" \
                "Updating OpenERP Modules"  			"$MODULESUPDATESTATUS" \
		"Reinstalling OpenERP Client"   		"$CLIENTINSTALLSTATUS" \
		"Reinstalling OpenERP Web"   			"$WEBINSTALLSTATUS" \
		"Starting OpenERP Server and OpenERP Web"   	"$STARTSTATUS" \
                #"Process nine" "-$i"
# break
sleep 1 
case $i in
  5)
  sudo /etc/init.d/openerp-server stop > /dev/null 2>&1
  sudo /etc/init.d/openerp-web stop > /dev/null 2>&1
  STOPSTATUS=3;
  ;;
  15)
  if [ $NEWSERVERREVISIONS -eq 1 ];
  then
  cd /home/openerp/production/openerp-server
  #sudo python setup.py install > /dev/null 2>&1
  fi
  SERVERREINSTALLSTATUS=3;
  ;;
  30)
  if [ $NEWADDONSREVISIONS -eq 1 ];
  then
  if [ ! -d $ADDONSPATH ]; then
  sudo mkdir -p $ADDONSPATH
  fi
  sudo ln -sf /home/openerp/production/addons/* $ADDONSPATH > /dev/null 2>&1
  sudo chown -R openerp.root $ADDONSPATH > /dev/null 2>&1
  sudo chmod 755 $ADDONSPATH > /dev/null 2>&1
  fi
  ADDONSINSTALLSTATUS=3;
  ;;
  45)
  if [ $NEWEXTRAADDONSREVISIONS -eq 1 ];
  then
  sudo ln -sf /home/openerp/production/extra-addons/* $ADDONSPATH > /dev/null 2>&1
  sudo chown -R openerp.root $ADDONSPATH > /dev/null 2>&1
  sudo chmod 755 $ADDONSPATH > /dev/null 2>&1
  fi
  EXTRAADDONSINSTALLSTATUS=3;
  ;;
  60)
  sudo $INSTALLPATH/bin/openerp-server --stop-after-init --update=all --logfile=/var/log/openerp/openerp.log > /dev/null 2>&1
  MODULESUPDATESTATUS=3;
  ;;
  75)
  if [ $NEWCLIENTREVISIONS -eq 1 ];
  then
  cd /home/openerp/production/openerp-client
  #sudo python setup.py install > /dev/null 2>&1
  fi
  CLIENTINSTALLSTATUS=3;
  ;;
  90)
  if [ $NEWWEBREVISIONS -eq 1 ];
  then
  cd /home/openerp/production/openerp-web
  sudo python setup.py install > /dev/null 2>&1
  #sudo easy_install -U openerp-web > /dev/null 2>&1
  #export PYTHONPATH=$SITEPACKAGESPATH         
  #easy_install --install-dir $SITEPACKAGESPATH -U openobject-web > /dev/null 2>&1
  fi
  WEBINSTALLSTATUS=3;
  ;;
  99)
  STARTSTATUS=3;
  sudo /etc/init.d/openerp-server start > /dev/null 2>&1
  sudo /etc/init.d/openerp-web start > /dev/null 2>&1
  sudo chown $USER ~/.bzr.log  > /dev/null 2>&1
  sudo chmod 644 ~/.bzr.log > /dev/null 2>&1
  ;;
esac
done 

if [ $FORCEUPDATE -eq 0 ]; 
then
$DIALOG --title "OpenERP updater" --clear \
        --msgbox "OpenERP has been updated and restarted\n\nOpenERP-updates.txt file is created with records of installed or updated OpenERP revisions.This is useful for controlling your updates.\n\nCommand-line options: openerp-updater.sh --help
\n\nPress OK to exit" 15 60
case $? in
  0)
    #echo "OK"
    ;;
  255)
    echo "ESC pressed."
    exit 0;;
esac
fi
}



function mainexec()
{
    WHOAMI=$(whoami)
    if [ "$WHOAMI" = "openerp" ];
    then
    echo "############################################################################" >>$MYDESKTOP/OpenERP-updates.txt
    echo "DATE:"`date` >>$MYDESKTOP/OpenERP-updates.txt 2>&1
    updatefunc
    else
    echo "This script must be run as openerp user. Script execution aborted"
    fi
}


########################################################################################################################
# END OF FUNCTIONS
########################################################################################################################

# Am I root or not?
#ROOT_UID=0   # Root has $UID 0.
#if [ "$UID" -eq "$ROOT_UID" ];  # Will the real "root" please stand up?
#then
#  echo "You are root."
#else
#  echo "You are just an ordinary user (but mom loves you just the same)."
#  exit 0
#fi

if [ "$1" = "-h" -o "$1" = "--help" -o "$1" = "-help" -o "$1" = "--h" ];
then
        echo $"Interactive usage: $0 "
        echo $"Usage without prompting: $0 {server|client|addons|extra-addons|extra|web-client|web|all}"
	echo $"Example: ./openerp-updater.sh server client -> will force an update of the server and client without prompting"
        exit 2
fi

params=$#              # Number of command-line parameters.
param=1                # Start at first command-line param.

if [ $params -eq 0 ];
then
     mainexec
else
while [ "$param" -le "$params" ]
do
  eval arg=\$$param
#  Gives the *value* of variable.
#  The "eval" forces the *evaluation* of \$$
#  as an indirect variable reference.

case "$arg" in
  server)
	SERVERNOPROMPTFORCE=on
        ;;
  client)
	CLIENTNOPROMPTFORCE=on
        ;;
  addons)
	ADDONSNOPROMPTFORCE=on
        ;;
  extra-addons|extra)
	EXTRAADDONSNOPROMPTFORCE=on
        ;;
  web-client|web)
	WEBCLIENTNOPROMPTFORCE=on
        ;;
  all|All)
        SERVERNOPROMPTFORCE=on
	CLIENTNOPROMPTFORCE=on
	ADDONSNOPROMPTFORCE=on
	EXTRAADDONSNOPROMPTFORCE=on
	WEBCLIENTNOPROMPTFORCE=on
        ;;
esac
(( param ++ ))         # On to the next.
done
FORCEUPDATE=1
mainexec
fi
