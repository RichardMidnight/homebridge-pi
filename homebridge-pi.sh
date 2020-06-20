#!/bin/bash
# homebridge-pi install, uninstall, monitor etc.

# 2018/8/2; 2020/05/27
# By Richard Reed

#note: jessey amd64 desktop needs this first:
#sudo apt-get install python-minimal:amd64 -y

#
# to download and run...
# curl -O  https://raw.githubusercontent.com/RichardMidnight/homebridge-pi/master/homebridge-pi.sh
# bash homebridge-pi.sh install
#

#note:  sudo systemctl daemon-reload


SCRIPT_VER=20200620.002

#minimums
NODEJS_MIN=12
NODEJS_REC=12
PI4_WIPI_MIN=2.52
  
  
BACKUP_FOLDER="/var/lib/homebridge/backups"
SERVICE_ACCOUNT=$(whoami)
SCRIPT_SOURCE="https://raw.githubusercontent.com/RichardMidnight/homebridge-pi/master/homebridge-pi.sh"
SCRIPT_NAME=${0##*/}



####################################################################################
help() {
echo This script greatly simplifies the installation and minor debugging of Homebridge on a Raspberry Pi.
echo
echo_red WARNING... this may clobber any existing homebridge installation
echo
echo Usage: "bash homebridge-pi.sh [install|uninstall|update|start|stop|restart|logs|sysinfo|backup] [option]"
echo Options:
echo "  -y                 auto answer yes to most prompts"
echo "  -nodejs[xx]        force version xx of nodejs on install"
echo "  -rename            rename homebridge based on serial number"
echo "  -j                 display and check config.json file"
echo "  -v, --version      output script version"
echo "  -h, --help         more help" 
echo
echo "EXAMPLE:  bash homebridge-pi.sh install"

}


help2(){
echo
echo It DOES NOT create a hardened install.

echo  - Tested in 2019 and 2020 with Raspberry Pi zero, 3  and 4 running Stretch or Buster incl lite versions
echo  - It works pretty well on Debian 9, Debian 10, LMDE, and Raspbian desktop, all on virtualbox
echo  - It seems to be pretty compatible with std Debian systems.
echo
echo  - It requires internet access 
echo  - It expects a clean installation of Raspbian and logged in as pi
echo  - It prefers all packages to be updated
echo  - It tries to use the most current standard distribution packages
echo  - As of May 2020, non-standard packages include: 
echo  --- node less than $NODEJS_REC gets upgraded to nodejs $NODEJS_REC
echo  --- npm get updated to latest
echo  --- wiring pi less than $PI4_WIPI_MIN on pi4 gets updated to latest
echo 
echo This will install 
echo  - all the Homebridge prerequisites
echo  - Homebrige server
echo "- the config-ui-x plug-in (popular browser-based interface) "
echo  - Homebridge service
echo  - Adds two shorcuts to the desktop.  homebridge-folder and config-ui
echo
}




####################################################################################
#Library
####################################################################################

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
RED_BK='\033[1;41m'  	# red background
NC='\033[0m' 			# No Color, standard text

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



check_exit_code(){
# $1 is exit code
  if [[ $1 == 0 ]] ; then
    echo_green OK
  else
    ERROR_COUNT=$((ERROR_COUNT+1))
    echo_white_on_red  Homebridge-pi ERROR! Exit code: $1
	echo Not all errors are fatal
	echo 1 - You can press any key to ignore and continue
	echo 2 - You can exit this with Ctrl-c and try running it again 
	echo 3 - You can look at the messages on the screen for clues on how to resolve the problem
    echo_white Press any key to continue.
    read -n1
  fi
}



compare_nums()
{
   # Function to compare two numbers (float or integers) by using awk.
   # The function will not print anything, but it will return 0 (if the comparison is true) or 1
   # (if the comparison is false) exit codes, so it can be used directly in shell one liners.
   #############
   ### Usage ###
   ### Note that you have to enclose the comparison operator in quotes.
   #############
   # compare_nums 1 ">" 2 # returns false
   # compare_nums 1.23 "<=" 2 # returns true
   # compare_nums -1.238 "<=" -2 # returns false
   #############################################
   num1=$1
   op=$2
   num2=$3
   E_BADARGS=65

   # Make sure that the provided numbers are actually numbers.
   if ! [[ $num1 =~ ^-?[0-9]+([.][0-9]+)?$ ]]; then >&2 echo "$num1 is not a number"; return $E_BADARGS; fi
   if ! [[ $num2 =~ ^-?[0-9]+([.][0-9]+)?$ ]]; then >&2 echo "$num2 is not a number"; return $E_BADARGS; fi

   # If you want to print the exit code as well (instead of only returning it), uncomment
   # the awk line below and comment the uncommented one which is two lines below.
   #awk 'BEGIN {print return_code=('$num1' '$op' '$num2') ? 0 : 1; exit} END {exit return_code}'
   awk 'BEGIN {return_code=('$num1' '$op' '$num2') ? 0 : 1; exit} END {exit return_code}'
   return_code=$?
   return $return_code
}



verToInt() {
	# this is not currently used... but clever
	local IFS=.
	parts=($1)
	let val=1000000*parts[0]+1000*parts[1]+parts[2]
	echo $val
}



update_script() {
	curl $SCRIPT_SOURCE$SCRIPT_NAME -s -o $SCRIPT_NAME.new
	NEW_VER=$(bash $SCRIPT_NAME.new -v)
	#check_exit_code $?
	
	if compare_nums $SCRIPT_VER "<" $NEW_VER ; then
	echo_red NOTE:
	  echo -n Script ver $SCRIPT_VER. Update to $NEW_VER available. Get it and exit?
	  read -n1 -r RESULT
	  echo
	  if [[ $RESULT == "y" ]] ; then
	    mv -f $SCRIPT_NAME.new $SCRIPT_NAME
		exit
	  fi
	else
		echo Script ver $SCRIPT_VER up to date.
		rm $SCRIPT_NAME.new
	fi
}



pi_model() {
  # -s means short version

  if [ -f "/proc/device-tree/model" ]; then
    case $1 in
    -s)
     revision=$(cat /proc/cpuinfo | grep 'Revision' | cut -d: -f2 | sed -e 's/^[ \t]*//')
      case $revision in
        c03111)	  model="4B"	;;   #4GB
        b03111)	  model="4B"	;;   #2GB
        a03111)	  model="4B"	;;   #1GB
        9020e0)	  model="3A+"		;;
        a020d3)	  model="3B+"		;;
        a32082)	  model="3B"		;;
        a22082)	  model="3B"		;;
        a02082)   model="3B"		;;
        *)	  model="unknown"	;;
      esac
      echo $model
      ;;

    *)
      # like: Raspberry Pi 3 Model B Rev 1.2
      cat /proc/device-tree/model
      echo
      ;;
    esac
  else 
    echo "not a raspberry pi"
  fi
}



