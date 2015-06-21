#!/bin/bash
#
# Download, verify and write Raspbian to some SD card
#
# Santiago Crespo 2014
# License: CC0 https://creativecommons.org/publicdomain/zero/1.0/
#

### [ CHECK ROOT ]
if [[ $EUID -ne 0 ]]; then
  echo "### We need root to dd the image to the SD card" 1>&2
  exit 1
fi

### [ CHECK UNZIP]
if ! unzip -h > /dev/null 2> /dev/null; then
  if aptitude -h > /dev/null 2> /dev/null; then
    aptitude install unzip -y
  else
    echo "### ERROR: please install unzip"
    exit 1
  fi
fi

### [ SD CARD DEVICE ]
fdisk -l | grep "Disk /dev"
echo "### SD card device name?"
read SD_CARD

### [ UMOUNT SD CARD ]
mount  | grep $SD_CARD | awk '{print "umount "$1}' | sh

###  [ DOWNLOAD RASPBIAN ]
mkdir -p /tmp/rpi
cd /tmp/rpi
echo "### HTTP download may be **very** slow. Torrent is much, much faster."
echo "### Download via torrent? [Y/n]"
read TORRENT
if [[ $TORRENT =~ ^[Nn]$ ]]; then
  wget "https://downloads.raspberrypi.org/raspbian_latest" -O raspbian.zip
else
  chmod o+rwX /tmp/rpi
  echo "### Please open this file with your torrent client http://downloads.raspberrypi.org/raspbian_latest.torrent and save the zip file on /tmp/rpi/"
  read -p "Press [ENTER] after the finishing the download."
  mv /tmp/rpi/20*zip /tmp/rpi/raspbian.zip
fi

###  [ UNZIP AND CHECK ]
echo "### Please wait, calculating checksum..."
DOWNLOADSHA1=`sha1sum /tmp/rpi/raspbian.zip  | awk '{print $1}'`
WEBSHA1=`curl 2> /dev/null "https://www.raspberrypi.org/downloads/"  | grep raspbian_latest -A5 | grep SHA  | awk -F '>' '{print $5}'  | awk -F '<' '{print $1}'`
# also, now they banned robots :( http://downloads.raspberrypi.org/robots.txt
#echo '### Go to http://www.raspberrypi.org/downloads/ , search "Raspbian" and click on "More info +"'
#echo "### Copy and paste here the SHA1, the press [Enter] (remove the spaces)"
#read WEBSHA1

if [ "$DOWNLOADSHA1" == "$WEBSHA1" ]; then
  echo "### Checksum OK: $WEBSHA1"
  unzip raspbian.zip
else
  echo "### ERROR: Checksum wrong! web SHA1: $WEBSHA1 and downloaded file SHA1: $DOWNLOADSHA1"
  exit 1
fi

###  [ WRITE IMAGE TO SD ]
echo "### Please wait, writing image to the SD card..."
IMAGE=`ls -1 20*.img`
dd bs=1M if=$IMAGE of=$SD_CARD
if [ $? -ne 0 ]
then
  echo "### Write image failed :("
  exit 1
else
  echo "### Done! :)"
fi

###  [ EJECT SD ]
eject $SD_CARD 2> /dev/null > /dev/null
echo "### All ok, now you may remove the SD card and continue with phase 1: first boot."

exit 0
