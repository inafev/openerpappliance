#!/bin/bash 
######################################################################################################################################################################
######################################################################################################################################################################
# File: openerp-updater.sh
# This script eases the update of openerp v6 on OpenERP turnkeylinux based virtual appliance (http://www.turnkeylinux.org/)
# Script based on http://opensourceconsulting.wordpress.com/2009/09/15/openerp-all-in-one-installer-update-for-dummies/
# Date: December 12th 2011
# Version: 2.1
# License: This script is released into GPLv3 (GNU GENERAL PUBLIC LICENSE Version 3)
######################################################################################################################################################################
######################################################################################################################################################################
# Author: Inaki Fernandez
# Senior IT Systems Engineer
# Madrid, Spain
# E-mail & Google Talk: openerpappliance_at_gmail_dot_com
# Twitter: twitter.com/linuxunixmadrid
# Blog: http://openerpappliance.com/
######################################################################################################################################################################
######################################################################################################################################################################

PSQLRELEASE=8.4
PYTHONRELEASE=python2.6
UBUNTURELEASE=10.04
INSTALLPATH=/usr/local
#SITEPACKAGESPATH=$INSTALLPATH/lib/$PYTHONRELEASE/site-packages
SITEPACKAGESPATH=$INSTALLPATH/lib/$PYTHONRELEASE/dist-packages
OPENERPSERVERPATH=$SITEPACKAGESPATH/openerp-server
ADDONSPATH=$OPENERPSERVERPATH/addons/   #/usr/local/lib/python2.6/dist-packages/openerp-server/addons/
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
OPENERPSERIES=6
declare -A REVISIONTAGPERBRANCH
REVISIONTAG=""
declare -A LOCALREVISIONPERBRANCH
declare -A LATESTREVISIONAVAILABLEONLAUNCHPADPERBRANCH
declare -A BZRINFOPERBRANCH
declare -A CHOSENMILESTONEPERBRANCH
declare -A LATESTMILESTONEONLAUNCHPADPERBRANCH

declare -A LOCAL_MILESTONE_PER_BRANCH[openerp-server]="NONE"
declare -A LOCAL_MILESTONE_PER_BRANCH[openerp-client]="NONE"
declare -A LOCAL_MILESTONE_PER_BRANCH[openerp-web]="NONE"
declare -A LOCAL_MILESTONE_PER_BRANCH[addons]="NONE"
declare -A LOCAL_MILESTONE_PER_BRANCH[extra-addons]="NONE"

declare -A BZR_BRANCH[openerp-server]="openobject-server/6.0"
declare -A BZR_BRANCH[openerp-client]="openobject-client/6.0"
declare -A BZR_BRANCH[openerp-web]="openobject-client-web/6.0"
declare -A BZR_BRANCH[addons]="openobject-addons/6.0"
declare -A BZR_BRANCH[extra-addons]="openobject-addons/extra-6.0"

CHOSENMILESTONEPERBRANCH[openerp-server]="Not updated"
CHOSENMILESTONEPERBRANCH[openerp-client]="Not updated"
CHOSENMILESTONEPERBRANCH[openerp-web]="Not updated"
CHOSENMILESTONEPERBRANCH[addons]="Not updated"
CHOSENMILESTONEPERBRANCH[extra-addons]="NONE"
LATESTMILESTONEONLAUNCHPADPERBRANCH[openerp-server]="Unknown"
LATESTMILESTONEONLAUNCHPADPERBRANCH[openerp-client]="Unknown"
LATESTMILESTONEONLAUNCHPADPERBRANCH[openerp-web]="Unknown"
LATESTMILESTONEONLAUNCHPADPERBRANCH[addons]="Unknown"
LATESTMILESTONEONLAUNCHPADPERBRANCH[extra-addons]="NONE"


