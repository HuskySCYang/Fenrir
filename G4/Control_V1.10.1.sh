#!/bin/bash
# Program:
# 		This script is used to control the UUT to perform the loop tests.
# version:
# 		1.0
# Date:
#		08/22/2019


##############################################################################################


future_function_implement(){
echo
read -p "Would you want to continue the stress or another new stress(1: continue, 2: new): " new_go
echo
}



##############################################################################################
cat configuration | grep "sled=" > bmcs.txt
echo 1 > test.cfg
echo 1 > sled_status.txt
rm -f *.cfg
rm -f sled_status.txt
while read line
do
	number=$(echo $line | awk -F "=" '{print $2}')
#	echo $number
#	echo "cat configuration | grep "sled=$number" -A 3 > sled_$number.cfg"
	cat configuration | grep "sled=$number" -A 3 > sled_$number.cfg

done < bmcs.txt

ls *.cfg > target.txt

for line in $(cat target.txt)
do
#cat $iconfig
name=$(echo $line | awk -F "." '{print $1}')
folder_ip=$(cat $line | grep ip | awk -F "=" '{print $2}')

if [ -d "$name" ]; then
rm -r -f "$name"
fi

mkdir -p {"$name"/Boot_error,"$name"/BMC_SEL,"$name"/BMC_Bank,"$name"/BIOS_Bank,"$name"/Version,"$name"/Restful}


done




##############################################################################################






new_go=2

if [ "$new_go" = 1 ]; then
start_tmp=$(cat "$name"/loop_count.txt)
start_condition=$(echo $(($start_tmp+1)))
echo
echo "Continue the stress at loop: $start_condition "
echo
for iconfig in $(cat target.txt)
do
#cat $iconfig
name=$(echo $iconfig | awk -F "." '{print $1}')
folder_ip=$(cat $iconfig | grep ip | awk -F "=" '{print $2}')
done

elif [ "$new_go" = 2 ]; then
start_condition=1
echo
read -p "Environment check !! (y/n): " checked

if [ "$checked" == "y" ]; then
 
pip3 install redfishtool
pip3 install pyserial-3.4-py2.py3-none-any.whl 

cat /etc/os-release > "$name"/os_info.log
cat os_info.log | grep -i ubuntu > /dev/null
if [ "$?" == 0 ]; then
	apt install python3 -y
	apt install jq -y
	apt install ipmitool -y
	apt install gawk -y
	apt install fence* -y
else
	yum install python3 -y
	yum install jq -y
	yum install ipmitool -y
	yum install fence* -y
fi

fi



else

echo
echo "Abnormal selection..."
echo
	exit


fi
##############################################################################################

#echo
#echo
#read -p "Do you want to execute lazy mode(y/n): " lazy
#echo
#if [ "$lazy" == y ]; then
path=$(pwd)
. $path/configuration
	if [ "$?" != 0 ]; then
		echo "There is no configuration file in $path/"	
			exit
	fi

hang_folder=$path/"$name"/Boot_error

if [ -f ""$PJN"_AC_power_on_time.log" ]; then
	rm -f "$PJN"_AC_power_on_time.log
fi

if [ -f ""$PJN"_DC_power_on_time.log" ]; then
	rm -f "$PJN"_DC_power_on_time.log
fi


if [ -f "BMC_Boot_time.log" ]; then
	rm -f BMC_Boot_time.log
fi

if [ -f "OS_boot_time.log" ]; then
	rm -f OS_boot_time.log
fi



function Colorful_script(){
	BLACK='\033[0;30m'
	RED='\033[0;31m'
	GREEN='\033[0;32m'
	ORANGE='\033[0;33m'
	BLUE='\033[0;34m'
	PURPLE='\033[0;35m'
	CYAN='\033[0;36m'
	NC='\033[0m'
}


function SystemPowerOn(){ #DC on by ipmitool
	SystemPowerStatus
	while [ "$SystemStatus" == "Chassis Power is off" ]
	do
		ipmitool -I lanplus -H $ip -U $user -P $password power on
		sleep 5
		SystemPowerStatus
		
	done
}


function SystemPowerReset(){ #reboot on by ipmitool
	SystemPowerStatus
	while [ "$SystemStatus" == "Chassis Power is on" ]
	do
		ipmitool -I lanplus -H $ip -U $user -P $password power reset
		if [ "$?" == 0 ]; then
			break
		else
			echo -n -e "." 
			sleep 1
		fi
		#SystemPowerStatus
		
	done
}

function SystemPowerStatus(){ #check the power status of active node
	SystemStatus=""
	sleep 1
	while [ "$SystemStatus" == "" ]
	do
		SystemStatus=`ipmitool -I lanplus -H $ip -U $user -P $password chassis power status`
		sleep 4
	done
}

function GetSELKeyWord(){ #capture the system event log if included "event 3" 
	#echo 1 > "$name"/KeyWord.log
	#sleep 1
	
	#rm -f "$name"/KeyWord.log
	SEL1=""
	sel_counter=0
	while true
	do
		ipmitool -I lanplus -H $ip -U $user -P $password sel list 2> /dev/null 1> "$name"/KeyWord.log
		if [ "$?" == 0 ]; then
			break
		else
			sleep 1
			echo -n -e "."
			let "sel_counter=$sel_counter+1"
			#if [ "$sel_counter" == 10 ]; then
			#echo "BMC session interrupt, can't get SEL."
				#exit
			#fi
		fi
	done
	
	cat "$name"/KeyWord.log | grep -i "OS Boot #0x87" > /dev/null
	if [ "$?" == 0 ]; then
		SEL1=`cat "$name"/KeyWord.log | grep -i "OS Boot #0x87"`
		#echo "loop_scripts executed completed." >  script.status
	fi

	cat "$name"/KeyWord.log | grep -i "Platform Security #0x87"  > /dev/null
	if [ "$?" == 0 ]; then
		SEL1=`cat "$name"/KeyWord.log | grep -i "Platform Security #0x87"`
		#echo "loop_scripts executed completed." >  script.status
	fi

	################################ debug-mode exit confition ################################ 
	cat "$name"/KeyWord.log | grep -i "OS Boot #0xf7" > /dev/null
	if [ "$?" == 0 ]; then
		if [ "$test_method" == "AC" ]; then
			echo
			echo
			echo "$name $target_ip SUT detect the error oocurred in debug mode."
			echo
			echo "Stop the stress !!"
			echo

		else
			echo
			echo
			echo "SUT detect the error oocurred in debug mode."
			echo
			echo "Stop the stress !!"
			echo
		fi
			exit
		
	fi

	cat "$name"/KeyWord.log | grep -i "Platform Security #0xf7"  > /dev/null
	if [ "$?" == 0 ]; then
		if [ "$test_method" == "AC" ]; then
			echo
			echo
			echo
			echo "$name $target_ip SUT detect the error oocurred in debug mode."
			echo
			echo "Stop the stress !!"
			echo

		else
			echo
			echo
			echo "SUT detect the error oocurred in debug mode."
			echo
			echo "Stop the stress !!"
			echo
		fi
			exit
		
	fi
	################################ debug-mode exit confition ################################ 

	sleep 1
}

function ClearSEL(){ #clear the system event log
	SELCR=0
	until [ "$SELCR" == "Clearing SEL.  Please allow a few seconds to erase." ]
	do
		SELCR=`ipmitool -I lanplus -H $ip -U $user -P $password sel clear`
		echo $SELCR
		sleep 2
		echo
	done
}


function Set_BMC(){
	echo -e ${ORANGE}
	
	echo
	read -p "Do you want to check the Golden Sample SEL(y/n): " Check_SEL
	read -p "Do you want to check the BMC and BIOS boot bank (y/n): " Check_Bank
	read -p "Do you want to check the FW version by redfish (y/n): " Check_Version
	read -p "Do you want to check the PCIe/Storage device by RESTful (y/n): " Check_Restful
	#if [ "$Check_Restful" == "y" ]; then
	#	cat os_info.log | grep -i ubuntu > /dev/null
	#	if [ "$?" == 0 ]; then
	#			apt install jq -y
	#		
	#	else
	#			yum install jq -y
	#		
	#	fi
	#fi

	

}

function Test_mode(){
	T01="Normal test"
	T02="Debug test"
	TESTCASE=("$T01" "$T02" )
	PS3="Choose the test type: "
	echo -e ${GREEN}
	select h in "${TESTCASE[@]}"
	do
		TESTMODE="$h"
		break
	done
	echo "Test Type: "$TESTMODE"" >> Test_info.cfg
}

