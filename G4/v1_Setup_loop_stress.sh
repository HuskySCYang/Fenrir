#!/bin/bash
# Program:
# 		This script is used for all loop test on UUT.
# version:
# 		1.5
# Date:
#		10/29/2021

path_detect(){
pwd > target_path.log
echo "path_go(){" > run_stress_loop_script.sh
#cat target_path.log
echo "cd $PWD" >> run_stress_loop_script.sh
cat path.sh >> run_stress_loop_script.sh
chmod 777 run_stress_loop_script.sh

echo "#!/bin/bash" > UUT_loop_main.sh
cat run_stress_loop_script.sh | head -8 >>  UUT_loop_main.sh
final_path=$(cat target_path.log)
echo "ScriptPath="$final_path"" >> UUT_loop_main.sh
cat v4_UUT_loop_main.sh >> UUT_loop_main.sh
}


path_detect


#cp v4_UUT_loop_main.sh UUT_loop_main.sh
chmod 777 UUT_loop_main.sh


source Client_configuration
ipmitool sel clear
sleep 10

cat /etc/os-release > os_info.log

echo "ifconfig $os_NIC_1 169.254.1.123" > /etc/profile.d/run_unset_lan.sh
chmod 777 /etc/profile.d/run_unset_lan.sh
. /etc/profile.d/run_unset_lan.sh
update(){
read -p "Environment check !!  (y/n): " checked

if [ "$checked" == "y" ]; then
 
	cat os_info.log | grep -i ubuntu >/dev/null
	pip3 install redfishtool
	pip3 install --upgrade urllib3
	pip3 install --upgrade requests
	pip3 install nautilus
	pip3 install robotframework
	pip3 install pyserial-3.4-py2.py3-none-any.whl
	cat os_info.log | grep -i ubuntu > /dev/null
	if [ "$?" == 0 ]; then
		apt install jq -y
		apt install ipmitool -y
		apt install gawk -y
		apt install fence* -y
		apt install ipmiutil -y
		apt install rasdaemon -y
		apt install nautilus -y
		apt install smartmontools -y
		apt install lsscsi* -y
		apt install ethtool -y
	else
		yum install jq -y
		yum install ipmitool -y
		yum install fence* -y
		yum install nautilus -y
		yum install gawk -y
		yum install ipmiutil -y
		yum install nautilus -y
		yum install rasdaemon -y
		#yum install smartmontools -y
	        yum install lsscsi* -y
		# install ipmiutil
		if [ "$(rpm -qa | grep -i ipmiutil)" == "" ];then
		rpm -ivh ipmiutil-3.1.8-1_el8.x86_64.rpm
		fi
	fi
fi
}
echo setting > flow.txt
#read -p "Do you want to execute lazy mode(y/n): " lazy

cp run_stress_loop_script.sh /etc/profile.d/

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



# 載入色彩
color_table

# 清除舊的設定檔
rm -f Loop.conf

# Debug option

echo "Test_run=Normal test" >> $PWD/Loop.conf


# Boot into OS delay time

echo
read -p "Please input the delay time after booting into OS: " wait_time

echo $wait_time > wait_time.log


# Choose test method
T01="AC"
T02="DC"
T03="Reboot"
TESTCASE=("$T01" "$T02" "$T03")
PS3="Choose the test item: "
echo -e ${ORANGE}
select i in "${TESTCASE[@]}"
do
	echo "Test_method=$i" >> $PWD/Loop.conf
	break
done


# AC by RTC

if [ "$i" == "AC" ]; then
	#T02="By Remote"	
	echo -e ${RED}
	echo "AC off behavior: Force AC off " 
	AC=1
	echo $AC > AC.method
	echo "AC_method=By Remote" >> $PWD/Loop.conf
			
fi

	

# DC by RTC
if [ "$i" == "DC" ];then
	T01="By RTC"
	T02="By BMC"
	TESTCASE2=("$T01" "$T02")
	PS3="How to power on the UUT: "
	echo -e ${RED}
	select j in "${TESTCASE2[@]}"
	do
		echo "DC_method=$j" >> $PWD/Loop.conf
		break
	done
fi