function getRevisionTag()
{
local branch4=$1
unset MILESTONES1
unset MILESTONES2
unset MILESTONES3
unset MILESTONE
cd /home/openerp/production/$branch4
local MILESTONES1=$(bzr tags -d lp:${BZR_BRANCH[$branch4]} 2> /dev/null | cut -d" " -f1 | grep ^$OPENERPSERIES |tr -d \n)
local REVERSE_MILESTONES1=`echo $MILESTONES1 | tac -s' '`  # How to reverse a list in bash
local LATESTREVISIONAVAILABLEONLAUNCHPAD=${LATESTREVISIONAVAILABLEONLAUNCHPADPERBRANCH[$branch4]}
#local LOCALREVISION=$(bzr version-info | grep revno: | cut -d" " -f2)
local LOCALREVISION=$(bzr revno --tree 2> /dev/null)
local MILESTONES2="Latest revision available ($LATESTREVISIONAVAILABLEONLAUNCHPAD) $REVERSE_MILESTONES1"
local MILESTONES3=("Latest revision available ($LATESTREVISIONAVAILABLEONLAUNCHPAD) - Local revision:$LOCALREVISION" $REVERSE_MILESTONES1)

local i=0
for item in "${MILESTONES3[@]}"; do
  local array[i++]=$item
  local array[i++]=""
done

local tempfile=/tmp/getRevisionTag$$
local MILESTONE=$(dialog --stdout --title "OpenERP updater" --menu "Which $branch4 release or revision would you like to update to?" 25 80 ${#MILESTONES3[@]} "${array[@]}" 2> $tempfile)

if [ $? -eq 1 -o $? -eq 255 ];then  # 1 = Cancel pressed, 255 = ESC pressed
  rm -f $tempfile
  exit 0;
elif [ -z "$MILESTONE" ];then # if empty
  rm -f $tempfile
  exit 0;
fi
rm -f $tempfile

LATESTMILESTONEONLAUNCHPADPERBRANCH[$branch4]=$(echo $REVERSE_MILESTONES1 | cut -d" " -f1) # latest revision available
if [ -z "${LATESTMILESTONEONLAUNCHPADPERBRANCH[$branch4]}" ]; #if empty because $branch4 = extra-addons
then
  LATESTMILESTONEONLAUNCHPADPERBRANCH[$branch4]="NONE"
fi
#if [ "$MILESTONE" == "Latest revision available" ];then 
if [ "$MILESTONE" == "Latest revision available ($LATESTREVISIONAVAILABLEONLAUNCHPAD) - Local revision:$LOCALREVISION" ];then 
  REVISIONTAG=""
  CHOSENMILESTONEPERBRANCH[$branch4]=$(echo $REVERSE_MILESTONES1 | cut -d" " -f1) # latest revision available
  if [ -z "${CHOSENMILESTONEPERBRANCH[$branch4]}" ]; then
    CHOSENMILESTONEPERBRANCH[$branch4]="NONE"
  fi
else
  REVISIONTAG="-rtag:$MILESTONE" 
  CHOSENMILESTONEPERBRANCH[$branch4]=$MILESTONE
fi

#echo "LOOK4THISTRACEINLOGS-> getRevisionTag -> $branch4 -> MILESTONE=$MILESTONE , REVISIONTAG=$REVISIONTAG" >>$MYDESKTOP/OpenERP-updates.txt 2>&1

}


function getLaunchpadLatestMilestonePerBranchFunc()
{
  for b in openerp-server openerp-client openerp-web addons extra-addons;
  do
    if [ "${LATESTMILESTONEONLAUNCHPADPERBRANCH[$b]}" == "Unknown" ];then 
      cd /home/openerp/production/$b
      local MILESTONES1=$(bzr tags -d lp:${BZR_BRANCH[$b]} 2> /dev/null | cut -d" " -f1 | grep ^$OPENERPSERIES |tr -d \n)
      local REVERSE_MILESTONES1=`echo $MILESTONES1 | tac -s' '`  # How to reverse a list in bash
      LATESTMILESTONEONLAUNCHPADPERBRANCH[$b]=$(echo $REVERSE_MILESTONES1 | cut -d" " -f1) # latest revision available
      if [ -z "${LATESTMILESTONEONLAUNCHPADPERBRANCH[$b]}" ]; #if empty because $b = extra-addons
      then
	LATESTMILESTONEONLAUNCHPADPERBRANCH[$b]="NONE"
      fi
    fi
  done
}


#obtengo el milestone de la selección en el menu
function getLocalMilestonePerBranchFunc()
{
  for b in openerp-server openerp-client openerp-web addons extra-addons;
  do
      cd /home/openerp/production/$b
      local tmpfile=/tmp/bzrtags$$
      bzr tags | grep ^$OPENERPSERIES | grep -v ? | tr -d \n > $tmpfile 2>&1

      # use the builtin mapfile to read a file into an array (only Bash 4)
      # help mapfile
      # http://bash-hackers.org/wiki/doku.php/commands/builtin/mapfile
      mapfile -t <$tmpfile #local BZRTAGSARRAY
      #printf "%s\n" "${MAPFILE[@]}"
      local biggestrevn=0
      for ((i=0; i < "${#MAPFILE[@]}"; i++)); 
      do 
	#printf "%s\n" "${MAPFILE[${i}]}";
	local tagn=$(echo ${MAPFILE[${i}]} | cut -d" " -f1)
	local revn=$(echo ${MAPFILE[${i}]} | cut -d" " -f2 | tr -d . )
	#echo "localrevisionperbranc es ${LOCALREVISIONPERBRANCH[$b]}"
	local localrevn=$(echo ${LOCALREVISIONPERBRANCH[$b]} | tr -d . )
	if [ "$localrevn" -ge "$revn" -a "$revn" -gt "$biggestrevn" ] 2>/dev/null;then LOCAL_MILESTONE_PER_BRANCH[$b]=$tagn;biggestrevn=$revn ;fi
      done
      rm $tmpfile
  done
}

function updateChosenMilestonePerBranch()
{
  for b in openerp-server openerp-client openerp-web addons extra-addons;
  do

    if [ "${CHOSENMILESTONEPERBRANCH[$b]}" == "Not updated" ]; 
    then
      CHOSENMILESTONEPERBRANCH[$b]=${LOCAL_MILESTONE_PER_BRANCH[$b]}
    fi
  done
}

function getLocalAndLaunchpadRevisionsPerBranchFunc()
{
  for br in openerp-server openerp-client openerp-web addons extra-addons; 
  do 
    cd /home/openerp/production/$br;
    BZRINFOPERBRANCH[$br]=$(bzr info | grep 'parent branch' | awk '{ print $3}' 2> /dev/null)
    LOCALREVISIONPERBRANCH[$br]=$(bzr version-info | grep revno: | cut -d" " -f2 2> /dev/null)
    LATESTREVISIONAVAILABLEONLAUNCHPADPERBRANCH[$br]=$(bzr revno ${BZRINFOPERBRANCH[$br]} 2> /dev/null)
  done
}

function updateBranchFunc()
{
  local branch3=$1
  cd /home/openerp/production/$branch3
  bzr pull ${REVISIONTAGPERBRANCH[$branch3]} >>$MYDESKTOP/OpenERP-updates.txt 2>&1
  #echo "LOOK4THISTRACEINLOGS-> $branch3 -> revision a actualizar ${REVISIONTAGPERBRANCH[$branch3]}" >>$MYDESKTOP/OpenERP-updates.txt 2>&1
  bzr update ${REVISIONTAGPERBRANCH[$branch3]} >>$MYDESKTOP/OpenERP-updates.txt 2>&1
}


function check4newrevisionsfunc()
{
local  __newrevisionsfound=$1
local  newrevisionsfound=0

local  __listbranches=$2
local  listbranches=""
local branch

SERVERSTATUS=7
CLIENTSTATUS=7
WEBSTATUS=7
ADDONSSTATUS=7
EXTRAADDONSSTATUS=7

getLocalAndLaunchpadRevisionsPerBranchFunc;
getLocalMilestonePerBranchFunc;

for i in 5 10 20 30 40 50 60 70 80 90 100
do
$DIALOG --backtitle "$background" \
        --title "Checking for new OpenERP revisions" \
        --mixedgauge "OpenERP-updates.txt file contains information about the updated OpenERP revisions.This is useful for managing your updates.\n\nCommand-line options: openerp-updater.sh --help" \
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
  branch=openerp-server
  if [ "${LOCALREVISIONPERBRANCH[$branch]}" != "${LATESTREVISIONAVAILABLEONLAUNCHPADPERBRANCH[$branch]}" ];
  then
    newrevisionsfound=1
    listbranches=$listbranches"openerp-server  ${LOCAL_MILESTONE_PER_BRANCH[openerp-server]} on "
  else
    listbranches=$listbranches"openerp-server  ${LOCAL_MILESTONE_PER_BRANCH[openerp-server]} off "
  fi
  SERVERSTATUS=3;
  ;;
  20)
  branch=openerp-client
  if [ "${LOCALREVISIONPERBRANCH[$branch]}" != "${LATESTREVISIONAVAILABLEONLAUNCHPADPERBRANCH[$branch]}" ];
  then
    newrevisionsfound=1
    listbranches=$listbranches"openerp-client ${LOCAL_MILESTONE_PER_BRANCH[openerp-client]} on "
  else
    listbranches=$listbranches"openerp-client ${LOCAL_MILESTONE_PER_BRANCH[openerp-client]} off "
  fi
  CLIENTSTATUS=3;
  ;;
  40)
  branch=openerp-web
  if [ "${LOCALREVISIONPERBRANCH[$branch]}" != "${LATESTREVISIONAVAILABLEONLAUNCHPADPERBRANCH[$branch]}" ];
  then
    newrevisionsfound=1
    listbranches=$listbranches"openerp-web ${LOCAL_MILESTONE_PER_BRANCH[openerp-web]} on "
  else
    listbranches=$listbranches"openerp-web ${LOCAL_MILESTONE_PER_BRANCH[openerp-web]} off "
  fi
  WEBSTATUS=3;
  ;;
  60)
  branch=addons
  if [ "${LOCALREVISIONPERBRANCH[$branch]}" != "${LATESTREVISIONAVAILABLEONLAUNCHPADPERBRANCH[$branch]}" ];
  then
    newrevisionsfound=1
    listbranches=$listbranches"Addons ${LOCAL_MILESTONE_PER_BRANCH[addons]} on "
  else
    listbranches=$listbranches"Addons ${LOCAL_MILESTONE_PER_BRANCH[addons]} off "
  fi
  ADDONSSTATUS=3;
  ;;
  80)
  branch=extra-addons
  if [ "${LOCALREVISIONPERBRANCH[$branch]}" != "${LATESTREVISIONAVAILABLEONLAUNCHPADPERBRANCH[$branch]}" ];
  then
    newrevisionsfound=1
    listbranches=$listbranches"extra-addons ${LOCAL_MILESTONE_PER_BRANCH[extra-addons]} on "
  else
    listbranches=$listbranches"extra-addons ${LOCAL_MILESTONE_PER_BRANCH[extra-addons]} off "
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
#LISTBRANCHES="openerp-server branch $SERVERNOPROMPTFORCE openerp-client branch $CLIENTNOPROMPTFORCE openerp-web branch $WEBCLIENTNOPROMPTFORCE Addons branch $ADDONSNOPROMPTFORCE extra-addons branch $EXTRAADDONSNOPROMPTFORCE"
LISTBRANCHES="openerp-server ${LOCAL_MILESTONE_PER_BRANCH[openerp-server]} $SERVERNOPROMPTFORCE openerp-client ${LOCAL_MILESTONE_PER_BRANCH[openerp-client]} $CLIENTNOPROMPTFORCE openerp-web ${LOCAL_MILESTONE_PER_BRANCH[openerp-web]} $WEBCLIENTNOPROMPTFORCE Addons ${LOCAL_MILESTONE_PER_BRANCH[addons]} $ADDONSNOPROMPTFORCE extra-addons ${LOCAL_MILESTONE_PER_BRANCH[extra-addons]} $EXTRAADDONSNOPROMPTFORCE"
else
check4newrevisionsfunc NEWREVISIONSFOUND LISTBRANCHES
fi
#echo "LOOK4THISTRACEINLOGS-> LISTBRANCHES A ACTUALIZAR $LISTBRANCHES" >>$MYDESKTOP/OpenERP-updates.txt 2>&1
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
    #LISTBRANCHES='openerp-server branch on openerp-client branch on openerp-web branch on Addons branch on extra-addons branch on'
    LISTBRANCHES="openerp-server ${LOCAL_MILESTONE_PER_BRANCH[openerp-server]} on openerp-client ${LOCAL_MILESTONE_PER_BRANCH[openerp-client]} on openerp-web ${LOCAL_MILESTONE_PER_BRANCH[openerp-web]} on Addons ${LOCAL_MILESTONE_PER_BRANCH[addons]} on extra-addons ${LOCAL_MILESTONE_PER_BRANCH[extra-addons]} on"
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