function Set_duration(){
	echo -e ${BLUE}
	
	echo "Project Name: $PJN"
	
	echo -e ${PURPLE}
	T01="12 hours"
	T02="24 hours"
	T03="48 hours"
	T04="60 hours"
	T05="1000 cycles"
	T06="Custom cycles"
	 
	TESTCASE=("$T01" "$T02" "$T03" "$T04" "$T05" "$T06")
	PS3="Choose the test time or test cycles: "
	select j in "${TESTCASE[@]}"
	do
		if [ "$j"  == "12 hours" ];then
			TESTTIME=43200
			CTC=1000
			echo "Test Time: "12 hours"" >> Test_info.cfg
		elif [ "$j"  == "24 hours" ];then
			TESTTIME=86400
			CTC=1000
			echo "Test Time: "24 hours"" >> Test_info.cfg
		elif [ "$j"  == "48 hours" ];then
			TESTTIME=172800
			CTC=1000
			echo "Test Time: "48 hours"" >> Test_info.cfg
		elif [ "$j"  == "60 hours" ];then
			TESTTIME=216000
			CTC=1000
			echo "Test Time: "60 hours"" >> Test_info.cfg
		elif [ "$j"  == "1000 cycles" ];then
			TESTTIME=9999999999
			CTC=1000
			echo "Test Cycles: "1000 cycles"" >> Test_info.cfg
		elif [ "$j" == "Custom cycles" ];then
			read -p "Please input the test cycles: " CTC
			TESTTIME=9999999999
			echo "Test Cycles: "$CTC cycles"" >> Test_info.cfg
		fi
		break
	done	
}

function PDUPlugStatus(){ # To get the plug power status.
	if [ "$PV" == "APC" ];then
		echo
		echo "PDU Port $PDUPlug status: "
		while true
		do
			fence_apc -a $APC_IP -l $APC_user -p $APC_password -n $PDUPlug -o status 2> /dev/null 1> APC.status
			cat APC.status | grep -i status
			if [ "$?" == 0 ]; then
				break
			else
				echo -n -e "."
				sleep 1
			fi
		done
		PDU1=`cat APC.status`
	else
		PDU1=`ipmitool -I lanplus -H $APC_IP -U $user -P flex raw 0x3c 0x13 $PDUPlug` 
	fi
}

function PDUPlugOn(){
	if [ "$PV" == "APC" ];then
		echo
		echo "Enable PDU Port: $PDUPlug"
		while true
		do
			fence_apc -a $APC_IP -l $APC_user -p $APC_password -n $PDUPlug -o on 2> /dev/null 1> APC.status
			cat APC.status | grep -i on
			if [ "$?" == 0 ]; then
				break
			else
				echo -n -e "."
				sleep 1
			fi
		done
	else
		ipmitool -I lanplus -H $APC_IP -U $user -P flex raw 0x3c 0x12 $PDUPlug 1
	fi
}

function PDUPlugOff(){
	if [ "$PV" == "APC" ];then
		echo
		echo "Disable PDU Port: $PDUPlug"
		while true
		do
			fence_apc -a $APC_IP -l $APC_user -p $APC_password -n $PDUPlug -o off 2> /dev/null 1> APC.status
			cat APC.status | grep -i off
			if [ "$?" == 0 ]; then
				break
			else
				echo -n -e "."
				sleep 1
			fi
		done
	else
		ipmitool -I lanplus -H $APC_IP -U $user -P flex raw 0x3c 0x12 $PDUPlug 0
	fi
}

JBOD_Always_on(){
# ---------------------------------------------------
if [ "$PV" == "APC" ] && [ "$JBOD" == "y" ]; then
	while true
	do	
	
		ipmitool -I lanplus -H $JBOD_ip -U $JBOD_user -P $JBOD_password chassis policy always-on 
		if [ "$?" == 0 ]; then
			break
		else
			echo -n -e "."
			sleep 1
		fi
	done	
fi

# ---------------------------------------------------
}

function PDUPlugOn_JBOD(){
	if [ "$PV" == "APC" ] && [ "$JBOD" == "y" ]; then
		echo 
		echo "JBOD APC Port status"
		echo
		while true
		do
			fence_apc -a $JBOD_APC_IP -l $JBOD_APC_user -p $JBOD_APC_password -n $JBOD_APC_PDUPlug -o on 2> /dev/null 1> APC.status
			cat APC.status | grep -i on
			if [ "$?" == 0 ]; then
				break
			else
				echo -n -e "."
				sleep 1
			fi
		done
	
	fi
}



function PDUPlugOff_JBOD(){
		
	if [ "$PV" == "APC" ] && [ "$JBOD" == "y" ]; then
		echo 
		echo "JBOD APC Port status"
		echo
		while true
		do
			fence_apc -a $JBOD_APC_IP -l $JBOD_APC_user -p $JBOD_APC_password -n $JBOD_APC_PDUPlug -o off 2> /dev/null 1> APC.status
			cat APC.status | grep -i off
			if [ "$?" == 0 ]; then
				break
			else
				echo -n -e "."
				sleep 1
			fi
		done
	
	fi
}



function Check_JBOD_power_on(){
if [ "$PV" == "APC" ] && [ "$JBOD" == "y" ] ;then
echo
while true
do
ipmitool -I lanplus -H $JBOD_ip -U $JBOD_user -P $JBOD_password chassis power status 2>/dev/null 1> JBOD_power.log
cat JBOD_power.log | grep -i on > /dev/null
	if [ "$?" == 0 ]; then
	
		break
	else
	ipmitool -I lanplus -H $JBOD_ip -U $JBOD_user -P $JBOD_password chassis power on
		sleep 10	
	fi
done
echo
echo "JBOD is in power on mode."
echo
fi

}


function Check_PDU_is_OFF_JBOD(){
if [ "$PV" == "APC" ] && [ "$JBOD" == "y" ] ;then
	fence_apc -a $JBOD_APC_IP -l $JBOD_APC_user -p $JBOD_APC_password -n $JBOD_APC_PDUPlug -o status 2> /dev/null 1> APC.status
	PDU1=`cat APC.status`
	if [ "$PDU1" == "Status: ON" ];then
		echo "Please execute the following command to turn off JBOD AC power.
	      fence_apc -a $JBOD_APC_IP -l $JBOD_APC_user -p $JBOD_APC_password -n $JBOD_APC_PDUPlug -o off"
		echo -e ${NC}
		exit 0
	fi
#else
	#if [ "$PDU1" == " 11" ];then
	#	echo "Please execute the following command to turn off JBOD AC power.
	#      ipmitool -I lanplus -H $pduip -U admin -P flex raw 0x3c 0x12 $pduplug2 0"
	#	echo -e ${NC}
	#	exit 0
	#fi
echo "PDU plug for JBOD is power off."
fi

}

function PDUConnection(){
	if [ "$PV" == "APC" ];then
		echo
		echo "Establish PDU session.."

		apc_connect=0
		while true
		do
		fence_apc -a $APC_IP -l $APC_user -p $APC_password -o list|grep -i "1,Outlet" > PDUStatus.txt
	
		PDUStatus=$(cat PDUStatus.txt)
		if [ "$PDUStatus" == "" ];then
			let "apc_connect=$apc_connect+1"
			echo "Get APC status command retry: $apc_connect"
			sleep 2
			if [ "$apc_connect" == 5 ]; then
				echo "Cannot connect to DPU. Please check the network settings."
				exit 0
			fi
		else
			echo
			echo "Successfully connected to the APC."
			break

		fi
		done
	else
		ping $APC_IP -c 1 -t 5 > PDUStatus.log
		PDUStatus=$(cat PDUStatus.log | grep -i ttl -c)
		if [ "$PDUStatus" == "" ];then
			echo "Cannot connect to PDU. Please check the network settings."
			exit 0
		fi
	fi
	echo
}


function Check_PDU_is_OFF(){
if [ "$PV" == "APC" ];then
		echo 
		echo "APC Port status"
		echo
	if [ "$PDU1" == "Status: ON" ];then
		echo "Please execute the following command to turn off AC power.
	      fence_apc -a $APC_IP -l $APC_user -p $APC_password -n $PDUPlug -o off"
		echo -e ${NC}
		exit 0
	fi

fi
echo "PDU plug is power off."
echo
}


function getoffsel(){  #無法DC OFF的project使用
	SEL1=`ipmitool -I lanplus -H $ip -U $user -P $password sel elist | grep "S5/G2: soft-off"`
	sleep 2
}

function Set_PDU(){
	echo
	PV="APC"
	POS="Status: ON"
	#echo "BMC IP: $ip" 
	#echo "BMC User: $user"
	#echo "BMC Password: $password"
	echo "APC/PDU IP:$APC_IP"
	echo "APC/PDU User:$APC_user"
	echo "APC/PDU Password:$APC_password"
	echo "APC/PDU action port: $PDUPlug"
	echo "PSU AC Failure time: $ac_failure_time"
	#fi
	echo
	read -p "Do your want to execute the JBOD AC(y/n): " JBOD
	echo
	if [ "$JBOD" == "y" ]; then
		
		echo "JBOD-BMC IP address: $JBOD_ip"
		echo "JBOD-BMC username:  $JBOD_user"
		echo "JBOD-BMC password:  $JBOD_password"
		echo "JBOD_PDU IP: $JBOD_APC_IP"
		echo "JBOD_PDU User: $JBOD_APC_user"
		echo "JBOD_PDU Password: $JBOD_APC_password"
		echo "JBBOD PDU PLUG number for JBOD: $JBOD_APC_PDUPlug"
	fi	
	echo
	echo

#	read -p "Above infomation are correct(y: continue, n: exit): " go
#	if [ "$go" == "y" ]; then
#		echo
#		echo "Start to the cycle stress."
#		echo
#	else
#		echo
#		echo "Incorrect information, exit the script/"
#		echo
#			exit
#	fi
		
}