os_version() {
  # -s = short
  case $1 in
  -s)
    cat /etc/os-release | grep "PRETTY_NAME=" | cut -d '"' -f2 | cut -d\( -f2 | cut -d \) -f1
  ;;

  *)
    cat /etc/os-release | grep "PRETTY_NAME=" | cut -d '"' -f2
    # EG: Raspbian GNU/Linux 9 (stretch)
    ;;
  esac
}



wiringpi_ver() {
  if [ $(which gpio) ]; then
     gpio -v | grep version | cut -d" " -f3
  else
    echo 0  
  fi
}



check_config_json() {
  #  -v = verbose     -e = verbose on error only
  jq . /var/lib/homebridge/config.json > null
  error_code=$?
  #echo $error_code
  
  if [ $error_code == 0 ]; then
    if [ $1 == '-v' ];then
      echo No errors in config.json
    fi
    return 0  # true
  else
    if [ $1 == '-v' ]  || [ $1 == '-e' ] ;then
      echo_red ERROR in config.json
    fi
    return 1  #false
  fi
}  



##################################################################
# configuration section
##################################################################

hw_serial_no() {
  # get raspberry pi serial number if it can
  SN=$(cat /proc/cpuinfo | grep Serial | cut -d ' ' -f 2 | tr '[:lower:]' '[:upper:]')

  if [[ $SN == "" ]]; then
    SN=$(sudo dmidecode -s baseboard-serial-number)
  fi

  if [[ $SN == "" ]] || [[ $SN == "0" ]] ; then
	SN2=$(sudo dmidecode -s system-uuid)
	SN=${SN2: -16}
  fi 
  
  
  if [[ $SN == "" ]] || [[ $SN == "0" ]] ; then
	#SN="0000999999999999"
	SN="0000000000000000"
  fi
  echo $SN
}


