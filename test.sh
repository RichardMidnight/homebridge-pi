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

setup_colors() {
# setup some screen colors
# https://stackoverflow.com/questions/5947742/how-to-change-the-output-color-of-echo-in-linux
# https://misc.flogisoft.com/bash/tip_colors_and_formatting
# for (( i = 30; i < 38; i++ )); do echo -e "\033[0;"$i"m Normal: (0;$i); \033[1;"$i"m light: (1;$i)"; done
BLACK='\033[0;30m'
RED='\033[0;31m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
LTGREY='\033[0;37m'

GREY='\033[1;30m'
LTRED='\033[1;31m'
LTGREEN='\033[1;32m'
YELLOW='\033[1;33m'
LTBLUE='\033[1;34m'
LTPURPLE='\033[1;35m'
LTCYAN='\033[1;36m'
WHITE='\033[1;37m'

BLUE_BK='\033[1;44m'	# blue background
RED_BK='\033[1;41m'  # red background
NC='\033[0m' 		# No Color, standard text

echo_red()          { (echo -e "${LTRED}$*${NC}") }
echo_white_on_red() { (echo -e "${WHITE}${RED_BK}$*${NC}") }
echo_blue_bk()      { (echo -e "${BLUE_BK}$*${NC}") }
echo_blue()         { (echo -e "${LTBLUE}$*${NC}") }
echo_blue_ne()      { (echo -e -ne "${BLUE}$*${NC}") }
echo_green()        { (echo -e "${GREEN}$*${NC}") }
echo_white()        { (echo -e "${WHITE}$*${NC}") }
echo_white_ne()     { (echo -e -ne "${WHITE}$*${NC}") }
echo_black()        { (echo -e "${BLACK}$*${NC}") }
}

setup_colors
echo_blue Hello World
help
