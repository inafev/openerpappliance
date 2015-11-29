#!/bin/bash


assertIsSet() {
    [[ ! ${!1} && ${!1-_} ]] && {
        echo "$1 is not set, aborting." >&2
        exit 1
    }
}


#MILESTONES=$(bzr tags | cut -d" " -f1 | grep ^$OPENERPSERIES |tr -d \n)
MILESTONES1="6.0.0 6.0.0-rc1 6.0.0-rc2 6.0.1"
MILESTONES2="$MILESTONES1 Latest revision available"
#MILESTONES=(wipe erase delete "zap it")
MILESTONES3=($MILESTONES1 "Latest revision available")
i=0

for item in "${MILESTONES3[@]}"; do
array[i++]=$item
array[i++]=""
done


RELEASE=$(dialog --stdout --menu "Which OpenERP release would you like to update to?" 20 85 ${#MILESTONES3[@]} "${array[@]}")

echo $?
if [ -z $RELEASE ];then echo "hola";
elif [ -n $RELEASE ];then echo "hola2";
fi

if [[ "$MILESTONES2" =~ "$RELEASE" ]];then
    echo $RELEASE
fi



