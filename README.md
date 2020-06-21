# homebridge-pi
Automated installation of Homebridge on a raspberry pi  (2018,2019,2020)

Homebridge is VERY cool, but I struggled to get it installed and working on a Raspberry Pi in 2018 when I was automating my garage doors. I tried so many different combinations from many bits of information that I finally coded it all into an installation script homebridge-pi.sh.  I updated it over the years and now with hb-serivce it is much simpler.  This gets the basic system up and running quickly, then you can get right to playing with the plugins.  Many thanks to all the contributors who made this possible.

It installs on any raspberry pi (probably) running Raspbian Buster or Raspbian Stretch including the lite versions. I used a 3b+ and a 4 with the standard raspbian desktop for most of the development.  It also seems to work pretty well on Debian 9, Debian 10, LMDE, and Raspbian desktop, all on virtualbox.  It seems to be pretty compatible with std Debian systems.

It installs the prerequisites, homebridge, homebridge service, config-ui, and sets all the config files so they work.  It also puts a shortcut to the homebridge folder and a shortcut to the browser interface on the desktop.


To run this (on your new Raspbian or Raspberry-Pi-OS image), open a terminal and copy and paste in the next two lines

   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;**curl -O https://raw.githubusercontent.com/RichardMidnight/homebridge-pi/master/homebridge-pi.sh**
   
   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;**bash homebridge-pi.sh**
   
   
You can install by typing

  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;**bash homebridge-pi.sh install**

You can uninstall by typing

   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;**bash homebridge-pi.sh uninstall**
   
Type **bash homebridge-pi.sh -h**  for standard help.   

 &nbsp;
 
 Here is a screen shot of it installed.

![Image](https://github.com/RichardMidnight/homebridge-pi/blob/master/screenshot.PNG?raw=true)