start_go(){

echo
#echo "BMC IP: $ip"
#echo "BMC User: $user"
#echo "BMC Password: $password"
#echo "OS boot limitation time: $wait_boot_time"
#echo "OS shutdon limitation time: $shutdown_time"
#echo
for iconfig in $(cat target.txt)
do
cat $iconfig
done
echo
read -p "Please check the test information and continue(y/n) ?: " start_go
echo
if [ "$start_go" == "y" ]; then
	echo 
	echo "Start to the loop stress"
	echo 
else
	echo "Information is incorrect. Exit the script"
	echo
	exit
fi
}

Remote_Check_BMC_BIOS_Bank(){
if [ "$Check_Bank" == "y" ]; then
	#echo
	BMC_bank=""$name"/BMC_Bank"
	BIOS_bank=""$name"/BIOS_Bank"
	while true
	do        
		ipmitool -I lanplus -H $ip -U $user -P $password raw 0x32 0x8f 0x02 > $BMC_bank/BMC_Bank_$i.log && ipmitool -I lanplus -H $ip -U $user -P $password raw 0x36 0x79 0x2a 0x6f 0x00 0x02 > $BIOS_bank/BIOS_Bank_$i.log
		if [ "$?" == 0 ]; then
			break
		else
			sleep 1
		fi
	done
	
	if [ "$i" == 1 ]; then
		cp $BMC_bank/BMC_Bank_$i.log $BMC_bank/BMC_Bank_Golden_Sample.log
		cp $BIOS_bank/BIOS_Bank_$i.log $BIOS_bank/BIOS_Bank_Golden_Sample.log
	else
		echo "=============== "$i" ===============" >  $BMC_bank/BMC_Bank_fail_tmp_1.log
		echo " " >>  $BMC_bank/BMC_Bank_fail_tmp_1.log
		diff $BMC_bank/BMC_Bank_Golden_Sample.log $BMC_bank/BMC_Bank_$i.log >  $BMC_bank/BMC_Bank_fail_tmp_2.log
		if [ -s  $BMC_bank/BMC_Bank_fail_tmp_2.log ]; then
			cat  $BMC_bank/BMC_Bank_fail_tmp_2.log >> $BMC_bank/BMC_Bank_fail_tmp_1.log
			echo "error" >>  $BMC_bank/BMC_Bank_fail_tmp_1.log
			echo " " >>  $BMC_bank/BMC_Bank_fail_tmp_1.log
		else
			sleep 1
		fi
		cat $BMC_bank/BMC_Bank_fail_tmp_1.log | grep "error" > /dev/null
		if [ "$?" == 0 ]; then
			sed -i '/error/d' $BMC_bank/BMC_Bank_fail_tmp_1.log
			cat $BMC_bank/BMC_Bank_fail_tmp_1.log  >> "$name"/BMC_Bank_fail.log
			#echo 
			echo -e ${RED}
			echo "Detected BMC bank switched at loop: $i."
			#echo
			echo -e ${GREEN}
		else
			echo
			bank=$(cat $BMC_bank/BMC_Bank_$i.log)
			echo "BMC bank boot from: $bank"	
		fi
	rm -f $BMC_bank/BMC_Bank_fail_tmp_1.log
	rm -f $BMC_bank/BMC_Bank_fail_tmp_2.log



	
		echo "=============== "$i" ===============" >  $BIOS_bank/BIOS_Bank_fail_tmp_1.log
		echo " " >>  $BIOS_bank/BIOS_Bank_fail_tmp_1.log
		diff $BIOS_bank/BIOS_Bank_Golden_Sample.log $BIOS_bank/BIOS_Bank_$i.log >  $BIOS_bank/BIOS_Bank_fail_tmp_2.log
		if [ -s  $BIOS_bank/BIOS_Bank_fail_tmp_2.log ]; then
			cat  $BIOS_bank/BIOS_Bank_fail_tmp_2.log >> $BIOS_bank/BIOS_Bank_fail_tmp_1.log
			echo "error" >>  $BIOS_bank/BIOS_Bank_fail_tmp_1.log
			echo " " >>  $BIOS_bank/BIOS_Bank_fail_tmp_1.log
		else
			sleep 1
		fi
		cat $BIOS_bank/BIOS_Bank_fail_tmp_1.log | grep "error" > /dev/null
		if [ "$?" == 0 ]; then
			sed -i '/error/d' $BIOS_bank/BIOS_Bank_fail_tmp_1.log
			cat $BIOS_bank/BIOS_Bank_fail_tmp_1.log  >> "$name"/BIOS_Bank_fail.log
			#echo 
			echo -e ${RED}
			echo "Detected BIOS bank switched at loop: $i."
			#echo
			echo -e ${GREEN}
		else
			#echo
			bank=$(cat $BIOS_bank/BIOS_Bank_$i.log)
			echo "BIOS bank boot from: $bank"
			#echo
		
		fi
	rm -f $BIOS_bank/BIOS_Bank_fail_tmp_1.log
	rm -f $BIOS_bank/BIOS_Bank_fail_tmp_2.log

	fi
fi
echo
}

Remote_Check_version(){
if [ "$Check_Version" == "y" ]; then
	version_path=""$name"/Version"
	redfish_counter=0
	while true
	do
	redfishtool -r $ip -u $user -p $password -S Always raw GET /redfish/v1/UpdateService/FirmwareInventory/ | grep -i "/redfish/v1/UpdateService/FirmwareInventory/" | grep -i "BIOS\|BMC\|CPLD\|SWITCH"> $version_path/firmware_version_layer1.log
	cat $version_path/firmware_version_layer1.log | grep "UpdateService" > /dev/null
	if [ "$?" == 0 ]; then
		break
	else
		echo -n -e "."
		sleep 2
		if [ "$redfish_counter" == 5 ]; then
		echo "redfish service don't work"		
			break
		fi
	let "redfish_counter=$redfish_counter+1"
	
	fi
	done

	cat $version_path/firmware_version_layer1.log | grep -i "/redfish/v1/UpdateService/FirmwareInventory/" | awk -F "\"" '{print $4}' > $version_path/firmware_version_layer2.log
	while read ver_line
	do
	echo "" > $version_path/version_tmp.log 
	redfishtool -r $ip -u $user -p $password -S Always raw GET $ver_line | grep -i version -B 3 >> $version_path/version_tmp.log 
	echo "" >> $version_path/version_tmp.log 
	cat $version_path/version_tmp.log >> $version_path/version_$i.log
	done < $version_path/firmware_version_layer2.log

	if [ "$i" == 1 ]; then
		cp $version_path/version_$i.log $version_path/version_golden_sample.log
	else

		diff $version_path/version_golden_sample.log $version_path/version_$i.log > $version_path/version_fail_tmp.log
		if [ "$?" == 1 ]; then
			echo -e ${RED}
			echo "Get firmware version fail at loop: $i " >> $version_path/version_fail.log
			echo -e ${GREEN}
			cat $version_path/version_$i.log >> $version_path/version_fail.log
			cat $version_path/version_fail_tmp.log
		else
			echo "Firmware version :"
			cat $version_path/version_$i.log
		fi

	fi
fi
}


function system_event_log_analysis(){
#if [ "$1" == "" ];then
#	echo "Usage: ./dmesg_log_analysis.sh /root/Desktop/XX_test_logs "
#	exit 0
#fi

cat "$name"/BMC_SEL/BMC_event_$i.log | grep "Detail" -B 100 | sed '/Detail/d' > "$name"/BMC_SEL/BMC_event_analysis_$i.log
echo "-------------------------------------------------------------------------------------------------
Counter |                                 events 
-------------------------------------------------------------------------------------------------"
grep -v "OEM record" "$name"/BMC_SEL/BMC_event_analysis_*.log | cut -d "|" -f 4- | sort | uniq -c

grep "OEM record" "$name"/BMC_SEL/BMC_event_analysis_*.log | cut -d "|" -f 2- | sort | uniq -c

}