homebridge_username_current() {
  #sudo cat /var/lib/homebridge/config.json | grep username | cut -d\" -f4
  jq .bridge.username /var/lib/homebridge/config.json | cut -d\" -f2
}


homebridge_username_target() { 
  PI_SERIAL_NO=$(hw_serial_no)

  #cut into 6 octets starting from the right side
  #a=${PI_SERIAL_NO:4:2}
  #b=${PI_SERIAL_NO:6:2}
  #c=${PI_SERIAL_NO:8:2}
  #d=${PI_SERIAL_NO:10:2}
  #e=${PI_SERIAL_NO:12:2}
  #f=${PI_SERIAL_NO:14:2}

	a=${PI_SERIAL_NO: -12:2}
	b=${PI_SERIAL_NO: -10:2}
	c=${PI_SERIAL_NO: -8:2}
	d=${PI_SERIAL_NO: -6:2}
	e=${PI_SERIAL_NO: -4:2}
	f=${PI_SERIAL_NO: -2:2}
  
  
  HB_USERNAME=$a:$b:$c:$d:$e:$f
  echo $HB_USERNAME
}


homebridge_name_set(){
	HOMEBRIDGE_OLDNAME=$(jq .bridge.name /var/lib/homebridge/config.json | cut -d\" -f2)
	PI_SERIAL_NO=$(hw_serial_no)
	HOMEBRIDGE_NAME=Homebridge-${PI_SERIAL_NO:12:4}
	
	#HOMEBRIDGE_NAME=Homebridge-${$(hw_serial_no):12:4}
	
	sudo sed -i -e "s/$HOMEBRIDGE_OLDNAME/$HOMEBRIDGE_NAME/" /var/lib/homebridge/config.json
}


homebridge_username_set(){
  OLD=$(homebridge_username_current)
  NEW=$(homebridge_username_target)	
  sudo sed -i -e 's/'$OLD'/'$NEW'/' /var/lib/homebridge/config.json
}


homebridge_pin_set(){
	OLD_PIN=$(jq .bridge.pin /var/lib/homebridge/config.json | cut -d\" -f2)
	sudo sed -i -e 's/'$OLD_PIN'/'"000-00-001"'/' /var/lib/homebridge/config.json
}


homebridge_rename(){
	if ! [[ $1 == "-y" ]]; then
		echo Rename homebridge to
		PI_SERIAL_NO=$(hw_serial_no)
		echo Name = Homebridge-${PI_SERIAL_NO:12:4}
		echo Usernaem = $(homebridge_username_target)	
		echo PIN = "000-00-001"
		read -n1 -p "Rename homebridge ?"  -r RESULT
		echo
	else
		RESULT="y"
	fi

	if [[ $RESULT == "y" ]]; then
	
		echo Set homebridge name ...
		homebridge_name_set
		jq .bridge.name /var/lib/homebridge/config.json | cut -d\" -f2

		echo Set homebridge username ...
		homebridge_username_set
		jq .bridge.username /var/lib/homebridge/config.json | cut -d\" -f2

		echo Set homebridge pin ...
		homebridge_pin_set
		jq .bridge.pin /var/lib/homebridge/config.json | cut -d\" -f2
		
		sudo hb-service restart
	
	fi
}




###################### End library #######################





homebridge_info(){
	echo_white homebridge-pi.sh by Richard Reed 2020
	#echo_white SYSTEM INFO:
	echo
	echo_white Status:
	echo "Homebridge Status       :$(systemctl status homebridge | grep Active | cut -d: -f2,3,4,5)"
	echo "Web console             : http://localhost:8581   user=admin   pw=admin"
	#echo "Web console             : "$(sudo ifconfig wlan0 | grep "inet "  | cut -d" " -f10)":8581   user=admin   pw=admin"
	echo

	echo_white_ne  "Hardware                : "
	if [ -f /proc/device-tree/model ]; then
		cat /proc/device-tree/model
	fi
	echo
	echo "Serial number           :" $(hw_serial_no)
	echo -ne "Processer               : "
	uname -m
	echo

	echo_white_ne "OS                      : "
	cat /etc/os-release | grep "PRETTY_NAME=" | cut -d '"' -f2
	echo "uptime                  : $(uptime -p)"
	echo "kernel (min v4.9)       : $(uname -r)"
	echo "hostname                : $(hostname)"
	echo "User                    : $(whoami)"
	echo "Locale                  : $(cat /etc/locale.gen | grep '^[^#;]')"
	echo "keyboard                : $(setxkbmap -query | grep layout)"
	echo "Timezone                : $(date +'%Z %z')"
  
	# check for internet access
	echo -n "Internet access         : " 
	wget -q --spider http://google.com
	if [[ $? -eq 0 ]]; then
		echo_green "[Online]"
	else
		echo_red "[Offline]"
	fi
	
	if ! [[ -z $(ip link | grep eth0) ]]; then
		echo " - LAN IP Addr          : $(ifconfig eth0 | grep "inet "  | cut -d" " -f10)"
	fi
	if ! [[ -z $(ip link | grep wlan0) ]]; then
		echo " - wifi IP Addr         : $(ifconfig wlan0 | grep "inet "  | cut -d" " -f10)"
	fi
	echo

	echo_white Prerequisites:
	echo    "nodejs ver (min 10)     : $(nodejs -v) "  
	echo -e "npm ver    (min 6)      : $(npm -v)  ${red}Latest=$(sudo npm view npm@latest version)${NC}"
	echo

	echo_white Homebridge:

	# find homebridge executable
	echo -n "Homebridge ver          : "
	if [[ -z $(which homebridge) ]]; then
		echo_red "[Not installed]"
	else
		echo "$(homebridge -V)  Latest=$(sudo npm view homebridge@latest version)"
	fi

	echo -n "Homebridge service      : "
	if [ -f /etc/systemd/system/homebridge.service ]; then
		echo_green "[OK]"
	else
		echo_red "[Not installed]"
	fi

  if [ -f /var/lib/homebridge/config.json ]; then
		echo "Homebridge Name          : $(jq .bridge.name /var/lib/homebridge/config.json) "
		echo "Homebridge Username      : $(jq .bridge.username /var/lib/homebridge/config.json) "
		#echo "Homebridge Username     : $(homebridge_username_current)"
		#echo "Homebridge PIN          : $(cat /var/lib/homebridge/config.json | grep pin | cut -d\: -f2) "
		echo "Homebridge PIN           : $(jq .bridge.pin /var/lib/homebridge/config.json) "

  else
    echo "Homebridge SN           : "
	echo "Homebridge PIN          : " 
  fi  
    
  
  echo 
  echo "Homebridge path              : $(which homebridge)"
  
  
  echo "Homebridge service           : /etc/systemd/system/homebridge.service"
  

  if [ -f /etc/systemd/system/homebridge.service ]; then
	ENV_FILE=$(cat /etc/systemd/system/homebridge.service | grep Environment | cut -d= -f2)
  else
	ENV_FILE=""
  fi
  echo "Homebridge env file          : $ENV_FILE"

  
  echo -ne "Homebridge storage path      : "
  if [ -f /etc/default/homebridge ]; then
    STORAGE_PATH=$(cat /etc/default/homebridge | grep HOMEBRIDGE_OPTS | cut -d' ' -f2)
  else
    STORAGE_PATH=""
  fi  
  echo $STORAGE_PATH

  
  echo -ne "Homebridge config file       : "
  echo $STORAGE_PATH/config.json
  
  check_config_json -v
  
  
  echo 
  echo_white Homebridge plug-ins installed ...
  # npm list -g | grep homebridge
  # npm  -g ls --depth=0  | grep homebridge | cut -d " " -f 2
  ls -1 `sudo npm root -g` | grep -


  echo
  echo_white Homebridge plug-ins configured in config.json  ...
  #cat /var/lib/homebridge/config.json | grep 'accessory\|name'
  #cat /var/lib/homebridge/config.json | jq '.platforms[].cameras[].name'
  if [ -f /var/lib/homebridge/config.json ]; then
	  echo Platforms:
	  cat /var/lib/homebridge/config.json | jq '.platforms[].platform'
	  echo Accessories:
	  cat /var/lib/homebridge/config.json | jq '.accessories[].accessory'
	  echo Accessory Names:
	  cat /var/lib/homebridge/config.json | jq '.accessories[].name'
  fi
  

	echo
	echo_white References
	echo "Homebridge              : https://github.com/nfarina/homebridge"
	echo "Homebrigdge on pi       : https://github.com/nfarina/homebridge/wiki/Running-HomeBridge-on-a-Raspberry-Pi"
	echo "Accessories             : https://www.npmjs.com/search?q=homebridge-plugin"
}



system_check() {
ERR_COUNT=0
echo_white Checking system ...


# Pi 3 or 4?
#echo -n Checking hardware ... $(pi_model -s)
#case $(pi_model -s) in
#  3B|3B+|4B)   echo_green " [OK]" ;;
#          *)   echo_red Unknown
#               let "ERR_COUNT++"
#               ;;
#esac


# Stretch or Buster?
echo -n Checking Operating system ... $(os_version -s)
case $(os_version -s) in
  cindy | jessy | stretch | buster)  echo_green " [OK]"   ;;
  *)    echo_red Unknown
        let "ERR_COUNT++"
        ;;
esac


# is user pi?
echo -n Checking user ... $(whoami)
if  [[ $(whoami) == "pi"  ]] ; then
  echo_green " [OK]"
else
  echo_red ERROR.  Recommend logging in a pi.
  let "ERR_COUNT++"
fi


# is internet working?
echo -n Testing for internet ...
wget -q --spider http://google.com
if [[ $? -eq 0 ]]; then
    echo_green "[Online..OK]"
else
    echo_red "[Offline]"
    let "ERR_COUNT++"
fi


# is hostname set?
#echo Checking pi name \(hostname\) in /etc/hosts and /etc/hostname ...
#pi_name_set                # in /etc/hosts and /etc/hostname


# is homebridge already installed
echo "Checking to see if Homebridge is already installed"
if [[ -z $(which homebridge) ]]; then
  echo_green [OK]
else
  echo_red Homebridge already installed
  homebridge -V
  let "ERR_COUNT++"
fi


# pause if there were any errors
if ! [[ $ERR_COUNT == "0" ]]; then
  echo_red ERRORS: Press any key to continue or Ctrl-C to abort
  read -n1
else
  echo_green OK
fi
}