# Reboot with remote server
if [ "$i" == "Reboot" ];then
	#T01="Yes."
	#T02="No."
	#TESTCASE2=("$T01" "$T02")
	#PS3="Do you want to use the remote host for Reboot test? "
	#echo -e ${RED}
	#select k in "${TESTCASE2[@]}"
	#do
		echo "Reboot_method="No."" >> $PWD/Loop.conf
		#break
	#done
	
fi

# Test duration

echo
read -p "Please input the test cycles: " CTC
echo -e ${PURPLE}

echo "CYCLES=$CTC" >> $PWD/Loop.conf
echo $CTC > CTC.txt
echo "RUNTIME=1000 hours" >> $PWD/Loop.conf
	
echo -e ${NC}


# Load parameter
#date "+%Y%m%d%H%M%S" > script_start.log
#start_time=$(cat script_start.log)
Testmethod=`grep Test_method $PWD/Loop.conf | sed 's/Test_method=//'g`
Logfoldername="${Testmethod}_test_logs"

AC_disable_off(){
if [ "$Testmethod" == "AC" ] && [ "$AC" == 1 ]; then
echo
read -p "DC off behavior: 1. OS 'init 0' off; 2. BMC chassis power off. (1/2): " adcboot
echo
	echo $adcboot > adcboot.method

fi
}
	echo 1 > adcboot.method


DC_BMC_Control(){
method=$(cat $PWD/Loop.conf | grep "DC_method" | grep BMC -c)
if [ "$Testmethod" == "DC" ] && [ "$method" == 1 ]; then
echo
read -p "DC off behavior: 1. OS 'init 0' off; 2. BMC chassis power off. (1/2): " dcboot
echo
	echo $dcboot > dcboot.method

fi

}

method=$(cat $PWD/Loop.conf | grep "DC_method" | grep RTC -c)
if [ "$Testmethod" == "DC" ] && [ "$method" == 1 ]; then

read -p "Input RTC delay time (minute base: This value should more than 2 ): " rtc_delay
echo
	#echo $rtc_delay | grep ""[a-z]"\|"[A-Z]"" 
	rtc_condition=$(echo $(($rtc_delay - 3)))
	if [ $rtc_condition -ge 0 ]; then
		echo $rtc_delay > rtc_delay.value
	else
		echo
		echo "RTC delay time is invalid value."
		echo
		exit
	fi

	read -p "DC off behavior: 1. OS 'init 0' off; 2. BMC chassis power off. (1/2): " dcboot
echo
	echo $dcboot > dcboot.method



fi







if [ "$Testmethod" == "Reboot" ]; then
echo
read -p "Reboot behavior: 1. OS 'init 6' reboot; 2. BMC chassis power reset. (1/2): " reboot
echo
	echo $reboot > reboot.method

fi 



## Create the folder of log files.

rm -rf $HOME/$Logfoldername
mkdir -p $HOME/$Logfoldername/{BMC/mc,BMC/event,BMC/sdr,BMC/sdr/tmp,BMC/fru,dmesg,disk,pci,usb,pci_link,pci_debug,net_link,DMI}

pwd="$HOME/$Logfoldername/"

cp $PWD/Loop.conf "$pwd"Test_Config.log
#-------------------------------------------------------# 
# Copy autostart file

#cp $PWD/UUT_loop_main.sh.desktop /root/.config/autostart/
#-------------------------------------------------------# 


echo
## Record the system information
./Get_system_info.sh > "$pwd"System_info.log

## Record the information of drives.
./Get_SATA_devices_info_cat.sh 
./Get_SATA_devices_info.sh > "$pwd"disk/SATA_drives_info_Golden_Sample.log
cat "$pwd"disk/SATA_drives_info_Golden_Sample.log | sed '/dev/d' | awk NF | sort > "$pwd"disk/SATA_drives_info_Golden_Sample_sort.log
./Get_NVMe_devices_info.sh > "$pwd"disk/NVMe_drives_info_Golden_Sample.log
cat "$pwd"disk/NVMe_drives_info_Golden_Sample.log | awk NF | sort > "$pwd"disk/NVMe_drives_info_Golden_Sample_sort.log
## SYS block devices detection
ls -l /sys/block/ | grep root |  cut -d ">" -f 2 > "$pwd"disk/SYS_block_info_Golden_Sample.log