Remote_Check_SEL(){



	###################################################################################################

	echo
	echo
	echo "Check "$name" SEL"
	echo
	while true
	do        
	ipmitool -I lanplus -H $ip -U $user -P $password sel elist > "$name"/BMC_SEL/BMC_event_$i.log
	if [ "$?" == 0 ]; then
		cp "$name"/BMC_SEL/BMC_event_$i.log "$name"/BMC_SEL/Golden_Sample_SEL_bak.log
		break
	else
		sleep 1
	fi
	done
	echo
		cat "$name"/BMC_SEL/BMC_event_$i.log
	echo
	echo
	cp "$name"/BMC_SEL/BMC_event_$i.log "$name"/BMC_SEL/BMC_event_analysis_$i.log
	{
	echo "-------------------------------------------------------------------------------------------------
	Counter |                                 events 
-------------------------------------------------------------------------------------------------"
	grep -v "OEM record" "$name"/BMC_SEL/BMC_event_analysis_*.log | cut -d "|" -f 4- | sort | uniq -c
	grep "OEM record" "$name"/BMC_SEL/BMC_event_analysis_*.log | cut -d "|" -f 2- | sort | uniq -c
	} > "$name"/BMC_SEL/All_SEL_analysis.log
	cat "$name"/BMC_SEL/All_SEL_analysis.log
	echo
	###################################################################################################
if [ "$Check_SEL" == y ]; then
	if [ "$i" == 1 ]; then
		
		cat "$name"/BMC_SEL/BMC_event_$i.log | awk -F " " '{print $1}' > "$name"/BMC_SEL/sel_number.log
		echo "" >> "$name"/BMC_SEL/BMC_event_$i.log
		echo "=============== Detail event analysis ===============" >> "$name"/BMC_SEL/BMC_event_$i.log
		echo "" >> "$name"/BMC_SEL/BMC_event_$i.log
		while read sel_line
		do
			ipmitool -I lanplus -H $ip -U $user -P $password sel get 0x$sel_line  >> "$name"/BMC_SEL/BMC_event_$i.log
		done < "$name"/BMC_SEL/sel_number.log
		rm -f "$name"/BMC_SEL/sel_number.log
		
		cat "$name"/BMC_SEL/BMC_event_$i.log
		#cat $hang_folder/boot.log | grep -i new > /dev/null
		#if [ "$?" == 0 ]; then
		read -p "Please check the 1st loop SEL, if no question the SEL will be the Golden SEL Sample(y/n): " golden_sel
		if [ "$golden_sel" == y ]; then
			echo $golden_sel > "$name"/chk_sel_sample.log
			cp "$name"/BMC_SEL/Golden_Sample_SEL_bak.log "$name"/BMC_SEL/Golden_Sample_SEL.log
		#	else
		#		exit
		#	fi
		else
			echo "Abnormal Boot event log in $hang_folder/Boot_error" 
		fi
	else
		echo " " >  "$name"/BMC_SEL/BMC_sel_fail_tmp.log
		echo "=============== "$i" ===============" >>  "$name"/BMC_SEL/BMC_sel_fail_tmp.log
		echo " " >>  "$name"/BMC_SEL/BMC_sel_fail_tmp.log
		echo "Event Status: " >  "$name"/BMC_SEL/BMC_sel_abnormal_tmp.log 
		while read sel_check		
		do
			sel_number=$(echo $sel_check | awk -F "|" '{print $1}')
			sel_content_1=$(echo $sel_check | awk -F "|" '{print $4}')
			sel_content_2=$(echo $sel_check | awk -F "|" '{print $5}')
			
			grep "$sel_content_1" "$name"/BMC_SEL/Golden_Sample_SEL.log > /dev/null && grep "$sel_content_2" "$name"/BMC_SEL/Golden_Sample_SEL.log > /dev/null
			if [ "$?" != 0 ]; then
			echo "Abnormal event found" >>  "$name"/BMC_SEL/BMC_sel_abnormal_tmp.log
			#echo ""$sel_number" status=error" >>  BMC_SEL/BMC_sel_fail_tmp.log
			#echo " " >>  BMC_SEL/BMC_sel_fail_tmp.log
			#cat BMC_SEL/BMC_event_$i.log | grep "$sel_number" | grep "$sel_content"
			echo "$sel_check" >>  "$name"/BMC_SEL/BMC_sel_fail_tmp.log
			fi
		done < "$name"/BMC_SEL/BMC_event_$i.log
		cat "$name"/BMC_SEL/BMC_sel_fail_tmp.log  >> "$name"/BMC_SEL/BMC_sel_fail.log
		grep -i abnormal "$name"/BMC_SEL/BMC_sel_abnormal_tmp.log > /dev/null
		if [ "$?" == 0 ]; then
			echo 
			echo -e ${RED}
			echo "Detected the extra event in SEL at loop: $i."
			echo
				cat "$name"/BMC_SEL/BMC_sel_fail_tmp.log
			echo
			echo -e ${GREEN}
		else
			echo 
			echo "There is no extra event in SEL."
			echo
			#cat "$name"/BMC_SEL/BMC_event_$i.log
			echo
		fi
		rm -f "$name"/BMC_SEL/BMC_sel_abnormal_tmp_1.log
		
		cat "$name"/BMC_SEL/BMC_event_$i.log | awk -F " " '{print $1}' > "$name"/BMC_SEL/sel_number.log
		echo "" >> "$name"/BMC_SEL/BMC_event_$i.log
		echo "=============== Detail event analysis ===============" >> "$name"/BMC_SEL/BMC_event_$i.log
		echo "" >> "$name"/BMC_SEL/BMC_event_$i.log
		while read sel_check_line
		do
			ipmitool -I lanplus -H $ip -U $user -P $password sel get 0x$sel_check_line  >> "$name"/BMC_SEL/BMC_event_$i.log
		done < "$name"/BMC_SEL/sel_number.log
		rm -f "$name"/BMC_SEL/sel_number.log
	fi
	echo
	
	
else	
		
		echo
		
		echo "No Golden Sample SEL Checked" > "$name"/chk_sel_sample.log
		echo
fi
echo
	###################################################################################################
}

Record_resful_HW_device_scan(){
if [ "$Check_Restful" == "y" ]; then



echo
#cat configuration > Get_Restful_info_tmp.sh
#cat Get_Restful_info.sh >> Get_Restful_info_tmp.sh
#chmod 777 Get_Restful_info_tmp.sh
#./Get_Restful_info_tmp.sh
if [ "$i" == 1 ]; then
	cat $line > Get_Restful_info_tmp.sh
	#cat configuration > Get_Restful_info_tmp.sh
	cat restful_storage_info.sh >> Get_Restful_info_tmp.sh
	chmod 777 Get_Restful_info_tmp.sh
	if [ -f "Get_Restful_storage_info_tmp.sh" ]; then
		rm -f Get_Restful_storage_info_tmp.sh
	fi
	cp Get_Restful_info_tmp.sh Get_Restful_storage_info_tmp.sh
	chmod 777 Get_Restful_storage_info_tmp.sh
	./Get_Restful_storage_info_tmp.sh > "$name"/Restful/Storage_info_tmp.log
	cat "$name"/Restful/Storage_info_tmp.log | tail -1 | jq > "$name"/Restful/Storage_info_$i.log
	cp "$name"/Restful/Storage_info_$i.log "$name"/Restful/Storage_info_Golden_Sample.log
	cat $line > Get_Restful_info_tmp.sh
	cat restful_pcie_info.sh >> Get_Restful_info_tmp.sh
	chmod 777 Get_Restful_info_tmp.sh
	if [ -f "Get_Restful_pcie_info_tmp.sh" ]; then
		rm -f Get_Restful_pcie_info_tmp.sh
	fi
	cp Get_Restful_info_tmp.sh Get_Restful_pcie_info_tmp.sh
	chmod 777 Get_Restful_pcie_info_tmp.sh
	./Get_Restful_pcie_info_tmp.sh > "$name"/Restful/PCIe_info_tmp.log
	cat "$name"/Restful/PCIe_info_tmp.log | tail -1 | jq > "$name"/Restful/PCIe_info_$i.log
	cp "$name"/Restful/PCIe_info_$i.log "$name"/Restful/PCIe_info_Golden_Sample.log
	echo
else

	
	./Get_Restful_storage_info_tmp.sh > "$name"/Restful/Storage_info_tmp.log
	cat "$name"/Restful/Storage_info_tmp.log | tail -1 | jq > "$name"/Restful/Storage_info_$i.log
	./Get_Restful_pcie_info_tmp.sh > "$name"/Restful/PCIe_info_tmp.log
	cat "$name"/Restful/PCIe_info_tmp.log | tail -1 | jq > "$name"/Restful/PCIe_info_$i.log
	echo

	#echo "=============== "$i" ===============" >  Restful/Restful_fail_tmp_1.log
	#echo " " >>  Restful/Restful_fail_tmp_1.log
##############################################################

if [ -f ""$name"/Restful/Storage_info_fail_tmp.log" ]; then
	rm -f "$name"/Restful/Storage_info_fail_tmp.log
fi
target_file=""$name"/Restful/Storage_info_$i.log"
sed -i 's/\]//g' $target_file
sed -i 's/\[//g' $target_file
sed -i 's/}//g' $target_file
sed -i 's/{//g' $target_file
while read restful_storage
do
#echo $line
if [ "$restful_storage" == "" ]; then
	continue
else	
	grep "$restful_storage" "$name"/Restful/Storage_info_Golden_Sample.log > /dev/null
	if [ "$?" == 1 ]; then
			
		echo "Storage: $restful_storage info error" >> "$name"/Restful/Storage_info_fail_tmp.log
		
	else
		continue
	fi
	
fi
done < $target_file
##############################################################
	if [ ! -f ""$name"/Restful/Storage_info_fail_tmp.log" ]; then
		#cat Restful/Storage_info_fail_tmp.log | grep -i error
		#if [ "$?" == 1 ]; then
		echo "Storage information check OK."
	else
		echo "Storage info compare failed"
		echo "=============== "$i" ===============" >> "$name"/Restful/Storage_fail.log
		cat "$name"/Restful/Storage_info_fail_tmp.log >> "$name"/Restful/Storage_fail.log
		echo " " >> "$name"/Restful/Storage_fail.log
		#echo "Detected Storage info error at loop: $boot."
		#cat "$pwd"BMC/Restful/Storage_fail.log >> "$pwd"Restful_Storage_fail.log
	fi
	echo

##############################################################

if [ -f ""$name"/Restful/PCIe_info_fail_tmp.log" ]; then
	rm -f "$name"/Restful/PCIe_info_fail_tmp.log
fi
target_file=""$name"/Restful/PCIe_info_$i.log"
sed -i 's/\]//g' $target_file
sed -i 's/\[//g' $target_file
sed -i 's/}//g' $target_file
sed -i 's/{//g' $target_file
while read restful_pcie
do
#echo $line
if [ "$restful_pcie" == "" ]; then
	continue
else	
	grep "$restful_pcie" "$name"/Restful/PCIe_info_Golden_Sample.log > /dev/null
	if [ "$?" == 1 ]; then
			
		echo "PCIe: $restful_pcie info error" >> "$name"/Restful/PCIe_info_fail_tmp.log
		
	else
		continue
	fi
	
fi
done < $target_file
##############################################################




	if [ ! -f ""$name"/Restful/PCIe_info_fail_tmp.log" ]; then
		#cat Restful/PCIe_info_fail_tmp.log | grep -i error
		#if [ "$?" == 1 ]; then
		echo "PCIe informtion check OK."
	else
		echo "PCIeDevice info compare failed"
		echo "=============== "$i" ===============" >> "$name"/Restful/PCIe_fail.log
		cat "$name"/Restful/PCIe_info_fail_tmp.log >> "$name"/Restful/PCIe_fail.log
		echo " " >> "$name"/Restful/PCIe_fail.log
		#echo "Detected PCIe info error at loop: $boot."
		#cat "$pwd"BMC/Restful/PCIe_fail.log >> "$pwd"Restful_PCIe_fail.log
	fi

fi
echo
fi
}