upgrade_homebridge()  {
	echo_white Not working now...
	return	

	echo_white Stopping homebridge ...
	#sudo systemctl stop homebridge
	hb-service stop
	check_exit_code $?

	echo_white Update NODE
	
	
	echo_white Update NPM
	
	
	echo_white Upgrading homebridge ...
	homebridge_install
	check_exit_code $?

	#echo_white Updating homebridge ...
	#sudo npm update homebridge
	#check_exit_code $?

	echo_white Updating config-ui ...
	sudo npm update homebridge-config-ui-x
	check_exit_code $?

	echo_white reload service ...
	sudo systemctl daemon-reload
	check_exit_code $?

	echo_white Starting homebridge...
	sudo systemctl start homebridge
	check_exit_code $?

	echo_white	Done updating.
}



update_wiringpi(){
	echo_white "Upgrading wiring pi if needed ..."
	if [[ $(pi_model -s) == "4B" ]] && [[ $(wiringpi_ver) < 2.52 ]]; then
		echo Pi model: $(pi_model -s)
		echo Wiringpi ver: $(wiringpi_ver)
		echo_red WARNING ...
		echo Raspberry Pi model \'$(pi_model -s)\' needs wiringpi 2.52 or better

		if ! [[ $1 == '-y' ]]; then
			read -p "Upgrade wiring pi to 2.52 or later?"  -n1 -r RESULT
		else
			RESULT="y"
		fi	   

		if [[ $RESULT == "y" ]]; then
			echo
			echo_white Getting updated wiring pi from drogon.net ...
			wget https://project-downloads.drogon.net/wiringpi-latest.deb
			check_exit_code $?
			echo_white Installing wiring pi ...
			sudo dpkg -i wiringpi-latest.deb
			check_exit_code $?
			gpio -v | grep version
		fi
	else
		echo wipi is ver : $(wiringpi_ver)...
		echo_green "OK"
	fi
}





