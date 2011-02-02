#!/bin/bash

IFS=':'

read -ra PATHS <<< "$1"

IFS=" "
for i in ${PATHS[@]}
do
    echo $i
    if [ -d "$i/.hg" ] 
    then
        echo "hg: $i"
        pushd $i
        hg pull
        hg revert -a --no-backup
        hg update
        popd
    fi
    if [ -d "$i/.svn" ]
    then
        echo "svn: $i"
        pushd $i
        svn revert -R .
        svn update
	for j in `svn status | awk 'BEGIN {ORS=" ";} /^\?/ { print $2 }'` ; do
	    rm -r $j
	done
        popd
    fi
done


rm rosidl/CMakeLists.txt