#for branch in openerp-server openerp-client openerp-web extra-addons addons
BRANCHESTOREINSTALL2=$(echo $BRANCHESTOREINSTALL | sed "s#\"##g" | tr "[:upper:]" "[:lower:]")  # converting 'Addons' to 'addons'
for branch2 in $BRANCHESTOREINSTALL2
do
  getRevisionTag $branch2 
  REVISIONTAGPERBRANCH[$branch2]=$REVISIONTAG
done


for i in 5 10 20 30 40 50 60 70 80 90 100
do
$DIALOG --backtitle "$background" \
        --title "Updating OpenERP with latest revisions from launchpad.net" \
        --mixedgauge "OpenERP-updates.txt file contains information about the updated OpenERP revisions.This is useful for managing your updates.\n\nCommand-line options: openerp-updater.sh --help" \
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
    branch=openerp-server
    updateBranchFunc $branch;
  fi
  SERVERSTATUS=3;
  ;;
  20)
  if [ $NEWCLIENTREVISIONS -eq 1 ];
  then
    branch=openerp-client
    updateBranchFunc $branch;
  fi
  CLIENTSTATUS=3;
  ;;
  40)
  if [ $NEWWEBREVISIONS -eq 1 ];
  then
    branch=openerp-web
    updateBranchFunc $branch;
  fi
  WEBSTATUS=3;
  ;;
  60)
  if [ $NEWADDONSREVISIONS -eq 1 ];
  then
    branch=addons
    updateBranchFunc $branch;
  fi
  ADDONSSTATUS=3;
  ;;
  80)
  if [ $NEWEXTRAADDONSREVISIONS -eq 1 ];
  then
    branch=extra-addons
    updateBranchFunc $branch;
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
        --mixedgauge "OpenERP-updates.txt file contains information about the updated OpenERP revisions.This is useful for managing your updates.\n\nCommand-line options: openerp-updater.sh --help" \
                0 0 $i \
                "Stopping OpenERP Server and OpenERP Web"       "$STOPSTATUS" \
                "Reinstalling OpenERP Server"        		"$SERVERREINSTALLSTATUS" \
                "Reinstalling OpenERP Extra-Addons"             "$EXTRAADDONSINSTALLSTATUS" \
                "Reinstalling OpenERP Addons"		   	"$ADDONSINSTALLSTATUS" \
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
  sudo python setup.py install > /dev/null 2>&1
  fi
  SERVERREINSTALLSTATUS=3;
  ;;
  30)
  if [ $NEWEXTRAADDONSREVISIONS -eq 1 ];
  then
  sudo ln -sf /home/openerp/production/extra-addons/* $ADDONSPATH > /dev/null 2>&1
  sudo chown -R openerp.root $ADDONSPATH > /dev/null 2>&1
  sudo chmod 755 $ADDONSPATH > /dev/null 2>&1
  fi
  EXTRAADDONSINSTALLSTATUS=3;
  ;;
  45)
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
  60)
  sudo $INSTALLPATH/bin/openerp-server --stop-after-init --update=all --logfile=/var/log/openerp/openerp.log > /dev/null 2>&1
  MODULESUPDATESTATUS=3;
  ;;
  75)
  if [ $NEWCLIENTREVISIONS -eq 1 ];
  then
    cd /home/openerp/production/openerp-client
    sudo python setup.py install > /dev/null 2>&1
    # This is a fix for openerp-client bug https://bugs.launchpad.net/openobject-client/+bug/674231 
    ###if [[ "$REVISIONTAG" =~ "rtag" ]]; then # REVISIONTAG="-rtag:$MILESTONE"
      ###RELEASE=$MILESTONE 
    ###fi # else RELEASE is the one specified in first lines
    #echo "sudo ln -s /usr/local/lib/python2.6/dist-packages/openerp_client-${CHOSENMILESTONEPERBRANCH[openerp-client]}-py2.6.egg/openerp-client /usr/local/lib/python2.6/dist-packages/openerp-client" >>$MYDESKTOP/OpenERP-updates.txt
    if [ -e "/usr/local/lib/python2.6/dist-packages/openerp-client" ]; then 
      sudo rm /usr/local/lib/python2.6/dist-packages/openerp-client > /dev/null 2>&1 
    fi
    if [ -e "/usr/share/pixmaps/openerp-client" ]; then 
      sudo rm /usr/share/pixmaps/openerp-client > /dev/null 2>&1
    fi
    if [ -e "/usr/share/openerp-client" ]; then 
      sudo rm /usr/share/openerp-client > /dev/null 2>&1
    fi
    sudo ln -sf /usr/local/lib/python2.6/dist-packages/openerp_client-${CHOSENMILESTONEPERBRANCH[openerp-client]}-py2.6.egg/openerp-client /usr/local/lib/python2.6/dist-packages/openerp-client > /dev/null 2>&1
    sudo ln -sf /usr/local/lib/python2.6/dist-packages/openerp_client-${CHOSENMILESTONEPERBRANCH[openerp-client]}-py2.6.egg/share/pixmaps/openerp-client /usr/share/pixmaps/openerp-client > /dev/null 2>&1          
    sudo ln -sf /usr/local/lib/python2.6/dist-packages/openerp_client-${CHOSENMILESTONEPERBRANCH[openerp-client]}-py2.6.egg/share/openerp-client /usr/share/openerp-client > /dev/null 2>&1 
  fi
  CLIENTINSTALLSTATUS=3;
  ;;
  90)
  if [ $NEWWEBREVISIONS -eq 1 ];
  then
  cd /home/openerp/production/openerp-web
  sudo python setup.py install > /dev/null 2>&1
  #sudo easy_install -U openerp-web > /dev/null 2>&1  
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

getLocalAndLaunchpadRevisionsPerBranchFunc;
getLocalMilestonePerBranchFunc;
updateChosenMilestonePerBranch;
getLaunchpadLatestMilestonePerBranchFunc;

REPORT="CURRENT OPENERP APPLIANCE REVISIONS (Local Working Tree): \n
openerp-server: ${LOCALREVISIONPERBRANCH[openerp-server]} (${CHOSENMILESTONEPERBRANCH[openerp-server]})\n
openerp-client: ${LOCALREVISIONPERBRANCH[openerp-client]} (${CHOSENMILESTONEPERBRANCH[openerp-client]})\n
openerp-web: ${LOCALREVISIONPERBRANCH[openerp-web]} (${CHOSENMILESTONEPERBRANCH[openerp-web]})\n
addons: ${LOCALREVISIONPERBRANCH[addons]} (${CHOSENMILESTONEPERBRANCH[addons]})\n
extra-addons: ${LOCALREVISIONPERBRANCH[extra-addons]} (${CHOSENMILESTONEPERBRANCH[extra-addons]})\n\n
LATEST REVISIONS AVAILABLE ON LAUNCHPAD (Remote Parent Tree):\n
openerp-server: ${LATESTREVISIONAVAILABLEONLAUNCHPADPERBRANCH[openerp-server]} (${LATESTMILESTONEONLAUNCHPADPERBRANCH[openerp-server]})\n
openerp-client: ${LATESTREVISIONAVAILABLEONLAUNCHPADPERBRANCH[openerp-client]} (${LATESTMILESTONEONLAUNCHPADPERBRANCH[openerp-client]})\n
openerp-web: ${LATESTREVISIONAVAILABLEONLAUNCHPADPERBRANCH[openerp-web]} (${LATESTMILESTONEONLAUNCHPADPERBRANCH[openerp-web]})\n
addons: ${LATESTREVISIONAVAILABLEONLAUNCHPADPERBRANCH[addons]} (${LATESTMILESTONEONLAUNCHPADPERBRANCH[addons]})\n
extra-addons: ${LATESTREVISIONAVAILABLEONLAUNCHPADPERBRANCH[extra-addons]} (${LATESTMILESTONEONLAUNCHPADPERBRANCH[extra-addons]})\n\n
PARENT BRANCH PER LOCAL WORKING TREE:\n
openerp-server: ${BZRINFOPERBRANCH[openerp-server]}\n
openerp-client: ${BZRINFOPERBRANCH[openerp-client]}\n
openerp-web: ${BZRINFOPERBRANCH[openerp-web]}\n
addons: ${BZRINFOPERBRANCH[addons]}\n
extra-addons: ${BZRINFOPERBRANCH[extra-addons]}\n\n
Destination Tree is the Local Working Tree. Parent branch of Local Tree = Remote Tree\n\n"

datereport=$(date)

echo >>$MYDESKTOP/OpenERP-updates.txt
echo "#####################################################################################################">>$MYDESKTOP/OpenERP-updates.txt
echo "  O P E N E R P    A P P L I A N C E    U P D A T E    R E P O R T : $datereport ">>$MYDESKTOP/OpenERP-updates.txt
echo >> $MYDESKTOP/OpenERP-updates.txt
echo "  Author: Inaki Fernandez " >>$MYDESKTOP/OpenERP-updates.txt
echo "  http://openerpappliance.com" >>$MYDESKTOP/OpenERP-updates.txt 
echo "#####################################################################################################">>$MYDESKTOP/OpenERP-updates.txt
echo "CURRENT OPENERP APPLIANCE REVISIONS (Local Working Tree): ">>$MYDESKTOP/OpenERP-updates.txt
echo "openerp-server: ${LOCALREVISIONPERBRANCH[openerp-server]} (${CHOSENMILESTONEPERBRANCH[openerp-server]})">>$MYDESKTOP/OpenERP-updates.txt
echo "openerp-client: ${LOCALREVISIONPERBRANCH[openerp-client]} (${CHOSENMILESTONEPERBRANCH[openerp-client]})">>$MYDESKTOP/OpenERP-updates.txt
echo "openerp-web: ${LOCALREVISIONPERBRANCH[openerp-web]} (${CHOSENMILESTONEPERBRANCH[openerp-web]})">>$MYDESKTOP/OpenERP-updates.txt
echo "addons: ${LOCALREVISIONPERBRANCH[addons]} (${CHOSENMILESTONEPERBRANCH[addons]})">>$MYDESKTOP/OpenERP-updates.txt
echo "extra-addons: ${LOCALREVISIONPERBRANCH[extra-addons]} (${CHOSENMILESTONEPERBRANCH[extra-addons]})">>$MYDESKTOP/OpenERP-updates.txt
echo >>$MYDESKTOP/OpenERP-updates.txt
echo "LATEST REVISIONS AVAILABLE ON LAUNCHPAD (Remote Tree): ">>$MYDESKTOP/OpenERP-updates.txt
echo "openerp-server: ${LATESTREVISIONAVAILABLEONLAUNCHPADPERBRANCH[openerp-server]} (${LATESTMILESTONEONLAUNCHPADPERBRANCH[openerp-server]})">>$MYDESKTOP/OpenERP-updates.txt
echo "openerp-client: ${LATESTREVISIONAVAILABLEONLAUNCHPADPERBRANCH[openerp-client]} (${LATESTMILESTONEONLAUNCHPADPERBRANCH[openerp-client]})">>$MYDESKTOP/OpenERP-updates.txt
echo "openerp-web: ${LATESTREVISIONAVAILABLEONLAUNCHPADPERBRANCH[openerp-web]} (${LATESTMILESTONEONLAUNCHPADPERBRANCH[openerp-web]})">>$MYDESKTOP/OpenERP-updates.txt
echo "addons: ${LATESTREVISIONAVAILABLEONLAUNCHPADPERBRANCH[addons]} (${LATESTMILESTONEONLAUNCHPADPERBRANCH[addons]})">>$MYDESKTOP/OpenERP-updates.txt
echo "extra-addons: ${LATESTREVISIONAVAILABLEONLAUNCHPADPERBRANCH[extra-addons]} (${LATESTMILESTONEONLAUNCHPADPERBRANCH[extra-addons]})">>$MYDESKTOP/OpenERP-updates.txt
echo >>$MYDESKTOP/OpenERP-updates.txt
echo "PARENT BRANCH PER LOCAL WORKING TREE:">>$MYDESKTOP/OpenERP-updates.txt
echo "openerp-server: ${BZRINFOPERBRANCH[openerp-server]}">>$MYDESKTOP/OpenERP-updates.txt
echo "openerp-client: ${BZRINFOPERBRANCH[openerp-client]}">>$MYDESKTOP/OpenERP-updates.txt
echo "openerp-web: ${BZRINFOPERBRANCH[openerp-web]}">>$MYDESKTOP/OpenERP-updates.txt
echo "addons: ${BZRINFOPERBRANCH[addons]}">>$MYDESKTOP/OpenERP-updates.txt
echo "extra-addons: ${BZRINFOPERBRANCH[extra-addons]}">>$MYDESKTOP/OpenERP-updates.txt
echo >>$MYDESKTOP/OpenERP-updates.txt
echo "Destination Tree is the Local Working Tree. Parent branch of Local Working Tree = Remote Tree">>$MYDESKTOP/OpenERP-updates.txt
echo >>$MYDESKTOP/OpenERP-updates.txt
echo "#####################################################################################################">>$MYDESKTOP/OpenERP-updates.txt
echo >>$MYDESKTOP/OpenERP-updates.txt
echo >>$MYDESKTOP/OpenERP-updates.txt

if [ $FORCEUPDATE -eq 0 ]; 
then
$DIALOG --title "OpenERP updater" --clear \
        --msgbox "OpenERP has been updated and restarted\n\n
$REPORT
OpenERP-updates.txt file contains information about the updated OpenERP revisions.This is useful for managing your updates.\n\n
Command-line options: openerp-updater.sh --help
\n\nPress OK to exit" 40 95
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