send_shutdown_event(){
echo
echo "Send test event to power off "$name" System"
echo
while true
do
ipmitool -I lanplus -H $ip -U $user -P $password  raw 0x0a 0x44 0xff 0xff 0x02 0x00 0x00 0x00 0x00 0x87 0x00 0x02 0x1f 0x87 0x03 0x51 0x54 0x43 > /dev/null
if [ "$?" == 0 ]; then
	echo ""$name" System will shutdown within 60 seconds."
	break
else
	echo -n -e "." 
	sleep 2
fi
done
echo

}

send_reboot_event(){
echo
echo "Send test event to reboot System"
echo
while true
do
ipmitool -I lanplus -H $ip -U $user -P $password  raw 0x0a 0x44 0xff 0xff 0x02 0x00 0x00 0x00 0x00 0x87 0x00 0x02 0x1f 0x88 0x03 0x51 0x54 0x43 > /dev/null
if [ "$?" == 0 ]; then
	echo ""$name" System System will reboot within 60 seconds."
	break
else
	echo -n -e "." 
	sleep 2
fi
done
echo

}
wait_system_off(){

echo
echo "Wait for "$name" System power off."
echo
while true
do
ipmitool -I lanplus -H $ip -U $user -P $password chassis power status > "$name"/system_status.log
cat "$name"/system_status.log | grep -i off
if [ "$?" == 0 ]; then
	echo
	echo ""$name" System in power off mode"
	echo
	break
else
	echo -n -e "." 
	sleep 2
fi
done
echo
}


finish_AC(){

	#echo
	#echo "Check BMC is ready to access"
	#echo	
	i_BMC=0
	while [ "$i_BMC" = 0 ]
	do
	ipmitool -I lanplus -H $ip -U $user -P $password mc info 2>/dev/null 1 > "$name"/ready.log
	i_BMC=$(cat "$name"/ready.log | grep -i version -c)
	echo -n -e "."
	sleep 1
		if [ "$i_BMC" == 180 ]; then
			echo "No. $i testing cycle, BMC maybe hang up because of BMC has no any response within 180 seconds." >> $hang_folder/"$PJN"_BMC_hang.log
			echo
				
		fi
	done
	#cat ready.log | head -3
	echo
	# ---------- check the system is on or off --------------
	SystemPowerStatus
	if [ "$SystemStatus" == "Chassis Power is off" ];then
		SystemPowerOn
		#sleep $ACONtoPOST
		#sleep $POSTtoOS
	fi
	# -------------------------------------------------------
}

Always_off(){
# ---------------------------------------------------
while true
do
	ipmitool -I lanplus -H $ip -U $user -P $password chassis policy always-off 
	if [ "$?" == 0 ]; then
		break
	else
		echo -n -e "."
		sleep 1
	fi
done
# ---------------------------------------------------
}



Always_on(){
# ---------------------------------------------------
while true
do
	ipmitool -I lanplus -H $ip -U $user -P $password chassis policy always-on 
	if [ "$?" == 0 ]; then
		break
	else
		echo -n -e "."
		sleep 1
	fi
done
# ---------------------------------------------------
}
delay_counter(){
echo
echo "DC off delay for $1 seconds"
echo
	date
dc_counter=0
while [ $dc_counter != $1 ]
do
	echo -n -e "."
	sleep 1
	let "dc_counter=$dc_counter+1"
done
echo
	date
echo
}
###################################################################################################
file_backup() {

for line in $(cat target.txt)
do
#cat $iconfig
name=$(echo $line | awk -F "." '{print $1}')
folder_ip=$(cat $line | grep ip | awk -F "=" '{print $2}')


rm -rf "$name"_"$folder_ip"_"$test_method"

cp -r "$name" "$name"_"$folder_ip"_"$test_method"
cp Test_info.cfg "$name"_"$folder_ip"_"$test_method"/
cp configuration "$name"_"$folder_ip"_"$test_method"/
echo
echo "Stress logs and configuration are saved in "$name"_"$folder_ip"_"$test_method""
echo


done
}


###################################################################################################


if [ -f ""$PJN"_AC_power_on_time.log" ]; then
	rm -f "$PJN"_AC_power_on_time.log
fi

if [ -f ""$PJN"_DC_power_on_time.log" ]; then
	rm -f "$PJN"_DC_power_on_time.log
fi


if [ -f "BMC_Boot_time.log" ]; then
	rm -f BMC_Boot_time.log
fi

if [ -f "OS_Boot_time.log" ]; then
	rm -f OS_Boot_time.log
fi