#########################################################################
install_prerequisites(){
	export ERROR_COUNT=0

	echo_white Installing standard prerequisites ...

	#update system
	if ! [[ $1 == "-y" ]]; then
		read -n1 -p "Upgrade all software packages ?"  -r RESULT
		echo
	else
		RESULT="y"
	fi
	if [ $RESULT == "y" ]; then
		echo_white "Updating all software packages ..."
		sudo apt update
		check_exit_code $?
		sudo apt upgrade -y
		check_exit_code $?
	fi	


	# for OSMC or other stripped down Raspberry OS...  (not needed for Stretch or Buster)
	echo_white "Install g++, gcc, git, python, and make ..."
	sudo apt install -y git gcc g++ python make
	check_exit_code $?


	#optional install build tools                    (not needed for Stretch or Buster)
	echo_white "Install build-essential ..."
	sudo apt install -y build-essential
	check_exit_code $?
  
  
	if [[ $(uname -m) == "armv7l" ]]; then
		echo_white "Installing wiring pi ..."
		sudo apt install wiringpi -y
		check_exit_code $? 

		update_wiringpi $1
		check_exit_code $?
	fi
  
  
	echo_white  "Install jq (json query) ..."
	sudo apt install jq -y
	check_exit_code $?


	echo_white "Installing avahi (bonjour) ..."
	sudo apt install -y libavahi-compat-libdnssd-dev
	check_exit_code $?

	
	if ! [ -z $(which nodejs) ]; then
		NODEJS_VER=$(nodejs -v | cut -dv -f2 | cut -d. -f1)
	else	
		NODEJS_VER=0
	fi	
		

	echo Distro nodejs ver:
	NODEJS_DISTRO=$(sudo apt show nodejs | grep Version | cut -d' ' -f2 | cut -d. -f1)


	echo_white Nodejs versions:
	echo Installed  Nodejs Ver is $NODEJS_VER
	echo Distro     Nodejs Ver is $NODEJS_DISTRO
	echo Recomended Nodejs Ver is $NODEJS_REC

	sleep 5
	
	
	if [ $NODEJS_REC -gt $NODEJS_VER ] && [ $NODEJS_REC -gt $NODEJS_DISTRO ]; then 
		echo_white "Getting node $NODEJS_REC from nodesource.com ... "
		curl -sL https://deb.nodesource.com/setup_$NODEJS_REC.x | sudo -E bash -
		check_exit_code $?
	fi
	
	
	echo_white "Installing nodejs ... "
	sudo apt install nodejs -y
	check_exit_code $?
	echo nodejs ver: $(node -v)
	
	
	if [ -z $(npm -v) ] ; then
		echo_white "Installing npm (node package manager) ..."
		sudo apt install npm -y
		check_exit_code $?
	fi
	echo npm ver: $(npm -v)
	
	
	echo_white Updating npm ...
	sudo npm install -g npm
	check_exit_code $?
	echo nodejs ver: $(node -v)
	echo npm ver: $(npm -v)
  

	echo_white "Cleanup ..."
	sudo apt autoremove -y
	check_exit_code $?

	
	if [[ $ERROR_COUNT == 0 ]] ; then
		echo_green No errors detected installing Prerequisites
	else
		echo_white_on_red Error count: $ERROR_COUNT installing Prerequisites
	fi
	echo 
}



