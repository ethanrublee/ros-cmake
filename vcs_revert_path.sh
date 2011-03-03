#!/bin/bash

IFS=':'

read -ra PATHS <<< "$1"

IFS=" "
for i in ${PATHS[@]}
do
    echo $i
    if [ $(basename $i) = "cmake" ] ; then
        echo "skipping revert of cmake"
        continue
    fi
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
    if [ -d "$i/.git" ]
    then
        echo "git: $i"
        read FOO
        pushd $i
        git clean -fd
        git reset --hard HEAD
        popd
    fi
done


rm -f rosidl/CMakeLists.txt
