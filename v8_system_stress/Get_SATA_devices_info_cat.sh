#!/bin/bash
#ScriptPath
#ScriptPath="/$(grep Exec /root/.config/autostart/UUT_loop_main.sh.desktop | cut -d "/" -f 2-4)"

unset i_sata
rm -f SATA_all.log
lsscsi | grep -v Virtual | grep "/dev/" | grep ATA |  awk -F "/" '{print "/"$2"/"$3}' | sort -n >  $ScriptPath/disk_info.log

for i_sata in $(cat $ScriptPath/disk_info.log)
#for i in $(cat SATA.log)
do
	i_count=1
	while true
	do
        	{
		echo "__________"$i_sata"__________"
		smartctl -i "$i_sata" | grep "Device Model\|Serial\|Capacity\|Firmware\|SATA\|Vendor\|Identifier"
        	} > SATA_tmp.log
	cat SATA_tmp.log | grep -i device > /dev/null
	if [ "$?" == 0 ]; then
		cat SATA_tmp.log >> $ScriptPath/SATA_all.log
		break

	else
		sleep 3
		let "i_count=$i_count+1"
		if [ "$i_count" == 4 ]; then
			echo "Get $i_sata HDD info fail..."
			break
		fi
	fi
	done
done 

#rm -f disk_info.log