install_homebridge(){
	echo_white "Installing Homebridge (homekit server) ..."
	sudo npm install -g homebridge
	EXIT_CODE=$?
	if ! [[ $EXIT_CODE == 0 ]]; then 
		echo ERROR $EXIT_CODE. Retrying with --unsafe-perm
		sudo npm install -g homebridge --unsafe-perm
		check_exit_code $?
	fi  


	sudo mkdir /var/lib/homebridge
	sudo chmod 777 /var/lib/homebridge
	
	echo Putting shortcut to /var/lib/homebridge on desktop ...	
	# https://raspberrypi.stackexchange.com/questions/100679/auto-execute-desktop-shortcut-problem
#find file manager

    echo "[Desktop Entry]
Version=1.0
Name=Homebridge Folder
Comment=Homebridge Folder
Icon=/usr/share/icons/gnome/32x32/places/folder.png
Exec=xdg-open /var/lib/homebridge
Encoding=UTF-8
Terminal=false
Type=Application
Categories=None;" >> "/home/$SERVICE_ACCOUNT/Desktop/HomebridgeFolder.desktop"
  
	
	
	
	echo_white "Installing homebridge-config-ui-x (browser interface)..."
    sudo npm install -g --unsafe-perm homebridge-config-ui-x -y
	EXIT_CODE=$?

	#make_homebridge_ui_x_shortcut
	#EXIT_CODE=$?
	
	#make_homebridge_ui_x_shortcut() {
	#get an icon file
	sudo curl -s https://wiesmann.codiferes.net/wordpress/wp-content/uploads/homekit_icon.png --output /usr/share/pixmaps/homekit_icon.png
	#sudo curl -s https://user-images.githubusercontent.com/19808920/58770949-bd9c7900-857f-11e9-8558-5dfaffddffda.png  --output /usr/share/pixmaps/homekit_icon.png

	echo "[Desktop Entry]
Version=1.0
Name=Homebridge
Comment=Homebridge
Icon=/usr/share/pixmaps/homekit_icon.png
Exec=xdg-open http://localhost:8581
Encoding=UTF-8
Terminal=false
Type=Application
Categories=None;" >> "/var/lib/homebridge/Homebridge.desktop"

	sudo chmod +x "/var/lib/homebridge/Homebridge.desktop"
  
	# create a link to homebridge web interface on the desktop
	ln -sf /var/lib/homebridge/Homebridge.desktop /home/$SERVICE_ACCOUNT/Desktop
#}	
	
	
	# this creates the auto start service
	echo_white Installing homebridge service
	sudo hb-service install --user pi
	EXIT_CODE=$?
}



