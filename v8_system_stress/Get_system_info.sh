#!/bin/bash
# Program:
# 		To get all pci device link speed and driver.
# Version:
#		1.0
# History:
# 		2021/10/29 Terry Hsu	First release


# bios
echo "------------------------ BIOS ------------------------"
dmidecode -t bios | grep "Vendor:" | sed 's/\t//g'
dmidecode -t bios | grep "Version:" | sed 's/\t//g'
dmidecode -t bios | grep "Release Date:" | sed 's/\t//g'
dmidecode -t bios | grep "ROM Size:" | sed 's/\t//g'
echo ""
# bmc
echo "------------------------ BMC -------------------------"
ipmitool mc info | grep "Firmware Revision"
ipmitool mc info | grep "IPMI Version"
echo ""
# OS
echo "------------------------ OS --------------------------"
[ -a "/etc/redhat-release" ] && cat /etc/redhat-release
[ -a "/etc/lsb-release" ] && cat /etc/lsb-release
[ -a "/etc/os-release" ] && cat /etc/os-release
echo ""
# kernel
echo "------------------------ Kernel ----------------------"
uname -r 
echo ""
# driver
echo "------------------------ Modules ---------------------"
for i in $(lspci -k | grep "Kernel driver in use" | sort | uniq | cut -d ":" -f 2)
do
	echo "Driver: $i $(modinfo $i 2> /dev/null | grep version | grep -v 'rhel\|src\|magic' | sed 's/       //g' | grep -v ERROR)" 
done
echo ""

#NIC
echo "------------------------ NIC -------------------------"
for j in $(ls -l /sys/class/net/ | grep -v 'bonding\|virtual\|total\|usb' | rev | cut -d "/" -f 1 | rev)
do
	lspci -s $(ethtool -i $j | awk '/bus-info/{print$2}')
	ethtool -i $j | grep 'firmware'
	echo ""
done



