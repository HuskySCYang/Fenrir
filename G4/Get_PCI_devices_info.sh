#!/bin/bash
# Program:
# 		To get all pci device link speed and driver.
# Version:
#		1.1
# History:
# 		2017/05/03 Terry Hsu	First release
#		2021/10/22 Terry Hsu	Modify script



## To get all pci bridge bus. 
BUS1=`lspci | grep -i 'pci bridge' | awk '{print$1}' | rev | awk -F "" '{print $1$2$3$4$5$6$7}' | rev`  
#echo BUS1: $BUS1
## To get all pci device bus which connect to pci bridge.
for k in $BUS1
do
	BUS2=`ls -l /sys/bus/pci/devices/ | grep "0000:$k" | rev | cut -d "/" -f 1 | rev | grep -v "0000:$k"`
	#BUS2=`ls -l /sys/bus/pci/devices/ | grep "$k" | rev | cut -d "/" -f 1 | rev | grep -v "$k"`
	#echo BUS2: $BUS2
	if [ "$BUS2" != "" ];then
		for l in $BUS2
		do
			#echo $l
			echo $l >> /tmp/$$.pci_dev 

		done
	fi
done
echo
echo "======================================================================================"

## Use the pci device bus to get the pci device link speed 
BUS3=`cat /tmp/$$.pci_dev   | sort | uniq`
for j in $BUS3
do
echo
	lspci -s $j
	lspci -s $j -vvv | grep 'Physical Slot:'| sed 's/^[ \t]*//g'
	lspci -s $j -vvv | gawk '/LnkCap:/ {print$1,$4,$5,$6,$7}'
	echo "$(lspci -s $j -vvv | gawk '/LnkSta:/ {print$1,$2,$3,$4,$5,$6,$7}')"
	lspci -s $j -vvv | grep 'DevSta'| sed 's/^[ \t]*//g' | cut -d " " -f 1-3 | grep -v "+"
	lspci -s $j -vvv | grep 'DevSta'| sed 's/^[ \t]*//g' | cut -d " " -f 1-3 | grep "CorrErr+\|NonFatalErr-\|FatalErr-"
	lspci -s $j -vvv | grep 'CESta'| sed 's/^[ \t]*//g' 
	lspci -s $j -vvv | grep 'Kernel'| sed 's/^[ \t]*//g'
	echo
echo "======================================================================================"
done
rm -f /tmp/$$.pci_dev 

