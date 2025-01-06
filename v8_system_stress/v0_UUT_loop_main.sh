



wait_time_into_OS=$(cat $ScriptPath/wait_time.log)
cat $ScriptPath/Loop.conf | grep DC_method | grep RTC > /dev/null
if [ "$?" == 0 ]; then
rtc_delay=$(cat $ScriptPath/rtc_delay.value)
fi
#date "+%Y-%m-%d %T"

if [ "$wait_time_into_OS" == "" ]; then
	wait_time_into_OS=0
fi
#sleep $wait_time_into_OS
#date "+%Y-%m-%d %T"
default_sleep=30
wait_time_all=$(echo $(($default_sleep + $wait_time_into_OS)))
#echo $wait_time_all

echo "Wait $wait_time_all for System ready." 

echo
	date
echo
wait_counter=1
#echo $wait_counter
while [ $wait_counter != $wait_time_all ]
do
echo -n -e "."
sleep 1
let "wait_counter=$wait_counter+1"

done

echo
	date
echo



function color_table(){
BLACK='\033[0;30m'
RED='\033[0;31m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'
}

pure(){
pureversion -a 2> /dev/null
if [ "$?" == 0 ]; then
purestorage=0
else
purestorage=1
fi
}


function CHECKRESULT(){ #check all test results and show it on the screen.
	FAILLIST=`find $pwd -iname '*_fail.log' | grep -v dmesg`
	## 判斷是否有fail的log
	for F in $FAILLIST
	do
		if [ -s "$F" ];then
			echo "$F" >> "$pwd"Fail_items_detail.log
		fi
	done

	feature(){
	SELLIST=`find $pwd -iname '*abnormal.log' `
	## 判斷是否有fail的log
	for E in $SELLIST
	do
		if [ -s "$E" ];then
			echo "$E" >> "$pwd"Fail_items_detail.log
		fi
	done
	}

	if [ -s "$pwd"Fail_items_detail.log ];then
		cat "$pwd"Fail_items_detail.log|sort|uniq > "$pwd"Fail_items_simple.log

		cat "$pwd"Fail_items_simple.log ;cat $ScriptPath/FAIL
	else
		cat $ScriptPath/PASS

	fi
	
	#echo debug
			
	OFFMETHOD

}

counter_dealy(){
i_counter=1
while [ $i_counter != $1 ]
do
echo -n -e "."
sleep 1
let "i_counter=$i_counter+1"
done
echo
}

function OFFMETHOD(){
	pure
	if [ "$FinishTest" == "Yes" ];then
		rm -f /etc/profile.d/run_stress_loop_script.sh 
		
		#echo "Stress Completed"
		read -p "Stress Completed"
		echo	
		exit 0
				
		
		
	fi
	if [ "$Testmethod" == "Reboot" ];then
		cat $ScriptPath/reboot.method | grep 1 > /dev/null
		if [ "$?" == 0 ] && [ "$purestorage" == 1 ]; then		
			shutdown -r +1 
		else
			
			counter_dealy 60
			
			pureboot reboot --offline
			
		fi
		
	fi
	if [ "$Testmethod" == "DC" ];then
		DC=$(cat $ScriptPath/Loop.conf | grep -i "Test_method" | grep "DC" -c)
		cycle_BMC=$(cat $ScriptPath/Loop.conf | grep -i "DC_method" | grep "BMC" -c)
		cycle_RTC=$(cat $ScriptPath/Loop.conf | grep -i "DC_method" | grep "RTC" -c)
		if [ "$DC" == 1 ] && [ "$cycle_BMC" == 1 ]; then
			
			echo "Wait for remote client control"

		fi
		if [ "$DC" == 1 ] && [ "$cycle_RTC" == 1 ]; then
			#counter_dealy 60
			echo > /dev/null
			
			if [ "$purestorage" == 0 ]; then
				counter_delay 60
				pureboot poweroff --offline
			else
				cat $ScriptPath/dcboot.method | grep 1 > /dev/null
				if [ "$?" == 0 ]; then	
					shutdown -h +1
				else
					counter_delay 60
					ipmitool chassis power off 
				fi
			fi
			
		fi
	fi
	if [ "$Testmethod" == "AC" ];then
	
		AC_method=$(cat $ScriptPath/AC.method)
		DC_method=$(cat $ScriptPath/adcboot.method)
		#echo $AC_method
		#echo $DC_method
		#echo $purestorage
		echo
		if [ "$purestorage" == 1 ];  then
			if [ "$AC_method" == 1 ] && [ "$DC_method" == 1 ]; then
				echo "System will shutdown within 1 minutes."
				echo
				shutdown -h +1 
			fi
			if [ "$AC_method" == 1 ] && [ "$DC_method" == 2 ]; then
				echo "System will shutdown within 1 minutes."
				echo
				counter_dealy 60
				ipmitool chassis power off
			fi
			if [ "$AC_method" == 2 ]; then
				echo "Wait force AC"
			fi
		else
			if [ "$AC_method" == 1 ] && [ "$DC_method" == 1 ]; then
				echo "System will shutdown within 1 minutes."
				echo
				counter_dealy 60
				pureboot poweroff --offline 
			fi
			if [ "$AC_method" == 1 ] && [ "$DC_method" == 2 ]; then
				echo "System will shutdown within 1 minutes."
				echo
				counter_dealy 60
				ipmitool chassis power off
			fi
			if [ "$AC_method" == 2 ]; then
				echo "Wait force AC"
			fi
		fi
	fi
	
echo
echo
echo
		
}


