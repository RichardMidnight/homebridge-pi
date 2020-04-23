#!/bin/bash

help() {
echo This script greatly simplifies the installation of Homebridge on a Raspberry Pi
echo
echo_red WARNING... this will clobber any existing homebrige installation
echo
echo Tested in 2019 and 2020 with Raspberry Pi 3  and 4 running Buster and Stretch incl lite versions
echo  - It requires internet access 
echo  - It expects a clean installation of Raspbian and logged in as pi
echo  - It prefers all packages to be updated
echo  - It tries to use the most current standard releases
echo 
echo This will install 
echo  - all the Homebridge prerequisites
echo  - homebrige server and homebridge service
echo  - the config-ui-x plug-in
echo
echo Usage - only one switch allowed:
echo no switch - install with prompts
echo -y answer yes on install
echo -u uninstall
echo -i homebridge info
echo -h help
}

echo Hello World
help