function AC_test(){
echo "Test Method: "$test_method"" >> Test_info.cfg
cat configuration | grep "sled=" > bmcs.txt
echo 1 > test.cfg
rm -f *.cfg
echo 1 > sled_status.txt
rm -f sled_status.txt
while read line
do
	number=$(echo $line | awk -F "=" '{print $2}')
#	echo $number
#	echo "cat configuration | grep "sled=$number" -A 3 > sled_$number.cfg"
	cat configuration | grep "sled=$number" -A 3 > sled_$number.cfg

done < bmcs.txt

ls *.cfg > target.txt

## create the parameter
Colorful_script
Test_mode
Set_duration
#Set_BMC
Set_PDU
start_go

echo -e ${GREEN}
sleep 1

echo -e ${GREEN}
ACONtoPOST=30   #BMC網路起動到POST的時間
POSTtoOS=60  #POST到OS的時間

sleep 1 
for line in $(cat target.txt)
do
. $line
name=$(echo $line | awk -F "." '{print $1}')
#send_shutdown_event
echo "new boot" > $hang_folder/boot.log
# ---------------------------------------------------

JBOD_Always_on

Always_off

wait_system_off



# ---------------------------------------------------
#

#for line in $(cat target.txt)

done 

PDUConnection
sleep 1
PDUPlugStatus
sleep 1
#Check_PDU_is_OFF
PDUPlugOff
sleep 1
PDUPlugOff_JBOD
sleep 1
PDUPlugStatus
sleep 1
Check_PDU_is_OFF
sleep 1
Check_PDU_is_OFF_JBOD
sleep 1
PDUPlugStatus
echo
	date "+%Y-%m-%d %T"
echo
echo "AC Power off $ac_failure_time sec!"
echo
time_count=1
while [ $ac_failure_time -gt $time_count ]
	#sleep $ac_failure_time
	do
	
	res=$(($time_count%10))
	#echo $res
	if [ "$res" == 0 ]; then
		echo -n -e "$time_count"
	else
		echo -n -e "."
	fi
	sleep 1
	let "time_count=$time_count+1"
	
done
echo
echo
	date "+%Y-%m-%d %T"
echo
# ---------- record the time of start ---------------
echo $(($(date +%s)+$TESTTIME)) > /root/AC_FINISH_TIME
FTIME=`cat /root/AC_FINISH_TIME`
# ---------------------------------------------------

# -------------------------------- Start AC cycling ---------------------------------------- #
for((i=$start_condition;i<=1100;i++))
do
echo $i > loop_count.txt
#======================================================================================================1	
	# ---------- check the testing time or cycles ----------
	## time base
	NTIME=`date +%s`
	if [ "$NTIME" -ge "$FTIME" ];then
		echo -e ${NC}
		echo
		echo "AC cycling test has been finished."
		echo
		PDUPlugOn
		PDUPlugOn_JBOD
		if [ "$JBOD" == "y" ];then
			echo
			echo "Check JBOD BMC is ready to access"
			echo
			i_JBOD=0
			i_count=0
			while [ "$i_JBOD" = 0 ]
			do
			
			ipmitool -I lanplus -H $JBOD_ip -U $JBOD_user -P $JBOD_password mc info 2>/dev/null 1> JBOD_ready.log
			i_JBOD=$(cat JBOD_ready.log | grep -i version -c)
			echo -n -e "."
			sleep 1
				let "i_count=$i_count+1"
				if [ "$i_count" == 180 ]; then
					echo "No. $i testing cycle, JBOD-BMC maybe hang up because of BMC has no any response within 180 seconds." >> /root/Desktop/"$PJN"_JBOD_BMC_hang.log
					echo
							
				fi
			done
			echo
				cat JBOD_ready.log | grep -i "Firmware Revision"
			echo ""
			echo "JBOD BMC is ready"
			echo ""
			Check_JBOD_power_on
		fi
			
		echo
		for line in $(cat target.txt)
		do
			#echo $line
			. $line
			name=$(echo $line | awk -F "." '{print $1}')
			echo $name
			finish_AC
		#for line in $(cat target.txt)
		done
		echo
		file_backup
		exit 0
	fi
#======================================================================================================1
#======================================================================================================2
	## cycle base
	if [ "$i" -ge "$CTC" ];then
		echo -e ${NC}
		echo
		echo "AC cycling test has been finished."
		echo
		PDUPlugOn
		PDUPlugOn_JBOD
		if [ "$JBOD" == "y" ];then
			echo
			echo "Check JBOD BMC is ready to access"
			echo
			i_JBOD=0
			i_count=0
			while [ "$i_JBOD" = 0 ]
			do
			
			ipmitool -I lanplus -H $JBOD_ip -U $JBOD_user -P $JBOD_password mc info 2>/dev/null 1> JBOD_ready.log
			i_JBOD=$(cat JBOD_ready.log | grep -i version -c)
			echo -n -e "."
			sleep 1
				let "i_count=$i_count+1"
				if [ "$i_count" == 180 ]; then
					echo "No. $i testing cycle, JBOD-BMC maybe hang up because of BMC has no any response within 180 seconds." >> /root/Desktop/"$PJN"_JBOD_BMC_hang.log
					echo
							
				fi
			done
			echo
				cat JBOD_ready.log | grep -i "Firmware Revision"
			echo ""
			echo "JBOD BMC is ready"
			echo ""
			Check_JBOD_power_on
		fi
			
		echo
		for line in $(cat target.txt)
		do
			#echo $line
			. $line
			name=$(echo $line | awk -F "." '{print $1}')
			echo $name
			finish_AC
		#for line in $(cat target.txt)
		done 
		echo		
		file_backup
		exit 0

	fi
	# ------------------------------------------------------
#======================================================================================================2
	# ---------- Power on the PDU plug --------------------- 
	until [ "$PDU1" == "$POS" ]
	do
		
		PDUPlugOn
		sleep 3
		PDUPlugOn_JBOD
		sleep 3
		PDUPlugStatus  #將變數PDU改為ON
		sleep 3
	done
	# ------------------------------------------------------
	echo
		date "+%Y-%m-%d %T" 2>&1 | tee BMC_boot_time_start.log
	echo
	echo
	echo "***** Power on UUT & Test No.$i *****" 2>&1 | tee loop_cycle.log
	echo
	echo "PDU power on."
	echo
	echo "No.$i" >> "$PJN"_AC_power_on_time.log ;date >> "$PJN"_AC_power_on_time.log  #記錄每次開機時間
#======================================================================================================3
	for line in $(cat target.txt)
	do
	#echo $line
	. $line
	name=$(echo $line | awk -F "." '{print $1}')
	ct=1
	bt=1
	# ---------- check the BMC network connection ----------
	BMCPING="" 
	echo
	echo
	echo "Wait for $name BMC booting completed"
	echo
	echo
	echo "OK" > BMC_boot.error
	#rm -f BMC_boot.error
	#PDUPlugStatus
	#bmc_number=$(cat target.txt | wc -l)
	#bmc_boot=$((50/$bmc_number))
	bmc_boot=180
	#echo $bmc_boot
	while [ "$BMCPING" == "" ]  # 只要BMCPING的變數值為空白就執行迴圈
	do
		#date
		
		#res_bmc=$(($bt%10))
		#if [ "$res_bmc" == 0 ]; then
		#	echo -n -e "$(($bt*1))"
		#else
			echo -n -e "."
		#fi
		let "bt = $bt + 1"
		sleep 1
	
		BMCPING=`ping $ip -c 1 | grep ttl`
		if [ $bt -gt $bmc_boot ]; then  #設置等待時間為180秒
			echo
			PDUPlugStatus
			echo "No. $i testing cycle, cannot connect to BMC network.
			      Therefore, AC power off the UUT via remote side." >> $name/Boot_error/"$PJN"_AC_power_on_hang_$name.log
			echo		
			#echo $PDU1
			
			while [ "$PDU1" == "Status: ON" ]
			do
				
				echo "Cannot connect to BMC network ，AC off the system."
				PDUPlugOff
				sleep 3
				PDUPlugOff_JBOD
				sleep 3
				PDUPlugStatus  #將$PDU改為OFF
				sleep 3
			done
			echo "BMC boot fail" > BMC_boot.error
			BMCPING=1  #跳脫BMC迴圈
		fi
		#PDUPlugStatus
		
	done
	cat BMC_boot.error | grep -i fail > /dev/null
	if [ "$?" == 0 ]; then
		break
	fi
	#for line in $(cat target.txt)
	done 
	echo
	
	#PDUPlugStatus
	cat BMC_boot.error | grep -i fail > /dev/null
	if [ "$?" == 0 ]; then
		
		echo	
			cat BMC_boot.error
		echo
	else
	#======================================================================================================3
		echo
			date "+%Y-%m-%d %T" 2>&1 | tee BMC_boot_time_end.log
		echo	
	# -------------------------------------------------------
		bmc_start=$(cat BMC_boot_time_start.log)
		bmc_end=$(cat BMC_boot_time_end.log)
		#echo "BMC boot start:$bmc_start"
		#echo "BMC end end:$bmc_end"
		BMC_boots_time=$(($(date -d "$bmc_end" +%s)-$(date -d "$bmc_start" +%s))) 
		cat loop_cycle.log >> BMC_Boot_time.log
		echo "BMC boots time: $BMC_boots_time seconds" 2>&1 | tee BMC_Boot_time_tmp.log
		echo
		cat BMC_Boot_time_tmp.log >> BMC_Boot_time.log
	#======================================================================================================4
		for line in $(cat target.txt)
		do
		#echo $line
		. $line
		name=$(echo $line | awk -F "." '{print $1}')
		echo
		echo "Check $name BMC is ready to access"
		echo	
		bmc_number=$(cat target.txt | wc -l)
		bmc_boot=$((30/$bmc_number))
		i_BMC=0
		while [ "$i_BMC" = 0 ]
		do
		ipmitool -I lanplus -H $ip -U $user -P $password mc info 2>/dev/null 1 > BMC_ready.log
		i_BMC=$(cat BMC_ready.log | grep -i version -c)
		echo -n -e "."
		sleep 1
		let "i_BMC=$i_BMC+1"
			if [ $i_BMC -gt $bmc_boot  ]; then
				echo "No. $i testing cycle, BMC maybe hang up because of BMC has no any response within 180 seconds." >> $hang_folder/"$PJN"_BMC_hang_$name.log
				echo
				
			fi
		done
		echo
		major_version=$(cat BMC_ready.log | grep "Firmware Revision" | awk -F ":" '{print $2}')
		revision_version=$(cat BMC_ready.log | grep "Aux Firmware Rev Info" -A 1 | tail -1 | awk -F "0x" '{print $2}')
		echo
		echo "BMC version: $major_version.$revision_version"
		echo
		
	# ---------- check the system is on or off --------------
		SystemPowerStatus
		if [ "$SystemStatus" == "Chassis Power is off" ];then
			
			SystemPowerOn
			#echo ON
		fi
	# -------------------------------------------------------
		#for line in $(cat target.txt)
		done 
	echo
		date "+%Y-%m-%d %T" 2>&1 | tee OS_boot_time_start.log
	echo

	if [ "$JBOD" == "y" ];then
		echo
		echo "Check JBOD BMC is ready to access"
		echo
		i_JBOD=0
		i_count=0
		while [ "$i_JBOD" = 0 ]
		do
		
		ipmitool -I lanplus -H $JBOD_ip -U $JBOD_user -P $JBOD_password mc info 2>/dev/null 1> JBOD_ready.log
		i_JBOD=$(cat JBOD_ready.log | grep -i version -c)
		echo -n -e "."
		sleep 1
			let "i_count=$i_count+1"
			if [ "$i_count" == 180 ]; then
				echo "No. $i testing cycle, JBOD-BMC maybe hang up because of BMC has no any response within 180 seconds." >> /root/Desktop/"$PJN"_JBOD_BMC_hang.log
				echo
					
			fi
		done
		echo
			cat JBOD_ready.log | grep -i "Firmware Revision"
		echo ""
		echo "JBOD BMC is ready"
		echo ""
		Check_JBOD_power_on
	fi
		
#======================================================================================================4
		
#======================================================================================================5
		echo
		echo "Wait for booting into OS"
		echo
	fi
	ct=1
	while [ "$PDU1" == "$POS" ]  #當插座是通電狀態下就執行以下程式
	#while true
	do
		
		# 當開機狀態下達到600秒就強制斷電
		#date
		#echo wait_boot:$wait_boot_time
		#cct=$(($ct*3))
		#echo $cct
		#if [ $cct -gt $wait_boot_time ]; then
		if [ $ct -gt $wait_boot_time ]; then
			
			if [ "$TESTMODE" == "Debug test" ];then
				echo "No. $i testing cycle, the UUT test failed."
				exit 0
			else
				
				for line in $(cat target.txt)
				do
				echo "abnormal boot" > $hang_folder/boot.log
				. $line
				name=$(echo $line | awk -F "." '{print $1}')
				echo "No. $i testing cycle, the system cannot boot to OS within 10 mins. 
			      Therefore, AC power off the UUT via remote side." | tee -a $hang_folder/"$PJN"_AC_power_on_hang_$name.log
				
				ipmitool -I lanplus -H $ip -U $user -P $password sel elist 2>&1 | tee -a $hang_folder/boot_sel_over10mins_$name-loop_$i.log
				sleep 2
				echo
				#echo "OS boot timeout, force AC OFF within 30 seconds."
				Remote_Check_version
				#echo "line-1178"
				Remote_Check_SEL
				ClearSEL
				if [ -f sled_status.txt ]; then
					rm -f sled_status.txt
				fi
				echo "new boot" > $hang_folder/boot.log
				#for line in $(cat target.txt)
				done 
				while [ "$PDU1" == "$POS" ] 
				do
					PDUPlugOff
					sleep 3
					PDUPlugStatus
					sleep 3
					#echo "line-1189"
					break
				done
			fi
		# 未超過600秒執行以下scrpit
		else
			#echo 1 > sled_status.txt
			#rm -f sled_status.txt
			#ct=$((ct+10))  #10秒偵測一次PDU狀態
			for line in $(cat target.txt)
			do
			#echo "1: $line"
			. $line
			name=$(echo $line | awk -F "." '{print $1}')
			target_ip=$(cat $line | grep ip | awk -F "=" '{print $2}')
			GetSELKeyWord
		
			#res=$(($ct%10))
			#if [ "$res" == 0 ]; then
				
				#echo -n -e "$ct"
				
			#else
				echo -n -e "."
			#fi
			let "ct = $ct + 1"
			#echo
			#sleep 1
			#echo "2: $line"	
			# 當系統進入OS發出event 3後執行下列程式 
			if [ "$SEL1" != "" ];then
				echo
				#echo "3: $line"
				echo
				echo
					date "+%Y-%m-%d %T" 2>&1 | tee Event_time_end.log
				echo
				#echo "7: $line"
				# -------------------------------------------------------
				OS_start=$(cat OS_boot_time_start.log)
				OS_end=$(cat Event_time_end.log)
				#echo "BMC boot start:$bmc_start"
				#echo "BMC end end:$bmc_end"
				OS_boots_time=$(($(date -d "$OS_end" +%s)-$(date -d "$OS_start" +%s))) 
				echo
				echo "OS boots and script executed time: $OS_boots_time seconds" 2>&1 | tee OS_Boot_time_tmp.log		
				#echo "8: $line"
				echo
				cat loop_cycle.log >> OS_Boot_time.log
				cat OS_Boot_time_tmp.log >> OS_Boot_time.log
				# -------------------------------------------------------
				echo $name check
				#echo "9: $line"
				Record_resful_HW_device_scan
				#echo "10: $line"
				Remote_Check_BMC_BIOS_Bank
				#echo "11: $line"
				Remote_Check_version
				echo "Getting the system logs..."
				sleep 10  
				dt=1
				#echo "12: $line"
				SystemPowerStatus
				# 確認系統是否關機
				#############################################################################
				ipmitool -I lanplus -H $ip -U $user -P $password sel elist > force_AC.log
				force_ac_1=$(cat force_AC.log | grep "Platform Security #0xff" -c)
				force_ac_2=$(cat force_AC.log | grep "OS Boot #0xff" -c)
				##force_AC
				if [ "$force_ac_1" == 0 ] && [ "$force_ac_2" == 0 ]; then
				#############################################################################
					echo
					echo "Shut down the OS now, OS will power off within $shutdown_time seconds."
					echo
					#echo "4: $line"
					while [ "$SystemStatus" == "Chassis Power is on" ] 
					do	
						
						res=$(($dt%10))
						if [ "$res" == 0 ]; then
							echo -n -e "$dt" 
						else
							echo -n -e "."
						fi
						let "dt = $dt + 1"
						sleep 1
						SystemPowerStatus
						if [ "$dt" -gt "$shutdown_time" ] ; then
							if [ "$TESTMODE" == "Debug test" ]; then
								echo
								echo "No. $i testing cycle, the UUT test failed."
								echo
									exit 0
							fi
						
							echo
							echo
								date
							echo
							echo "No. $i testing cycle, cannot shut dwon the OS within 5 mins. 
						      Therefore, AC power off the UUT via remote side." | tee -a $hang_folder/"$PJN"_AC_power_off_hang_$name.log
							ipmitool -I lanplus -H $ip -U $user -P $password sel elist | tee -a $hang_folder/shutdown_over_5mins_SEL_$name-loop_$i.log
							sleep 2
							#echo "6: $line"
							ipmitool -I lanplus -H $ip -U $user -P $password power off
							sleep 10
							SystemPowerStatus
							
						fi
					done
				fi #force shoudown

				echo
				echo
				#echo "5: $line"
				#echo $line
				echo $line >> sled_status.txt
					Remote_Check_SEL
				echo
					#system_event_log_analysis 2>&1 | tee $name/BMC_SEL/All_SEL_analysis.log
				#cat $name/BMC_SEL/All_SEL_analysis.log				
				echo
				echo
				echo "Clear SEL"
				ClearSEL
				echo 
				#echo "gg"
				#cat sled_status.txt
				sleep 10
				
			fi
			#PDUPlugStatus
			#for line in $(cat target.txt)
			done 
		
			
		fi	
		if [ -f sled_status.txt ]; then
			iline=1
			while read line
			do
				grep "$line" target.txt > /dev/null			
				if [ "$?" == 0 ]; then
					echo $iline > check.txt	
				fi
				let "iline=$iline+1"
			done < sled_status.txt
			cat target.txt | wc -l  > original.txt
			diff original.txt check.txt  > /dev/null
			if [ "$?" == 0 ]; then
				rm -f sled_status.txt
				break
			fi
			
		fi
	done
				
				# ---------- PDU PLUG AC OFF --------------------
			
				while [ "$PDU1" == "$POS" ]
				do
					PDUPlugOff
					sleep 2
					PDUPlugOff_JBOD
					sleep 2
					PDUPlugStatus
					sleep 3				
				done
				# -----------------------------------------------
	
	echo
		echo "AC Power off $ac_failure_time sec! "
	echo
		date "+%Y-%m-%d %T" 2>&1 | tee AC_off_time_start.log
	echo
	time_count=1
	while [ $ac_failure_time -gt $time_count ]
	#sleep $ac_failure_time
	do
		res=$(($time_count%10))
		if [ "$res" == 0 ]; then
			echo -n -e "$time_count"
		else
			echo -n -e "."
		fi
		sleep 1
		let "time_count=$time_count+1"
	done
	echo
	echo
	# ---------- check the PDU network -------------------
	while [ "$PDU1" == "" ]  #確認是否有抓到PDU的狀態
	do
		PDUPlugStatus
		sleep 3
		echo "PDU connection error! reconnect..."
	done
	# ----------------------------------------------------
	echo
		date "+%Y-%m-%d %T"  2>&1 | tee  AC_off_time_end.log
	echo
	
done
}


