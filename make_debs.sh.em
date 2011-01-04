#!/bin/sh

for p in @(' '.join(projects))
do
    echo ">>> ${p}"
    sed "s/;ALL/;$p/" CPackConfig.cmake | sed "s/cpacked/$p/ " > ${p}.CPackConfig.cmake
    cpack --config ${p}.CPackConfig.cmake
done

