#!/bin/bash

options=(wipe erase delete "zap it")
i=0

for item in "${options[@]}"; do
array[i++]=$item
array[i++]=""
done

dialog --menu "Shall I ... ?" 11 30 ${#options[@]} "${array[@]}"

# ----- checklist ----- #

options=(wipe erase delete "zap it")
i=0; counter=0

for item in "${options[@]}"; do
(( counter++ ))
array[i++]=$counter
array[i++]=$item
array[i++]="off"
done

dialog --checklist "Shall I ... ?" 11 50 ${#options[@]} "${array[@]}"