function DC_test(){
echo "Test Method: "$test_method"" >> Test_info.cfg
## create the parameter
Colorful_script
Test_mode
Set_duration
#Set_BMC
start_go
echo -e ${GREEN}
#send_shutdown_event
wait_system_off
sleep 1
ClearSEL

##1. Check the UUT power status is OFF.
SystemPowerStatus
if [ "$SystemStatus" == "Chassis Power is on" ]; then
	echo "The UUT power status is ON, please DC off the UUT then restart this script!"
	echo -e ${NC}
	exit 0
fi

# record the time of start
FTIME=`echo $(($(date +%s)+$TESTTIME))`
echo
SystemPowerOn
echo
##2. Start the test

	
for((i=$start_condition;i<=1100;i++))
do
echo $i > "$name"/loop_count.txt
	## time base
	NTIME=`date +%s`
	if [ "$NTIME" -ge "$FTIME" ];then
		echo -e ${NC}
		echo	
		echo "DC cycling test has been finished."
		echo
		SystemPowerOn
		echo
		file_backup
			exit 0
	fi
	## cycle base
	if [ "$i" -ge "$CTC" ];then
		echo -e ${NC}
		echo
		echo "DC cycling test has been finished."
		echo
		SystemPowerOn
	    	echo
			file_backup
		exit 0
	fi
	##
	echo "***** Power on UUT & Test No.$i *****"  2>&1 | tee "$name"/loop_cycle.log
		
	date >> $hang_folder/"$PJN"_DC_power_on_time.log
	echo
	ct=1
	SystemPowerOn
	echo
		date "+%Y-%m-%d %T" 2>&1 | tee "$name"/OS_boot_time_start.log
	echo
	#sleep 45  #waiting for POST 
	SystemPowerStatus
	while [ "$SystemStatus" == "Chassis Power is on" ]
	do
		if [ "$ct" == "$wait_boot_time" ]; then 
			if [ "$TESTMODE" == "Debug test" ];then
				echo "No. $i testing cycle, the UUT test failed."
				exit 0
			else
				echo "No. $i testing cycle, the UUT power on over 10 mins. 
			      Therefore, DC power off the UUT via remote side." | tee -a $hang_folder/"$PJN"_DC_power_on_hang.log
				ipmitool -I lanplus -H $ip -U $user -P $password power off
				sleep 5
				SystemPowerStatus
			fi
		else
			
			GetSELKeyWord 
			
			
				#res=$(($ct%10))
				#if [ "$res" == 0 ]; then
				#	echo -n -e "$ct"
				#else
					echo -n -e "."
				#fi
				let "ct = $ct + 1"
				#sleep 1
				
				
			if [ "$SEL1" != "" ];then
				echo
					date "+%Y-%m-%d %T" 2>&1 | tee "$name"/Event_time_end.log
				echo
				
				OS_start=$(cat "$name"/OS_boot_time_start.log)
				OS_end=$(cat "$name"/Event_time_end.log)
				OS_boots_time=$(($(date -d "$OS_end" +%s)-$(date -d "$OS_start" +%s))) 
				#echo "***** Power on UUT & Test No. $i *****" > loop_cycle.log
				echo
				echo "OS boots and script executed time: $OS_boots_time seconds" 2>&1 | tee "$name"/OS_boot_time_tmp.log		
				echo
				
				cat "$name"/loop_cycle.log >> "$name"/OS_boot_time.log
				cat "$name"/OS_boot_time_start.log >> "$name"/OS_boot_time.log
				cat "$name"/OS_boot_time_tmp.log >> "$name"/OS_boot_time.log
				cat "$name"/Event_time_end.log >> "$name"/OS_boot_time.log
				echo "" >> "$name"/OS_boot_time.log

				sleep 3
				for line in $(cat target.txt)
				do
				#echo "1: $line"
				. $line
				name=$(echo $line | awk -F "." '{print $1}')
				folder_ip=$(cat $line | grep ip | awk -F "=" '{print $2}')
				Record_resful_HW_device_scan
				done
				Remote_Check_BMC_BIOS_Bank
				Remote_Check_version
				echo
				echo  "Waiting for system shutdown complete within $shutdown_time seconds."
				echo
				SystemPowerStatus
				dt=1
				while [ "$SystemStatus" == "Chassis Power is on" ]
				do
					res=$(($dt%10))
					if [ "$res" == 0 ]; then
						echo -n -e "$dt" 
					else
						echo -n -e "."
					fi
					let "dt = $dt + 1"
					SystemPowerStatus #5s
					if [ "$dt" -gt "$shutdown_time" ] ; then
						if [ "$TESTMODE" == "Debug test" ]; then
							echo
							echo "No. $i testing cycle, the UUT test failed."
							echo
								exit 0
						fi
					
						echo "No. $i testing cycle, the UUT cannot DC power off over 5 mins. 
						      Therefore, force off the UUT via remote side." >> $hang_folder/"$PJN"_DC_power_off_hang.log
						ipmitool -I lanplus -H $ip -U $user -P $password chassis power off
						sleep 10
						SystemPowerStatus
						
					fi
				done
				echo
					date "+%Y-%m-%d %T" 
				echo
				echo "DC power off the system for 10 seconds to analyze the SEL."
			fi
		fi
	done
	echo
	sleep 10
	echo
		date "+%Y-%m-%d %T" 
	echo
	Remote_Check_SEL
	echo
	#system_event_log_analysis 2>&1 | tee "$name"/BMC_SEL/All_SEL_analysis.log
	#cat "$name"/BMC_SEL/All_SEL_analysis.log	
	echo
	ClearSEL
	delay_counter $DC_OFF_duration #DC off duration = 30s
done
}