backup(){
	echo "Creating backup in $BACKUP_FOLDER"
	TIMESTAMP=$(date +%Y-%m-%d_%H:%M:%S)
	if [[ -z $(which zip) ]]; then
		sudo apt-get install zip -y
	fi
	mkdir $BACKUP_FOLDER
	zip -r $BACKUP_FOLDER/$TIMESTAMP.zip /var/lib/homebridge  /etc/systemd/system/homebridge*  -x *.zip
}



uninstall() {
	echo_white Uninstalling homebridge service ...
	sudo hb-service uninstall
	check_exit_code $?
		
		
	echo_white Uninstalling homebridge-config-ui-x ...
	#sudo npm uninstall -g --unsafe-perm homebridge-config-ui-x -y
	sudo npm uninstall -g homebridge-config-ui-x -y
	check_exit_code $?
		
	
	echo_white Uninstalling homebridge ...
	sudo npm uninstall -g homebridge -y
	check_exit_code $?

	
	echo
	read -p "Remove ALL homebridge settings ,data and backup files [y/N] ?" -n 1 -r RESULT
	echo
	if [[ $RESULT == "y" ]]; then
	# cleanup old installation files
	if [[ -f /etc/systemd/system/homebridge.service ]]; then
			echo_white Removing homebridge.service file and defaults file ...
			sudo rm /etc/systemd/system/homebridge.service
			sudo systemctl daemon-reload
			sudo rm /etc/default/homebridge
		fi	

		echo_white Remove desktop shortcuts ...
		#rm /home/$SERVICE_ACCOUNT/Desktop/homebridge
		rm "/home/$SERVICE_ACCOUNT/Desktop/Homebridge.desktop"
		rm "/home/$SERVICE_ACCOUNT/Desktop/HomebridgeFolder.desktop"

		echo_white Removing /var/lib/homebridge folder ...
		sudo rm -r -d /var/lib/homebridge
	fi

	
	echo
	echo_white "Uninstall prerequisites (recommend no) ..."


	#echo
	read -p "Uninstall npm $(npm -v) [y/N] ?" -n 1 -r RESULT
	echo
	if [[ $RESULT == "y" ]]; then
		sudo npm uninstall -g npm
		check_exit_code $?
		
		if ! [ -z $(which npm) ]; then 
			echo_white removing npm with apt $(npm -v)
			sudo apt remove npm -y
			check_exit_code $?
		fi	
	fi

	
	#echo
	read -p "Uninstall nodejs $(nodejs -v) [y/N]?" -n 1 -r RESULT
	echo
	if [[ $RESULT == "y" ]]; then
		sudo apt remove nodejs -y
		check_exit_code $?
		if [ -f /etc/apt/sources.list.d/nodesource.list ]; then
			echo Renaming /etc/apt/sources.list.d/nodesource.list  to .bak
			sudo mv /etc/apt/sources.list.d/nodesource.list /etc/apt/sources.list.d/nodesource.list.bak
			sudo apt update
		fi	
	fi


	
	read -p "Uninstall avahi (bonjour) [y/N]?" -n 1 -r RESULT
	echo
	if [[ $RESULT == "y" ]]; then
		sudo apt remove libavahi-compat-libdnssd-dev  -y
		check_exit_code $?
	fi


	#echo
	read -p "Uninstall build-essential[y/N]?" -n 1 -r RESULT
	echo
	if [[ $RESULT == "y" ]]; then
		sudo apt remove build-essential  -y
		check_exit_code $?
	fi
  

	#echo
	read -p "Uninstall git, gcc, g++ and make[y/N]?" -n 1 -r RESULT
	echo
	if [[ $RESULT == "y" ]]; then
		sudo apt remove git gcc g++ make  -y
		check_exit_code $?
	fi

	#echo
	read -p "Uninstall jq [y/N]?" -n 1 -r RESULT
	echo
	if [[ $RESULT == "y" ]]; then
		sudo apt remove jq -y
		check_exit_code $?
	fi

	#echo
	read -p "Uninstall wiringpi [y/N]?" -n 1 -r RESULT
	echo
	if [[ $RESULT == "y" ]]; then
		sudo apt remove wiringpi -y
		check_exit_code $?
	fi

	#echo
	echo_white Cleanup: apt autoremove ...
	sudo apt autoremove -y
	check_exit_code $?
}


