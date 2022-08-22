#!/bin/bash

function help()
{
	echo "Usage format-sdcard.sh /dev/<sdcard-dev>"
	echo "Format SD card for Alkali design"
}

FORMATING_SCHEME="$(cat << EOF
label: dos
label-id: 0x168f9a20
unit: sectors

name="boot", start=2048, size=1048576, type=c, bootable
name="root", start=1050624, size=30065664, type=83
EOF
)"

if [ "$#" -ne 1 ]; then
	help
	exit 1
fi

DEVICE=$1
if [ ! -b "$DEVICE" ]; then
	echo "Block device not available"
	exit 1
fi

echo -e "\033[0;33mAre you sure that you want to format ${DEVICE}, with the following way:\033[0m"
echo -e "quit\nNo\n" | sudo sfdisk --no-act "${DEVICE}"
echo

read -p $'\033[0;33mAre you sure? [Y]es/[N]o: \033[0m' -r
echo
if [[ $REPLY =~ ^[Yy](es)?$ ]]
then
	sudo umount ${DEVICE}?
	echo "${FORMATING_SCHEME}" | sudo sfdisk --wipe=always ${DEVICE}
	sudo mkfs.vfat ${DEVICE}1
	sudo mkfs.ext4 -F ${DEVICE}2
else
	echo -e "\033[0;33mQuiting without any changes\033[0m"
fi
