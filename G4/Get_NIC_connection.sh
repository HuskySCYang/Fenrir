#!/bin/bash

NIC=`ls /sys/class/net/ | grep -i -v "do*\|lo\|usb\|br*\|vir*\|bond"`
#echo $NIC
for x in $NIC
do
	#echo $x
	res1=$(ls -l /sys/class/net | grep $x | grep -i -c usb)
	res2=$(ls -l /sys/class/net | grep $x | grep -i -c docker)
    res3=$(ls -l /sys/class/net | grep $x | grep -i -c virtual)
	#echo $res1:$res2
	if [ "$res1" == 0 ] && [ "$res2" == 0 ] && [ "$res3" == 0 ]; then
		#echo $x
        
		target=$(ls -l /sys/class/net/ | grep -w $x | rev | cut -d "/" -f 3 | rev ) 
        echo
        echo $target
        echo
        lspci -s $target
        #echo debug1
        #echo $target
        #echo debug2
        lspci -s $target -vvv | grep -i width | sed 's/^[ \t]*//g'
        echo
        
	#else
		#lspci -s $(ls -l /sys/class/net/ | grep $x | awk -F "usb" '{print $1}' | awk -F "/" '{print $5}'| cut -c 6-12)
	
	ethtool $x | grep "Speed\|Duplex\|Link detected"
	fi
	#echo "------------------------------------------------------------"
	echo


done


