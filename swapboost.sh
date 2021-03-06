#!/bin/bash
###########
# This is a bash version of Windows Vista's "ReadyBoost".  This doesn't have a
# limitation on the hardware, or a minimum size requirement either.  I wrote
# this kind of as a proof of concept that, yes, we could do this too.
# Someone remind me again why in the *hell* anyone would want to pay for Vista?
#
#
# 1. Inserta la memoria USB y espera a que se monte.
# 2. Ejecuta en terminal: ./swapboost.sh -n para crear una partición swap.
# 3. Puedes comprobar si la memoria se ha añadido al swap mediante el
# comando swapon –s.
# 4. Ejecuta en terminal ./swapboost.sh -d para desmontar la memoria USB.
#
###########

if [[ $EUID -ne "0" ]]
then
	echo
	echo "#############################################"
	echo "# You must be root / sudo to run SwapBoost! #"
	echo "#############################################"
	echo
exit 1
fi

device=$(mount | tail -n1 | awk '{ print $1 }')
mount=$(mount | tail -n1 | awk '{ print $3; }')
freespace=$(df | tail -n1 | awk '{ print $4; }')

function usage {
	echo "usage: $0 [OPTION] [DEVICE]"
	echo "Create (or destroy) additional swap space on removable USB media"
	echo
	echo "-n, --new			create a new swap file a USB device"
	echo
	echo "-d, --delete			delete a USB swap file"
	echo
	echo "-h, --help			display this help information"
	echo
	echo "Example:"
	echo " $0 -n"
	echo "	The above will create a swap file on the latest USB"
	echo " $0 -d"
	echo "	The above will delete a swap file on the latest USB"
	echo
	echo "Originally created by Christer Edwards <christer.edwards@ubuntu.com>"
	echo "Released into the public domain"
	echo
}

function destroy {
if [[ -f $mount/swap ]]
then
	swapoff $mount/swap
	sleep 5
	rm $mount/swap
	sleep 5
	umount $mount
	echo
	echo "swap file cleaned up. ($freespace) available for use."

	else

	echo
	echo "You don't seem to have a swap file created on that device"
	exit 1
fi
}

function create {
if [[ -f $mount/swap ]]
then
	echo
	echo "You already have swap created on that device."
	echo
	swapon $mount/swap
	exit 1
fi

read -p "Would you like to create additional swap space on $device? ($mount) (y/n) " CREATE
CREATE=$(echo $CREATE | tr 'A-Z' 'a-z')
if [[ $CREATE == 'y' ]] || [[ $CREATE == 'yes' ]]
then

read -p "Would you like to use the maximum available space? ($freespace) (y/n)" SPACE
	if [[ $SPACE == 'y' ]] || [[ $SPACE == 'yes' ]]
	then
	
	dd if=/dev/zero of=$mount/swap bs=1K count=$freespace
	sleep 5
	mkswap $mount/swap
	sleep 5
	swapon $mount/swap
	sleep 5

	echo
	echo "You now have $freespace additional space available as swap"

	else

	echo
	echo "Planned for upcoming release.  Currently only full size accepted"

	fi
	exit 1

else
	echo
	echo "Exiting SwapBoost"
	exit 1
fi
}

while getopts ":ndh" OPTS ; do
	case $OPTS in
		n)	create 	;;
		d)	destroy	;;
		\? | h)	usage	;;
	esac
done