function Reboot_test(){
echo "Test Method: "$test_method"" >> Test_info.cfg
## create the parameter
Colorful_script
Test_mode
Set_duration
#Set_BMC
start_go
echo -e ${GREEN}
#send_shutdown_event
#wait_system_off
sleep 1
ClearSEL

##1. Check the UUT power status is OFF.
wait_system_off
SystemPowerStatus
if [ "$SystemStatus" == "Chassis Power is on" ]; then
	echo "The UUT power status is ON, please DC off the UUT then restart this script!"
	echo -e ${NC}
	exit 0
fi

# record the time of start
FTIME=`echo $(($(date +%s)+$TESTTIME))`
SystemPowerOn
##2. Start the test
for((i=$start_condition;i<=1100;i++))
do
echo $i > loop_count.txt
	## time base
	NTIME=`date +%s`
	if [ "$NTIME" -ge "$FTIME" ];then
		echo -e ${NC}		
		echo
		echo "Reboot test has been finished."
		echo 
		file_backup
		exit 0
	fi
	## cycle base
	if [ "$i" -ge "$CTC" ];then
		echo -e ${NC}		
		echo
		echo "Reboot test has been finished."
	   	echo
		file_backup
		exit 0
	fi
	##
	echo
	echo
	echo "***** Reboot test No.$i *****" 2>&1 | tee "$name"/loop_cycle.log
	echo
	ct=1
	EXOS=""
	echo
		date "+%Y-%m-%d %T" 2>&1 | tee "$name"/OS_boot_time_start.log
	echo
	while [ "$EXOS" == "" ]
	do
		if [ "$ct" == "$wait_boot_time" ];then
			if [ "$TESTMODE" == "Debug test" ];then
				echo "No. $i testing cycle, the UUT test failed."
				exit 0
			else
				echo
				echo "No. $i testing cycle, the UUT power on over 10 mins. 
			      Therefore, power reset the UUT via remote side." | tee -a $hang_folder/"$PJN"_reboot_hang.log
				ipmitool -I lanplus -H $ip -U $user -P $password power reset
				sleep 5 ; EXOS=1
			fi
		else
			
			GetSELKeyWord #2s
			
			
				#res=$(($ct%10))
				#if [ "$res" == 0 ]; then
				#	echo -n -e "$ct"
				#else
					echo -n -e "."
				#fi
				let "ct = $ct + 1"
				#sleep 1
			if [ "$SEL1" != "" ];then
				EXOS=1
				echo
					date "+%Y-%m-%d %T" 2>&1 | tee "$name"/Event_time_end.log
				echo
				
				OS_start=$(cat "$name"/OS_boot_time_start.log)
				OS_end=$(cat "$name"/Event_time_end.log)
				OS_boots_time=$(($(date -d "$OS_end" +%s)-$(date -d "$OS_start" +%s))) 
				echo
				echo "OS boots and script executed time: $OS_boots_time seconds" 2>&1 | tee "$name"/OS_boot_time_tmp.log		
				echo
				
				cat "$name"/loop_cycle.log >> "$name"/OS_boot_time.log
				cat "$name"/OS_boot_time_start.log >> "$name"/OS_boot_time.log
				cat "$name"/OS_boot_time_tmp.log >> "$name"/OS_boot_time.log
				cat "$name"/Event_time_end.log >> "$name"/OS_boot_time.log
				echo "" >> "$name"/OS_boot_time.log

				echo
				Remote_Check_BMC_BIOS_Bank
				Remote_Check_version
				Remote_Check_SEL
				for line in $(cat target.txt)
				do
				#echo "1: $line"
				. $line
				name=$(echo $line | awk -F "." '{print $1}')
				folder_ip=$(cat $line | grep ip | awk -F "=" '{print $2}')
				Record_resful_HW_device_scan
				done
				send_reboot_event
				sleep 10
				
				echo
				#system_event_log_analysis 2>&1 | tee "$name"/BMC_SEL/All_SEL_analysis.log
				#cat "$name"/BMC_SEL/All_SEL_analysis.log				
				echo
				ClearSEL
				echo
				echo -ne "Waiting for system reboot ..."\\r
				echo
				sleep 3 
				
			fi
		
		fi
	done
	
done
}


rm -f Test_info.cfg

echo "Test Start Timing:" >> Test_info.cfg
date | tee -a Test_info.cfg 

# Choose test method
Colorful_script
T01="AC"
T02="DC"
T03="Reboot"
TESTCASE=("$T01" "$T02" "$T03")
PS3="Choose the test item: "
echo -e ${ORANGE}
select test_method in "${TESTCASE[@]}"
do
	#echo "$test_method"
	
	#echo "Test Method: "$test_method"" >> Test_info.cfg
	if [ "$test_method" == "Reboot" ];then
		
		Reboot_test
	elif [ "$test_method" == "DC" ];then
		
		DC_test
	else
		
		AC_test
	fi	
	break
done

echo "Test End Timing:" >> Test_info.cfg
date | tee -a Test_info.cfg 

