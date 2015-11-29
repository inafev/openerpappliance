#!/bin/bash

declare -A REVISIONTAGPERBRANCH
REVISIONTAG="uno"
branch2=hash1
REVISIONTAGPERBRANCH=( ["$branch2"]="$REVISIONTAG" )
REVISIONTAGPERBRANCH=( ["dos"]="otrohash" )
echo ${REVISIONTAGPERBRANCH[hash1]}
echo ${REVISIONTAGPERBRANCH[dos]}
#echo "${animals["moo"]}"
#for sound in "${!animals[@]}"; do echo "$sound - ${animals["$sound"]}"; done



REVISIONTAGPERBRANCH[$branch2]=$REVISIONTAG
REVISIONTAGPERBRANCH["dos"]="otrohash"
echo ${REVISIONTAGPERBRANCH[$branch2]}
echo ${REVISIONTAGPERBRANCH["dos"]}



declare -A animals=( ["moo"]="cow" )
animals=( ["moo2"]="cow2" )
echo "${animals["moo"]}"
for sound in "${!animals[@]}"; do echo "$sound - ${animals["$sound"]}"; done

#typeset -A newmap 
declare -A newmap
newmap[name]="Irfan Zulfiqar"
newmap[designation]=SSE
newmap[company]="My Own Company"

echo ${newmap[company]}
echo ${newmap[name]}
