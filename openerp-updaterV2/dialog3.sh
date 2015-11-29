#!/bin/bash


#MILESTONES=$(bzr tags | cut -d" " -f1 | grep ^$OPENERPSERIES |tr -d \n)
LISTMILESTONES="6.0.0 6.0.0-rc1 6.0.0-rc2 6.0.1"
#MILESTONES=(wipe erase delete "zap it")
MILESTONES=($LISTMILESTONES)
i=0

for item in "${MILESTONES[@]}"; do
array[i++]=$item
array[i++]=""
done

RELEASE=$(dialog --stdout --menu "Which OpenERP release would you like to update to?" 20 65 ${#MILESTONES[@]} "${array[@]}")

echo $RELEASE




options=(wipe erase delete "zap it")
i=0

for item in "${options[@]}"; do
array[i++]=$item
array[i++]=""
done

HEAD_OR_MILESTONE=$(dialog --stdout --menu "Woult  ?" 11 30 ${#options[@]} "${array[@]}")
echo $HEAD_OR_MILESTONE
