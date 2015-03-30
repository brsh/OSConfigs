#!/bin/bash

function whichOS {
# because not everything works the same everywhere
local Distro
BaseOS=$(uname -s)


case "${BaseOS}" in
        Darwin )
                Distro="MacOS"
        ;;
        Linux )
                Distro=$(cat /etc/*-release 2> /dev/null | grep ^NAME= | cut -d = -f2)
        ;;
        CYGWIN* )
                Distro="Windows"
                BaseOS="CYGWIN"
        ;;
        * )
                Distro="${BaseOS}"
esac
printf "${Distro}"
}