## Record the link speed of pci devices.
./Get_PCI_devices_info.sh > "$pwd"pci_link/PCI_Link_Golden_Sample.log 2> /dev/null
./Get_PCI_debug_info.sh > "$pwd"pci_debug/PCI_debug_Golden_Sample.log 2> /dev/null
## Record all of pci devices.(include the NVMe drives.)
lspci > "$pwd"pci/lspci_Golden_Sample.log
lspci -vvv > "$pwd"pci/lspci-vvv_Golden_Sample.log

## Record the link speed of network.
#./Get_NIC_connection.sh > "$pwd"net_link/NIC_link_Golden_Sample.log
#cat "$pwd"net_link/NIC_link_Golden_Sample.log | awk NF | sort > "$pwd"net_link/NIC_link_Golden_Sample_sort.log


## Record all of usb devices.
./Get_USB_devices_info.sh > "$pwd"usb/USB_info_Golden_Sample.log

## BMC FRU
ipmitool fru print > "$pwd"BMC/fru/fru_Golden_Sample.log
## BMC MC info
ipmitool mc info > "$pwd"BMC/mc/mc_Golden_Sample.log
## BMC SDR(20230210:add the sensor status check)
ipmitool sdr elist > "$pwd"BMC/sdr/sdr_Golden_Sample.log
cat "$pwd"BMC/sdr/sdr_Golden_Sample.log | awk -F "|" '{print $1 $3}' > "$pwd"BMC/sdr/sdr_Golden_tmp.log
#cat "$pwd"BMC/sdr/sdr_Golden_Sample.log | awk -F "|" '{print $3}' > "$pwd"BMC/sdr/sdr_Golden_Sample_status.log


## DMI check
dmidecode -t 0 > "$pwd"DMI/BIOS_Golden_Sample.log
dmidecode -t 1 | grep -v Wake > "$pwd"DMI/System_Golden_Sample.log
dmidecode -t 2 > "$pwd"DMI/Baseboard_Golden_Sample.log
dmidecode -t 3 > "$pwd"DMI/Chassis_Golden_Sample.log
dmidecode -t 4 > "$pwd"DMI/CPU_Golden_Sample.log
dmidecode -t 17 | grep -i -w "Siz:e\|Locator:\|Speed\|Manufacturer:\|Volatile Size" > "$pwd"DMI/MEM_Golden_Sample.log
#dmidecode > "$pwd"DMI/DMI_Golden_Sample.log

#--------------------------------------------------------------------------------------------
if [ -f "control.method" ]; then
	rm -f control.method
fi
if [ "$Testmethod" == "DC" ];then
	if [ "$(grep DC_method $PWD/Loop.conf | sed 's/DC_method=//'g)" == "By RTC" ];then
		echo -e ${BLUE} "1. The golden sample files have created, please check these files are correct!! "
		echo -e ${RED} "2. Command "ipmitool chassis power cycle" the system to start the test."
		echo "reboot" > control.method
	#else
	#	echo -e ${BLUE} "1. The golden sample files have created, please check these files are correct!! "
	#	echo -e ${RED} "2. Shut down the system and execute the script Host_control.sh on the remote side to start the test."
		echo "shutdown" > control.method
	fi
elif [ "$Testmethod" == "AC" ];then
	echo -e ${BLUE} "1. The golden sample files have created, please check these files are correct!! "
	echo -e ${RED} "2. Shut down the system and execute the script Host_control.sh on the remote side to start the test."
	echo "shutdown" > control.method
elif [ "$Testmethod" == "Reboot" ];then
	if [ "$(grep Reboot_method $PWD/Loop.conf | sed 's/Reboot_method=//'g)" == "Yes." ];then
		echo -e ${BLUE} "1. The golden sample files have created, please check these files are correct!! "
		echo -e ${RED} "2. Shut down the system and execute the script Host_control.sh on the remote side to start the test."
		echo "shutdown" > control.method
	else
		echo -e ${BLUE} "1. The golden sample files have created, please check these files are correct!! "
		echo -e ${RED} "2. Reboot the system to start the test."
		echo "reboot" > control.method
	fi
fi


# open nautilus



other_action(){
action=$(cat control.method)

case "$action" in

reboot)
	
	echo "Please reboot the system via "init 6" to start the stress."
		
;;

idle)
      	
	echo "Please don't do anything, script will take the action to start stress."
		
;;

shutdown)
	
	
	echo "Please reboot the system via "init 6" to start the stress."
	
	
esac

}


echo -e ${NC}