function Record_disk(){
	## Record the information of drives.
	$ScriptPath/Get_SATA_devices_info_cat.sh
	$ScriptPath/Get_SATA_devices_info.sh > "$pwd"disk/SATA_drives_info_"$boot".log
	$ScriptPath/Get_NVMe_devices_info.sh > "$pwd"disk/NVMe_drives_info_"$boot".log
	## SYS block devices detection
	ls -l /sys/block/ | grep root |  cut -d ">" -f 2 > "$pwd"disk/SYS_block_info_"$boot".log
	if [ "$boot" != "1" ];then
        	cat "$pwd"disk/SATA_drives_info_"$boot".log | sed '/dev/d' |awk NF | sort > "$pwd"disk/SATA_drives_info_"$boot"_sort.log
		cat "$pwd"disk/NVMe_drives_info_"$boot".log | awk NF | sort  > "$pwd"disk/NVMe_drives_info_"$boot"_sort.log

		diff -c "$pwd"disk/SATA_drives_info_Golden_Sample_sort.log "$pwd"disk/SATA_drives_info_"$boot"_sort.log >> "$pwd"SATA_drives_fail.log
		diff -c "$pwd"disk/NVMe_drives_info_Golden_Sample_sort.log "$pwd"disk/NVMe_drives_info_"$boot"_sort.log >> "$pwd"NVMe_drives_fail.log
	fi
}




function Record_PCI(){
	## Record all of pci devices.(include the NVMe drives.)
	lspci > "$pwd"pci/lspci_"$boot".log
	lspci -vvv > "$pwd"pci/lspci-vvv_"$boot".log
	## Record the link speed of pci devices.
	$ScriptPath/Get_PCI_devices_info.sh > "$pwd"pci_link/PCI_Link_"$boot".log
	$ScriptPath/Get_PCI_debug_info.sh > "$pwd"pci_debug/PCI_debug_"$boot".log
	## Record the pci devices register
	lspci -xxxx > "$pwd"pci-x/pci-x."$boot".log
	## Record the pci errors(remark cycle doesn't check the Err+ and replace to check CESta)
	#for pcibus in $(lspci | awk '{print$1}')
	#do
	#	C1=`lspci -s $pcibus -vvv | grep DevSta | grep 'Err+'`
	#	if [ "$C1" != "" ];then
	#		lspci -s $pcibus >> "$pwd"pci/pci-err."$boot".log
	#		echo $C1 >> "$pwd"pci/pci-err."$boot".log
	#	fi	
	#done
	##
	if [ "$boot" != "1" ];then
		diff -c "$pwd"pci/lspci_Golden_Sample.log "$pwd"pci/lspci_"$boot".log >> "$pwd"PCIe_devices_fail.log
		diff -c "$pwd"pci_link/PCI_Link_Golden_Sample.log "$pwd"pci_link/PCI_Link_"$boot".log >> "$pwd"PCIe_link_fail.log
		diff -c "$pwd"pci_debug/PCI_debug_Golden_Sample.log "$pwd"pci_debug/PCI_debug_"$boot".log >> "$pwd"PCIe_debug_fail.log

	fi
	#(remark cycle doesn't check the Err+ and replace to check CESta)
	#if [ "$(cat "$pwd"pci/pci-err."$boot".log)" != "" ];then
	#	echo "No. $boot cycle has pcie errors." >> "$pwd"PCIe_errors_fail.log
	#fi
}

function Record_NIC(){
	## Record the link speed of network.
	$ScriptPath/Get_NIC_connection.sh > "$pwd"net_link/NIC_link_$boot.log
	if [ "$boot" != "1" ];then
		cat  "$pwd"net_link/NIC_link_$boot.log | awk NF |sort > "$pwd"net_link/NIC_link_"$boot"_sort.log 
		diff -c "$pwd"net_link/NIC_link_Golden_Sample_sort.log "$pwd"net_link/NIC_link_"$boot"_sort.log >> "$pwd"NIC_link_fail.log
	fi
}

function Record_megaraid(){
	## record LSI Hardware Riad drive link speed and information
	if [ "$(lspci -k | grep -i megaraid_sas)" != "" ];then
		$ScriptPath/Get_megaraid_devices_info.sh > "$pwd"disk/MegaRaid_drives_info_"$boot".log
		sleep 2
		if [ "$boot" != "1" ];then
			diff -c "$pwd"disk/MegaRaid_drives_info_Golden_Sample.log "$pwd"disk/MegaRaid_drives_info_"$boot".log >> "$pwd"MegaRaid_drives_fail.log
		fi
	fi
}




function Record_mptsas(){
	## record LSI 3008 link speed & drive information
	if [ "$(lspci -k | grep -i mpt)" != "" ];then
		$ScriptPath/Get_mptsas_devices_info.sh > "$pwd"LSI/mptSAS_drives_info_"$boot".log
		sleep 3
		cat "$pwd"LSI/mptSAS_drives_info_"$boot".log | awk NF |sort > "$pwd"LSI/mptSAS_drives_info_"$boot"_sort.log
		sleep 3
		$ScriptPath/Get_LSI_link.sh > "$pwd"LSI/LSI_link_"$boot".log
		sleep 2
		if [ "$boot" != "1" ];then
			diff -c "$pwd"LSI/LSI_link_Golden_Sample.log "$pwd"LSI/LSI_link_"$boot".log >> "$pwd"LSI_link_fail.log
			diff -c "$pwd"LSI/mptSAS_drives_info_Golden_Sample_sort.log "$pwd"LSI/mptSAS_drives_info_"$boot"_sort.log >> "$pwd"mptSAS_drives_fail.log
		fi
	fi
}

function Record_USB(){
	## Record all of usb devices.
	$ScriptPath/Get_USB_devices_info.sh > "$pwd"usb/USB_info_"$boot".log
	if [ "$boot" != "1" ];then
		diff -c "$pwd"usb/USB_info_Golden_Sample.log "$pwd"usb/USB_info_"$boot".log >> "$pwd"USB_info_fail.log
	fi
	
}


