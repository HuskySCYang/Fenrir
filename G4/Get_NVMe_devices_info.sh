#!/bin/bash
unset NVMe
for NVMe in $(lsblk | grep disk | awk '/nvme/{print$1}' | sort)
do
	
	echo "__________"$NVMe"__________"
	sudo smartctl -i /dev/$NVMe | grep "Model\|Serial\|Capacity\|Firmware"
done


