# homebridge-pi
Automated installation of Homebridge on a raspberry pi  (2018,2019,2020)

Homebridge is VERY cool, but I struggled to get it installed and working on a Raspberry Pi since 2018. I tried so many different combinations from many bits of information, that I finally coded it all into an installation script:  homebridge-pi.sh.  This gets the basic system up and running quickly, then you can play with the plugins.  Many thanks to all the contributors who made this possible.

It installs on any raspberry pi (probably) running Raspbian Buster or Raspbian Stretch including the lite versions. I used a 3b+ and a 4 with the standard raspbian desktop for most of the development.  It also seems to work pretty well on Debian 9, Debian 10, LMDE, and Raspbian desktop, all on virtualbox.  It seems to be pretty compatible with std Debian systems.

It installs the prerequisites, homebridge, homebridge service, config-ui, and sets all the config files so they work.  It also puts a shortcut to the homebridge folder and a shortcut to the browser interface on the desktop.


To run this (on your new Raspbian or Raspberry-Pi-OS image), open a terminal and copy and paste in the next two lines

"   **curl -O https://raw.githubusercontent.com/RichardMidnight/homebridge-pi/master/homebridge-pi.sh**"
   
"   **bash homebridge-pi.sh install**"
   
   
You can also uninstall by typing

"   bash homebridge-pi.sh uninstall"
   
Type **bash homebridge-pi.sh -h**  for standard help.   
