#!/bin/bash

IFS=':'

read -ra PATHS <<< "$1"

for i in ${PATHS[@]}
do
    echo $i
    if [ -d "$i/.hg" ] 
    then
        echo "hg: $i"
        pushd $i
        hg revert -a --no-backup
        popd
    fi
    if [ -d "$i/.svn" ]
    then
        echo "svn: $i"
        pushd $i
        svn revert -R .
        popd
    fi
done