function Record_FW_info(){
	## Record all of usb devices.
	$ScriptPath/Get_SUT_FW_info.sh > "$pwd"BMC/FW/FW_info_"$boot".log
	if [ "$boot" != "1" ];then
		diff -c "$pwd"BMC/FW/FW_info_Golden_Sample.log "$pwd"BMC/FW/FW_info_"$boot".log >> "$pwd"FW_info_fail.log
	fi
}



function Record_BMC(){
	## BMC FRU
	ipmitool fru print 2>&1 | tee "$pwd"BMC/fru/fru_$boot.log
	## BMC firmware info
	#if [ ! -s "$pwd"BMC/fru/fru_$boot.log ]; then
	#	echo "Done"
	#	exit
	#fi
	ipmitool mc info 2>&1 | tee "$pwd"BMC/mc/mc_info_$boot.log
	#if [ ! -s "$pwd"BMC/mc/mc_info_$boot.log ]; then
	#	echo "Done"
	#	exit
	#fi
	## BMC SDR
	#cat "$pwd"BMC/sdr/sdr_Golden_Sample.log | awk -F "|" '{print $1 $3}' > "$pwd"BMC/sdr/sdr_Golden_tmp.log
	
	i_sdr=1
	while true
	do
		ipmitool sdr list all 2>&1 | tee "$pwd"BMC/sdr/sdr_list_all_$boot.log
		ipmitool sdr elist > "$pwd"BMC/sdr/sdr_$boot.log
		cat "$pwd"BMC/sdr/sdr_$boot.log	| awk -F "|" '{print $1 $3}' > "$pwd"BMC/sdr/sdr_tmp.log
		diff "$pwd"BMC/sdr/sdr_Golden_tmp.log "$pwd"BMC/sdr/sdr_tmp.log > "$pwd"BMC/sdr/sdr_compare.log
		! test -s "$pwd"BMC/sdr/sdr_compare.log
		if [ "$?" == 0 ]; then
			break
		else
			sleep 5
			let "i_sdr=$i_sdr+1"
			if [ "$i_sdr" == 3 ]; then
			#cat "$pwd"BMC/BMC_sdr_tmp.log  >> "$pwd"BMC/BMC_sdr_fail.log	
			echo " =============== No. "$boot" Boot ================= " > "$pwd"BMC/BMC_sdr_tmp.log
				cat "$pwd"BMC/sdr/sdr_compare.log >> "$pwd"BMC/BMC_sdr_tmp.log
				cat "$pwd"BMC/BMC_sdr_tmp.log  >> "$pwd"BMC/BMC_sdr_fail.log
				 
				break
			fi
		fi
	done
rm -f "$pwd"BMC/BMC_sdr_tmp.log
rm -f "$pwd"BMC/sdr/sdr_compare.log	###################################################################################################
repeat_SDR(){
	echo " =============== No. "$boot" Boot ================= " > "$pwd"BMC/BMC_sdr_tmp.log
	i_line=1
	while read line
	do
		sensor_name=$(echo $line | awk -F "|" '{print $1}')
		senscat "$pwd"BMC/BMC_sdr_tmp.log  >> "$pwd"BMC/BMC_sdr_fail.logor_status=$(echo $line | awk -F "|" '{print $3}')
		golden_status=$(cat "$pwd"BMC/sdr/sdr_Golden_Sample.log | awk -F "|" '{print $3}' | head -$i_line | tail -1)
		golden_status=$(echo $golden_status | sed s/[[:space:]]//g )
		sensor_status=$(echo $sensor_status | sed s/[[:space:]]//g )
		let "i_line=$i_line + 1"
		if [ "$golden_status" != "$sensor_status" ]; then
			echo ""$sensor_name" status error" >> "$pwd"BMC/BMC_sdr_tmp.log
			cat "$pwd"BMC/sdr/sdr_$boot.log | grep "$sensor_name" >> "$pwd"BMC/BMC_sdr_tmp.log
		fi
	done < "$pwd"BMC/sdr/sdr_$boot.log

	cat "$pwd"BMC/BMC_sdr_tmp.log | grep "error" > /dev/null
	if [ "$?" == 0 ]; then
		sed -i '/error/d' "$pwd"BMC/BMC_sdr_tmp.log
		cat "$pwd"BMC/BMC_sdr_tmp.log  >> "$pwd"BMC/BMC_sdr_fail.log
		cat "$pwd"BMC/sdr/sdr_compare.log >> "$pwd"BMC/BMC_sdr_fail.log
		#cat "$pwd"BMC/BMC_sdr_fail.log >> "$pwd"BMC_sdr_fail.log
	fi
	rm -f "$pwd"BMC/BMC_sdr_tmp.log
}	###################################################################################################
	#makred Terry sdr check condition
	#_________________________________________________________________________________________________
	#if [ "$(ipmitool sdr elist | grep "nr" )" != "" ];then
	#	echo " =============== No. "$boot" Boot ================= " >> "$pwd"BMC/BMC_sdr_fail.log
	#	ipmitool sdr elist | grep "nr" >> "$pwd"BMC/BMC_sdr_fail.log
	#fi
	#_________________________________________________________________________________________________
	## record BMC event 
	ipmitool sel elist > "$pwd"BMC/event/BMC_event_$boot.log
	cat "$pwd"BMC/event/BMC_event_$boot.log | awk -F " " '{print $1}' > "$pwd"BMC/event/sel_number.log
	###################################################################################################
	cat "$pwd"BMC/event/BMC_event_$boot.log > "$pwd"BMC/event/Deatil_BMC_event_$boot.log
	echo "" >> "$pwd"BMC/event/Deatil_BMC_event_$boot.log
	echo "=============== Detail event analysis ===============" >> "$pwd"BMC/event/Deatil_BMC_event_$boot.log
	echo "" >> "$pwd"BMC/event/Deatil_BMC_event_$boot.log
	#ipmitool sel elist 2>&1 | tee sel_temp_1.log
	echo
	while read line
	do
	ipmitool sel get 0x$line  >> "$pwd"BMC/event/Deatil_BMC_event_$boot.log
	done < "$pwd"BMC/event/sel_number.log
	rm -f "$pwd"BMC/event/sel_number.log
	###################################################################################################
	ipmitool sel save "$pwd"BMC/raw/BMC_event_raw_$boot.log
	ipmiutil sel -r | awk 'NR>5 {print$8,$9,$10,$11,$12,$13,$14,$15,$16}' > "$pwd"BMC/full_raw/BMC_full_raw_$boot.log
	if [ "$boot" != "1" ];then
		diff -c "$pwd"BMC/fru/fru_Golden_Sample.log "$pwd"BMC/fru/fru_$boot.log >> "$pwd"BMC/fru_fail.log
		diff -c "$pwd"BMC/mc/mc_Golden_Sample.log "$pwd"BMC/mc/mc_info_$boot.log >> "$pwd"BMC/mc_fail.log
	fi
}

function Record_DMI(){
	## DMI check
	dmidecode -t 0 > "$pwd"DMI/BIOS_$boot.log
	dmidecode -t 1 | grep -v Wake > "$pwd"DMI/System_$boot.log
	dmidecode -t 2 > "$pwd"DMI/Baseboard_$boot.log
	dmidecode -t 3 > "$pwd"DMI/Chassis_$boot.log
	dmidecode -t 4 > "$pwd"DMI/CPU_$boot.log
	dmidecode -t 17 | grep -i -w "Siz:e\|Locator:\|Speed\|Manufacturer:\|Volatile Size"> "$pwd"DMI/MEM_$boot.log
	#dmidecode > "$pwd"DMI/DMI_$boot.log
	if [ "$boot" != "1" ];then
		diff -c "$pwd"DMI/BIOS_Golden_Sample.log "$pwd"DMI/BIOS_$boot.log >> "$pwd"BIOS_fail.log
		diff -c "$pwd"DMI/System_Golden_Sample.log "$pwd"DMI/System_$boot.log >> "$pwd"System_fail.log
		diff -c "$pwd"DMI/Baseboard_Golden_Sample.log "$pwd"DMI/Baseboard_$boot.log >> "$pwd"Baseboard_fail.log
		diff -c "$pwd"DMI/Chassis_Golden_Sample.log "$pwd"DMI/Chassis_$boot.log >> "$pwd"Chassis_fail.log
		diff -c "$pwd"DMI/CPU_Golden_Sample.log "$pwd"DMI/CPU_$boot.log >> "$pwd"CPU_fail.log
		diff -c "$pwd"DMI/MEM_Golden_Sample.log "$pwd"DMI/MEM_$boot.log >> "$pwd"MEM_fail.log
	fi
}

function system_event_log_analysis(){
if [ "$1" == "" ];then
	echo "Usage: ./dmesg_log_analysis.sh /root/Desktop/XX_test_logs "
	exit 0
fi
echo "-------------------------------------------------------------------------------------------------
Counter |                                 events 
-------------------------------------------------------------------------------------------------"
grep -v "OEM record" $1/BMC/event/BMC_event_*.log | cut -d "|" -f 4- | sort | uniq -c
grep "OEM record" $1/BMC/event/BMC_event_*.log | cut -d "|" -f 2- | sort | uniq -c
}

function dmesg_log_analysis(){
if [ "$1" == "" ];then
	echo "Usage: ./dmesg_log_analysis.sh /root/Desktop/XX_test_logs "
	exit 0
fi
echo "-------------------------------------------------------------------------------------------------
Counter |                                 Kernel Messages 
-------------------------------------------------------------------------------------------------"
grep -v "==\|CST" $1/dmesg_error_fail.log | sort | uniq -c
}

function Analysis_BMC_Dmesg(){
	## check BMC event
	echo " =============== No. "$boot" Boot ================= " > "$pwd"BMC/SEL_abnormal_tmp.log
	grep -i 'error\|timeout\|err\|fail\|going\|Upper\|Lower\|Critical\|ECC' "$pwd"BMC/event/BMC_event_$boot.log > /dev/null
	if [ "$?" == 0 ]; then	
	cat "$pwd"BMC/SEL_abnormal_tmp.log >> "$pwd"BMC/SEL_abnormal_fail.log
	grep -i 'error\|timeout\|err\|fail\|going\|upper\|lower\|Critical\|ECC' "$pwd"BMC/event/BMC_event_$boot.log >> "$pwd"BMC/SEL_abnormal_fail.log
	fi
	system_event_log_analysis "$pwd" > "$pwd"BMC/All_SEL_analysis.log
	rm -f "$pwd"BMC/SEL_abnormal_tmp.log
	## record error & fail dmesg
	
	
}

function Record_dmesg(){
	## backup the dmesg
	journalctl -k > "$pwd"dmesg/messages_$boot.log
	cat  "$pwd"dmesg/messages_$boot.log | grep "Hardware Error" > "$pwd"dmesg/dispaly_message_tmp.log
	if [ "$?" == 0 ]; then	
		echo  "=============== No. $boot Boot ===============" >> "$pwd"hardware_journalctl_error_fail.log
		cat "$pwd"dmesg/dispaly_message_tmp.log >> "$pwd"hardware_journalctl_error_fail.log
		echo  "==============================================" >> "$pwd"hardware_journalctl_error_fail.log
		echo  "" >> "$pwd"hardware_journalctl_error_fail.log
	fi
	dmesg > "$pwd"dmesg/dmesg_$boot.log
	cat  "$pwd"dmesg/dmesg_$boot.log | grep "Hardware Error" > "$pwd"dmesg/dispaly_dmesg_tmp.log
	if [ "$?" == 0 ]; then	
		echo  "=============== No. $boot Boot ===============" >> "$pwd"hardware_dmesg_error_fail.log
		cat "$pwd"dmesg/dispaly_dmesg_tmp.log >> "$pwd"hardware_dmesg_error_fail.log
		echo  "==============================================" >> "$pwd"hardware_dmesg_error_fail.log
		echo  "" >> "$pwd"hardware_dmesg_error_fail.log
	fi
	#error_fail=`dmesg | grep -i 'error\|fail\|mcelog\|warning'`
	error_fail=`cat "$pwd"dmesg/dmesg_$boot.log | grep -i 'error\|fail\|mcelog\|warning'`	
	if [ "$error_fail" != "" ]; then
		echo -n "===== No. $boot Boot ===== " >> "$pwd"dmesg_error_fail.log 
		date +"%x %X" >> "$pwd"dmesg_error_fail.log
		dmesg | grep -i 'error\|fail' | cut -d ']' -f 2- >> "$pwd"dmesg_error_fail.log
		dmesg_log_analysis "$pwd" > "$pwd"All_dmesg_analysis.log
	else
		echo -n "===== No. $boot Boot ===== " >> "$pwd"dmesg_error_fail.log 
		date +"%x %X" >> "$pwd"dmesg_error_fail.log
	fi
}

function Record_mcelog(){
	## mcelog
	cat /etc/os-release > os_info.log
	cat os_info.log | grep -i ubuntu > /dev/null
	if [ "$?" == 0 ]; then
		dmesg | grep -i mcelog > "$pwd"dmesg_mcelog_fail_tmp.log
		mcelog=$(cat "$pwd"dmesg_mcelog_fail_tmp.log)
		if [ "$mcelog" != "" ]; then
			echo "===== No. $boot Boot =====" >> "$pwd"dmesg_mcelog_fail_tmp.log
			cat "$pwd"dmesg_mcelog_fail_tmp.log >> "$pwd"dmesg_mcelog_fail.log
		fi
		rm -f "$pwd"dmesg_mcelog_fail_tmp.log

		if [ -f /var/log/mcelog ]; then
		mcelog=$(cat /var/log/mcelog)
		if [ "$mcelog" != "" ]; then
			cat /var/log/mcelog  > "$pwd"mcelog_fail_tmp.log
			echo "===== No. $boot Boot =====" >> "$pwd"mcelog_fail_tmp.log
			cat "$pwd"mcelog_fail_tmp.log >> "$pwd"mcelog_fail.log
		else	
			/lib/systemd/systemd-sysv-install enable mcelog
			systemctl start mcelog.service
			systemctl daemon-reload
		fi
		rm -f "$pwd"mcelog_fail_tmp.log
		fi
	else
		if [ "$(grep "logfile" /usr/lib/systemd/system/mcelog.service)" != "" ];then
			[ -s /var/log/mcelog ] && cp /var/log/mcelog "$pwd"mcelog_fail.log
		else
			sed -i 's/--syslog/--syslog --logfile=\/var\/log\/mcelog/g' /usr/lib/systemd/system/mcelog.service
			systemctl enable mcelog.service
			systemctl daemon-reload
		fi
	fi
}


Check_BMC_BIOS_Bank(){

cat "$pwd"BMC/Bank/command_status.log | grep -i ok > /dev/null
if [ "$?" == 0 ]; then

ipmitool raw 0x32 0x8f 0x02 > "$pwd"BMC/Bank/BMC_Bank_$boot.log

echo "=============== "$boot" ===============" >  "$pwd"BMC/Bank/BMC_Bank_fail_tmp_1.log
echo " " >>  "$pwd"BMC/Bank/BMC_Bank_fail_tmp_1.log
diff  "$pwd"BMC/Bank/BMC_Bank_Golden_Sample.log "$pwd"BMC/Bank/BMC_Bank_$boot.log >  "$pwd"BMC/Bank/BMC_Bank_fail_tmp_2.log
if [ -s "$pwd"BMC/Bank/BMC_Bank_fail_tmp_2.log ]; then
	cat "$pwd"BMC/Bank/BMC_Bank_fail_tmp_2.log >> "$pwd"BMC/Bank/BMC_Bank_fail_tmp_1.log
	echo "error" >>  "$pwd"BMC/Bank/BMC_Bank_fail_tmp_1.log
	echo " " >>  "$pwd"BMC/Bank/BMC_Bank_fail_tmp_1.log
else
	sleep 1
fi
cat "$pwd"BMC/Bank/BMC_Bank_fail_tmp_1.log | grep "error" > /dev/null
if [ "$?" == 0 ]; then
	sed -i '/error/d' "$pwd"BMC/Bank/BMC_Bank_fail_tmp_1.log
	cat "$pwd"BMC/Bank/BMC_Bank_fail_tmp_1.log  >> "$pwd"BMC/BMC_Bank_fail.log
	#cat "$pwd"BMC/Bank/BMC_Bank_fail_tmp_1.log  >> "$pwd"BMC_Bank_fail.log
	echo 
	echo -e ${RED}
	echo "Detected BMC bank switched at loop: $boot."
	echo
	echo -e ${GREEN}
fi
rm -f "$pwd"BMC/Bank/BMC_Bank_fail_tmp_1.log
rm -f "$pwd"BMC/Bank/BMC_Bank_fail_tmp_2.log

fi


cat "$pwd"BIOS/Bank/command_status.log | grep -i ok > /dev/null
if [ "$?" == 0 ]; then


ipmitool raw 0x36 0x79 0x2a 0x6f 0x00 0x02 > "$pwd"BIOS/Bank/BIOS_Bank_$boot.log


echo "=============== "$boot" ===============" >  "$pwd"BIOS/Bank/BIOS_Bank_fail_tmp_1.log
echo " " >>  "$pwd"BIOS/Bank/BIOS_Bank_fail_tmp_1.log
diff "$pwd"BIOS/Bank/BIOS_Bank_Golden_Sample.log "$pwd"BIOS/Bank/BIOS_Bank_$boot.log >  "$pwd"BIOS/Bank/BIOS_Bank_fail_tmp_2.log
if [ -s "$pwd"BIOS/Bank/BIOS_Bank_fail_tmp_2.log ]; then
	cat "$pwd"BIOS/Bank/BIOS_Bank_fail_tmp_2.log >> "$pwd"BIOS/Bank/BIOS_Bank_fail_tmp_1.log
	echo "error" >>  "$pwd"BIOS/Bank/BIOS_Bank_fail_tmp_1.log
	echo " " >>  "$pwd"BIOS/Bank/BIOS_Bank_fail_tmp_1.log
else
	sleep 1
fi
cat "$pwd"BIOS/Bank/BIOS_Bank_fail_tmp_1.log | grep "error" > /dev/null
if [ "$?" == 0 ]; then
	sed -i '/error/d' "$pwd"BIOS/Bank/BIOS_Bank_fail_tmp_1.log
	cat "$pwd"BIOS/Bank/BIOS_Bank_fail_tmp_1.log  >> "$pwd"BIOS/BIOS_Bank_fail.log
	#cat "$pwd"BIOS/BIOS_Bank_fail.log >> "$pwd"BIOS_Bank_fail.log
	echo 
	echo -e ${RED}
	echo "Detected BIOS bank switched at loop: $boot."
	echo
	echo -e ${GREEN}
fi
rm -f "$pwd"BIOS/Bank/BIOS_Bank_fail_tmp_1.log"$pwd"BMC/BMC_sdr_tmp.log
rm -f "$pwd"BIOS/Bank/BIOS_Bank_fail_tmp_2.log

fi
}


Record_resful_HW_device_scan(){
	
	$ScriptPath/Get_Restful_storage_info_tmp.sh > "$pwd"BMC/Restful/Storage_info_tmp.log
	cat "$pwd"BMC/Restful/Storage_info_tmp.log | tail -1 | jq > "$pwd"BMC/Restful/Storage_info_$boot.log
	$ScriptPath/Get_Restful_pcie_info_tmp.sh > "$pwd"BMC/Restful/PCIe_info_tmp.log
	cat "$pwd"BMC/Restful/PCIe_info_tmp.log | tail -1 | jq > "$pwd"BMC/Restful/PCIe_info_$boot.log


	#echo "=============== "$i" ===============" >  Restful/Restful_fail_tmp_1.log
	#echo " " >>  Restful/Restful_fail_tmp_1.log
	diff "$pwd"BMC/Restful/Storage_info_Golden_Sample.log "$pwd"BMC/Restful/Storage_info_$boot.log >  "$pwd"BMC/Restful/Storage_fail_tmp.log
	if [ "$?" == 0 ]; then
		echo "Storage information check OK."
	else
		echo "=============== "$boot" ===============" >> "$pwd"BMC/Restful/Storage_fail.log
		cat "$pwd"BMC/Restful/Storage_fail_tmp.log >> "$pwd"BMC/Restful/Storage_fail.log
		echo " " >> "$pwd"BMC/Restful/Storage_fail.log
		#echo "Detected Storage info error at loop: $boot."
		#cat "$pwd"BMC/Restful/Storage_fail.log >> "$pwd"Restful_Storage_fail.log
	fi
	echo
	diff "$pwd"BMC/Restful/PCIe_info_Golden_Sample.log "$pwd"BMC/Restful/PCIe_info_$boot.log >  "$pwd"BMC/Restful/PCIe_fail_tmp.log
	if [ "$?" == 0 ]; then
		echo "PCIe informtion check OK."
	else
		echo "=============== "$boot" ===============" >> "$pwd"BMC/Restful/PCIe_fail.log
		cat "$pwd"BMC/Restful/Storage_fail_tmp.log >> "$pwd"BMC/Restful/PCIe_fail.log
		echo " " >> "$pwd"BMC/Restful/PCIe_fail.log
		#echo "Detected PCIe info error at loop: $boot."
		#cat "$pwd"BMC/Restful/PCIe_fail.log >> "$pwd"Restful_PCIe_fail.log
	fi

echo
}

VPD_Check(){

$ScriptPath/Get_vpd_info.sh > "$pwd"VPD/VPD_info_$boot.log
	#if [ "$boot" != "1" ];then
		diff -c "$pwd"VPD/VPD_info_Golden_Sample.log "$pwd"VPD/VPD_info_$boot.log >> "$pwd"VPD_info_fail.log
	#fi

}
path_nvflash(){

cd $ScriptPath

}


vBIOS_Check(){
cat $ScriptPath/vBIOS_status.log | grep -i y > /dev/null
if [ "$?" == 0 ]; then

path_nvflash

./nvflash_58190 --version > "$pwd"vBIOS/vBIOS_info_tmp_$boot.log
	#if [ "$boot" != "1" ];then
		cat "$pwd"vBIOS/vBIOS_info_tmp_$boot.log | grep -i version > "$pwd"vBIOS/vBIOS_info_$boot.log
		diff -c "$pwd"vBIOS/vBIOS_info_Golden_Sample.log "$pwd"vBIOS/vBIOS_info_$boot.log >> "$pwd"vBIOS_info_fail.log
	#fi
fi
}

MCE_Check(){
$ScriptPath/Get_MCE_status.sh  > "$pwd"MCE/MCE_status_$boot.log
	#if [ "$boot" != "1" ];then
while read line
do
	grep "$line" "$pwd"MCE/MCE_status_Golden_Sample.log > /dev/null
	if [ "$?" !=  0 ]; then
		echo "================ $boot ==============" >> "$pwd"MCE_status_fail.log
		echo "$line" >> "$pwd"MCE_status_fail.log
	fi
done < "$pwd"MCE/MCE_status_$boot.log
 
	#fi

}

MEM_Check(){
$ScriptPath/Get_Mem_size_info.sh  > "$pwd"MEM/MEM_info_$boot.log
target_size=$(cat "$pwd"MEM/MEM_info_$boot.log | grep Mem | awk -F " " '{print $2}')
lower_final_size=$(cat "$pwd"MEM/MEM_Size_Golden_Sample.log | grep Lower_size | awk -F ":" '{print $2}')
upper_final_size=$(cat "$pwd"MEM/MEM_Size_Golden_Sample.log | grep Upper_size | awk -F ":" '{print $2}')
result_lower=$(echo "$target_size > $lower_final_size"|bc)
result_upper=$(echo "$upper_final_size > $target_size"|bc)
if [ "$result_lower" != 1 ] && [ "$result_upper" != 1 ]; then
	golden_size=$(cat "$pwd"MEM/MEM_info_Golden_Sample.log | grep Mem | awk -F " " '{print $2}')
	echo "================ $boot ==============" >> "$pwd"MEM_status_fail.log
	echo  "Upper Mem Size: $upper_final_size" >> "$pwd"MEM_status_fail.log
	echo  "Golden Mem Size: $golden_size " >> "$pwd"MEM_status_fail.log
	echo  "Lower Mem Size: $lower_final_size" >> "$pwd"MEM_status_fail.log
	echo  "Current Mem Size: $target_size " >> "$pwd"MEM_status_fail.log
	echo  " " >> "$pwd"MEM_status_fail.log
fi	
 

}

Shutdown_time(){
echo "================================="$boot"=================================" >> "$pwd"OS_Shutdown_time.log
echo ""  >> "$pwd"OS_Shutdown_time.log
last -x -F -n 1 shutdown | head -1 | awk -F " " '{print $5" "$6" "$7" "$8" "$9" "$10" "$11" "$12" "$13" "$14" "$15" "$16" "$17}' >> "$pwd"OS_Shutdown_time.log
echo ""  >> "$pwd"OS_Shutdown_time.log

}

## ---------------------------------------------- START --------------------------------------------------------
color_table

## clear the time of wakealarm
echo 0 > /sys/class/rtc/rtc0/wakealarm 
#sleep $default_sleep

#ScriptPath
#ScriptPath="/$(grep Exec /root/.config/autostart/UUT_loop_main.sh.desktop | cut -d "/" -f 2-4)"

#Testmethod=`cat $ScriptPath/TESTMETHOD`	## AC/DC/Reboot
Testmethod=`grep Test_method $ScriptPath/Loop.conf | sed 's/Test_method=//'g`

#TESTRUN=`cat $ScriptPath/TESTRUN`	## Normal or Debug mode
TESTRUN=`grep Test_run $ScriptPath/Loop.conf | sed 's/Test_run=//'g`

#DCmethod=`cat $ScriptPath/DCMETHOD`	## RTC or ipmi
DCmethod=`grep DC_method $ScriptPath/Loop.conf | sed 's/DC_method=//'g`

#Rebootmethod=`cat $ScriptPath/RBMETHOD`	## Reboot with Host or not
Rebootmethod=`grep Reboot_method $ScriptPath/Loop.conf | sed 's/Reboot_method=//'g`

#TestCycles=`cat $ScriptPath/CTC`	## custom test cycles
TestCycles=`grep CYCLES $ScriptPath/Loop.conf | sed 's/CYCLES=//'g`

## RUNTIME
RUNTIME=`grep RUNTIME $ScriptPath/Loop.conf | sed 's/RUNTIME=//'g`

#start_time=$(cat script_start.log)
Logfoldername="${Testmethod}_test_logs"
pwd="$HOME/$Logfoldername/"

## 將 RUNTIME 轉換成秒數
if [ "$RUNTIME"  == "12 hours" ];then
	TESTTIME=43200
elif [ "$RUNTIME"  == "24 hours" ];then
	TESTTIME=86400
elif [ "$RUNTIME"  == "48 hours" ];then
	TESTTIME=172800
elif [ "$RUNTIME"  == "60 hours" ];then
	TESTTIME=216000
elif [ "$RUNTIME"  == "1000 cycles" ];then
	TESTTIME=99999999
elif [ "$RUNTIME"  == "1000 hours" ];then
	TESTTIME=3600000
elif [ "$RUNTIME"  == "CTC" ];then
	TESTTIME=99999999
fi	

## Counts the testing cycles and times.
if [ -e "$pwd"bootcount.log ]; then
	echo $(($(cat "$pwd"bootcount.log)+1)) > "$pwd"bootcount.log
else
	hwclock --systohc --utc
	echo "1" > "$pwd"bootcount.log
	## 測試開始的時間
	date +%s > "$pwd"time1
	## 測試結束的時間
	echo $(($(cat "$pwd"time1)+$TESTTIME)) > "$pwd"time2
fi
sync
#boot=`printf "%04d" "$(cat "$pwd"bootcount.log)"`
boot=$(cat "$pwd"bootcount.log)
sleep 5

feature_function_add() {
gnome-terminal --geometry=80x20+200+200 -- bash -c "echo Script status in Record_disk;sleep 10" 
Record_disk
gnome-terminal --geometry=80x20+200+200 -- bash -c "echo Script status in Record_PCI;sleep 10" 
Record_PCI
gnome-terminal --geometry=80x20+200+200 -- bash -c "echo Script status in Record_NIC;sleep 10" 
Record_NIC
gnome-terminal --geometry=80x20+200+200 -- bash -c "echo Script status in Record_megaraid;sleep 10" 
Record_megaraid
gnome-terminal --geometry=80x20+200+200 -- bash -c "echo Script status in Record_mptsas;sleep 10" 
Record_mptsas
gnome-terminal --geometry=80x20+200+200 -- bash -c "echo Script status in Record_USB;sleep 10" 
Record_USB
gnome-terminal --geometry=80x20+200+200 -- bash -c "echo Script status in Record_DMI;sleep 10" 
Record_DMI
gnome-terminal --geometry=80x20+200+200 -- bash -c "echo Script status in Record_dmesg;sleep 10"  
Record_dmesg
gnome-terminal --geometry=80x20+200+200 -- bash -c "echo Script status in Record_mcelog;sleep 10"  
Record_mcelog
gnome-terminal --geometry=80x20+200+200 -- bash -c "echo Script status in Record_FW_info;sleep 10" 
Record_FW_info
gnome-terminal --geometry=80x20+200+200 -- bash -c "echo Script status in Record_BMC;sleep 10" 
Record_BMC
gnome-terminal --geometry=80x20+200+200 -- bash -c "echo Script status in VPD_Check;sleep 10" 
VPD_Check
gnome-terminal --geometry=80x20+200+200 -- bash -c "echo Script status in MCE_Check;sleep 10" 
MCE_Check
gnome-terminal --geometry=80x20+200+200 -- bash -c "echo Script status in vBIOS_Check;sleep 10" 
vBIOS_Check
gnome-terminal --geometry=80x20+200+200 -- bash -c "echo Script status in MEM_Check;sleep 10" 
MEM_Check
gnome-terminal --geometry=80x20+200+200 -- bash -c "echo Script status in Check_BMC_BIOS_Bank;sleep 10" 
Check_BMC_BIOS_Bank
gnome-terminal --geometry=80x20+200+200 -- bash -c "echo Script status in Analysis_BMC_Dmesg;sleep 10"  
Analysis_BMC_Dmesg
gnome-terminal --geometry=80x20+200+200 -- bash -c "echo Script status in Shutdown_time;sleep 10" 
Shutdown_time
gnome-terminal --geometry=80x20+200+200 -- bash -c "echo Script check completed......; echo Wait for checking result.....;sleep 5" 
}

#for test_item in Record_USB Record_PCI Record_NIC Record_megaraid Record_DMI Record_mcelog VPD_Check MCE_Check vBIOS_Check MEM_Check Record_disk Check_BMC_BIOS_Bank Record_BMC Record_mptsas Record_dmesg Analysis_BMC_Dmesg 
debug_test(){
for test_item in Record_PCI Record_DMI Record_disk Analysis_BMC_Dmesg 
do
	#echo "going" > $ScriptPath/script.status2
	#{
	date "+%Y-%m-%d %T" 2>&1 | tee  $ScriptPath/item_start.log
	#echo "$test_item test start.."
	
	echo "$test_item test start.." 
	sleep 1
	echo "$test_item is going" 
	$test_item
	
	echo "$test_item test done.."
	sleep 1	
	
	date "+%Y-%m-%d %T" 2>&1 | tee  $ScriptPath/item_end.log
	item_start=$(cat $ScriptPath/item_start.log)
	item_end=$(cat $ScriptPath/item_end.log)
	item_time=$(($(date -d "$item_end" +%s)-$(date -d "$item_start" +%s))) 

	echo
	echo "Escape time: $item_time "
	echo


done

}
debug_test
#Record_resful_HW_device_scanAnalysis_BMC_Dmesg
Shutdown_time
## 判斷是否已達到測試次數
if [ "$boot" -ge "$TestCycles" ]; then
	
	if [ "$Testmethod" == "Reboot" ];then
		Backup_name=$( date "+%Y%m%d%T"| sed 's/\://g')
		cp -r $HOME/$Logfoldername/ $HOME/$Backup_name"_"$Logfoldername/
		Teststatus="${Testmethod} test has been finished."
		FinishTest="Yes"
		CHECKRESULT
		
		#exit 0
	else
		Teststatus="${Testmethod} power cycling test has been finished."
		Backup_name=$( date "+%Y%m%d%T"| sed 's/\://g')
		cp -r $HOME/$Logfoldername/ $HOME/$Backup_name"_"$Logfoldername/
		FinishTest="Yes"
		CHECKRESULT
		
		#exit 0
	fi
fi

if [ "$Testmethod" == "AC" ] ; then

	#ipmitool sel clear
	Teststatus="No. $boot times for ${Testmethod} on/off test."
	echo $Teststatus
	CHECKRESULT
fi

if [ "$Testmethod" == "DC" ] && [ "$DCmethod" == "By RTC" ]; then
## DC by RTC
	WU=`cat /sys/class/rtc/rtc0/wakealarm` 
	while [ "$WU" == "" ];
	do
		echo $(date +%s --date "now + $rtc_delay minutes") > /sys/class/rtc/rtc0/wakealarm 
		sleep 1 ; sync ; sleep 2
		WU=`cat /sys/class/rtc/rtc0/wakealarm` 
	done
	ipmitool sel clear
	Teststatus="No. $boot times for ${Testmethod} on/off test."
	CHECKRESULT
fi
## Reboot remote control

if [ "$Testmethod" == "Reboot" ]; then
	if [ "$Rebootmethod" == "Yes." ]; then
	
		echo "Wait for remote client control"
	else
	
		ipmitool sel clear
	fi
	Teststatus="No. $boot times for ${Testmethod} test."
	CHECKRESULT
		
fi