install() {
	echo homebridge-pi.sh ver $SCRIPT_VER
	system_check
	
	install_prerequisites $1

	install_homebridge $1

	#if [ -z $hw_serial_no ]; then
	#	echo WARNING No serial number found
	#fi
	#read -n1 -p "configure homebridge to match pi serial number?" -r RESULT
	#if [[ $RESULT == "y" ]]; then
	#	homebridge_configure
	#fi

	echo_green Done installing Homebridge

	#echo Starting homebrige UI ...
	#xdg-open http://localhost:8581
	
	
	echo type 'hb-service -h' for info...
	echo --------------------------------------------------
	echo Start time= $T1
	echo End time  = $(date)
}



######################################################
# main run

INSTALL_PATH=$(dirname "$(realpath "$0")")
setup_colors


# setup some variables
INSTALL_MODE=ask
T1=$(date)


if [[ "$1" != "-v" ]]; then
	update_script
fi


#echo Usage: "bash homebridge-pi.sh [install|uninstall|update|start|stop|restart|logs|sysinfo|backup] [option]"
#echo Options:
#echo "  -y               auto answer yes to prompts"
#echo "  -nodejs[xx]      force version xx of nodejs on install"
#echo
#echo "  -v, --version      output script version"
#echo "  -h, --help         help"


case $1 in

	install)
		if ! [[ $2 == "-y" ]]; then
			read -p "Install Homebridge [y/N] ?" -n 1 -r RESULT
			echo
		else
			RESULT="y"
		fi	
		if [[ $RESULT == "y" ]]; then
			install $2
		fi
		;;
		
		
	uninstall)
		read -p "Uninstall Homebridge [y/N] ?" -n 1 -r RESULT
		echo
		if [[ $RESULT == "y" ]]; then
			uninstall $2
		fi
		;;

	rename)
		homebridge_rename $2
		;;
		
		
	upgdate)
		upgrade_homebridge
		;;	
		
		
	start)
		sudo hb-service start
		check_exit_code $?
		;;
		
		
	stop) 
		#sudo systemctl stop homebridge
		sudo hb-service stop
		check_exit_code $?
		;;
		
		
	restart) 
		#sudo systemctl restart homebridge
		sudo hb-service restart
		check_exit_code $?
		;;
				
		
	logs)
		#sudo sudo journalctl -e -f -a -u homebridge
		sudo hb-service logs
		;;
		
		
	sysinfo)
		homebridge_info
		;;

				
	backup)
		backup
		;;
		
	

	   
	-v | --version)
		echo $SCRIPT_VER
		;;

		
	-j)
		echo_white Contents of /var/lib/homebridge/homebridge.config.json
		cat /var/lib/homebridge/config.json
		echo
		check_config_json -v
		;;

		
	-nodejs*)
		NODE_TARGET=$(echo $1 | sed -e 's/-nodejs//')
		echo Installing homebridge with node $NODE_TARGET.  Press any key to continue
		read -n1
		echo Setting required node ver to $NODE_TARGET
		NODEJS_REC=$NODE_TARGET
		install
		;;
		
		
	
	-h | --help) 
		help 
		help2
		;;
	
	
	*)
		help
		;;
esac
