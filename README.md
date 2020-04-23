# homebridge-pi
Automated installation of Homebridge on a raspberry pi  (2020)

Homebridge is very cool. But I struggled to get it installed and working on a Raspberry Pi. I tried so many different combinations from bits of information I found, that I finally coded it all into an installation script:  install.homebridge-pi.sh

It installs on any raspberry pi (probably) running Raspbian Buster or Raspbian Stretch including the lite versions. I used a 3b+ and a 4 with the standard raspbian desktop for most of the development.

It installs the prerequisites, homebridge, homebridge service, config-ui, and sets all the config files so they work.


To run this, open a terminal and copy and paste in the next two lines

   curl -O https://raw.githubusercontent.com/RichardMidnight/homebridge-pi/master/test.sh
   
   bash test.sh
   
