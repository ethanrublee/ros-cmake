#!/bin/sh -e

WORK=$(dirname $(dirname $(readlink -f $0)))
if [ ! -d "$WORK/cmake/patches" ] ; then
    echo "Hmm.  Errors determining where we are."
    return 1
fi

for dir in $WORK/cmake/patches/*
do
    if [ -d $dir ] ; then
	bn=$(basename $dir)
	echo "rsync-patching $bn"
	rsync -a $dir/ $WORK/$bn/
    fi
done
