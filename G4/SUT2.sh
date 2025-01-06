#!/bin/bash
# Program:
# 		This script is used to control the UUT to perform the loop tests.
# version:
# 		1.0
# Date:
#		08/22/2019


##############################################################################################



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
		ipmitool  power on
		sleep 5
		SystemPowerStatus
		
	done
}

function SystemPowerStatus(){ #check the power status of active node
	SystemStatus=""
	sleep 1
	while [ "$SystemStatus" == "" ]
	do
		SystemStatus=`ipmitool  chassis power status`
		sleep 4
	done
}

function GetSELKeyWord(){ #capture the system event log if included "event 3" 
	#echo 1 > $name/KeyWord.log
	#sleep 1
	#rm -f $name/KeyWord.log
	SEL1=""
	sel_counter=0
	while true
	do
		ipmitool  sel list 2> /dev/null 1> $name/KeyWord.log
		if [ "$?" == 0 ]; then
			break
		else
			sleep 1
			echo -n -e "."
			let "sel_counter=$sel_counter+1"
			if [ "$sel_counter" == 10 ]; then
			echo "BMC session interrupt, can't get SEL."
				exit
			fi
		fi
	done
	cat $name/KeyWord.log | grep -i "OS Boot #0x87" > /dev/null
	if [ "$?" == 0 ]; then
		SEL1=`cat $name/KeyWord.log | grep -i "OS Boot #0x87"`
		#echo "loop_scripts executed completed." >  script.status
	fi
	cat $name/KeyWord.log | grep -i "Platform Security #0x87"  > /dev/null
	if [ "$?" == 0 ]; then
		SEL1=`cat $name/KeyWord.log | grep -i "Platform Security #0x87"`
		#echo "loop_scripts executed completed." >  script.status
	fi

	sleep 2
}

function ClearSEL(){ #clear the system event log
	SELCR=0
	until [ "$SELCR" == "Clearing SEL.  Please allow a few seconds to erase." ]
	do
		SELCR=`ipmitool  sel clear`
		echo $SELCR
		sleep 2
		echo
	done
}

function Set_BMC(){
	echo -e ${ORANGE}
	
	echo
	read -p "Do you want to check the Golden Sample SEL(y/n): " Check_SEL
	echo $Check_SEL > Check_SEL.txt
	read -p "Do you want to check the BMC and BIOS boot bank (y/n): " Check_Bank
	echo $Check_Bank > Check_Bank.txt
	read -p "Do you want to check the PCIe/Storage device by RESTful (y/n): " Check_Restful
	echo $Check_Restful > Check_Restful.txt
	if [ "$Check_Restful" == "y" ]; then
		cat os_info.log | grep -i ubuntu > /dev/null
		if [ "$?" == 0 ]; then
			dpkg -l | grep -i -w jq > /dev/null
			if [ "$?" == 1 ]; then
				apt install jq -y
			fi
		else
			rpm -qa | grep -i jq > /dev/null
			if [ "$?" == 1 ]; then
				yum install jq -y
			fi
		fi
	fi

	

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
}

function Set_duration(){
	j=$(cat Loop.conf | grep RUNTIME | awk -F "=" '{print $2}')
		#echo gg
		if [ "$j"  == "12 hours" ];then
			TESTTIME=43200
			
		elif [ "$j"  == "24 hours" ];then
			TESTTIME=86400
			
		elif [ "$j"  == "48 hours" ];then
			TESTTIME=172800
			
		elif [ "$j"  == "60 hours" ];then
			TESTTIME=216000
			
		elif [ "$j"  == "1000 cycles" ];then
			TESTTIME=9999999
			
		elif [ "$j" == "1000 hours" ];then
			TESTTIME=9999999
			
		fi
		
		
}

function PDUPlugStatus(){ # To get the plug power status.
	if [ "$PV" == "APC" ];then
		echo
		echo "PDU Port $PDUPlug status: "
		while true
		do
			python3 apc.py $APC_IP $PDUPlug status 2> /dev/null 1> APC.status
			cat APC.status | grep -i Success
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
			python3 apc.py $APC_IP $PDUPlug on 2> /dev/null 1> APC.status
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
			python3 apc.py $APC_IP $PDUPlug off 2> /dev/null 1> APC.status
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

function PDUConnection(){
	if [ "$PV" == "APC" ];then
		echo
		echo "Establish PDU session.."

		apc_connect=0
		while true
		do
		python3 apc.py $APC_IP $PDUPlug status  2>&1 | tee PDUStatus.txt
		cat PDUStatus.txt | grep -i not > /dev/null
		if [ "$?" == 0 ]; then
			cat os_info.log | grep -i ubuntu >/dev/null
			if [ "$?" == 0 ]; then
				apt install fence-agents -y
			else
				yum install fence-agents -y
			fi
		fi
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
	if [ "$PDU1" == "Status: ON" ];then
		echo "Please execute the following command to turn off AC power."
		echo "python3 apc.py $APC_IP $PDUPlug off"
		echo -e ${NC}
		exit 0
	fi
else
	if [ "$PDU1" == " 11" ];then
		echo "Please execute the following command to turn off AC power.
	      ipmitool -I lanplus -H $APC_IP -U $user -P flex raw 0x3c 0x12 $PDUPlug 0"
		echo -e ${NC}
		exit 0
	fi
fi
echo "PDU plug is power off."
}

function getoffsel(){  #無法DC OFF的project使用
	SEL1=`ipmitool  sel list | grep "S5/G2: soft-off"`
	sleep 2
}

function Set_PDU(){
	echo
	#T01="APC"
	#T02="Raritan"
	#TESTCASE=("$T01" "$T02" )
	#PS3="Choose the PDU vendor: "
	#echo -e ${GREEN}
	#select P in "${TESTCASE[@]}"
	#do
	#	PV="$P"
		PV=APC
	#	break
	#done
	echo
	#if [ "$lazy" == n ]; then
	#read -p "Input the PDU IP: " APC_IP
	#read -p "Input the PDU Username: " APC_user
	#read -p "Input the PDU Password: " APC_password
	#read -p "Input the PDU PLUG number: " PDUPlug
	#read -p "AC Failure time: " ac_failure_time
	#else
	echo
	echo "APC/PDU IP:$APC_IP"
	echo "APC/PDU User:$APC_user"
	echo "APC/PDU Password:$APC_password"
	echo "APC/PDU action port: $PDUPlug"
	#echo "PSU AC Failure time: $ac_failure_time"
	#fi
	if [ "$PV" == "APC" ];then
		POS="Status: ON"
	else
		POS=" 11"
	fi
}

check_info(){

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
	echo "Start to the loop stress"
else
	echo "Information is incorrect. Exit the script"
	echo
	exit
fi
}

Remote_Check_BMC_BIOS_Bank(){
if [ "$Check_Bank" == "y" ]; then
	#echo
	BMC_bank="$name/BMC_Bank"
	BIOS_bank="$name/BIOS_Bank"
	while true
	do        
		ipmitool  raw 0x32 0x8f 0x02 > $BMC_bank/BMC_Bank_$i.log && ipmitool  raw 0x36 0x79 0x2a 0x6f 0x00 0x02 > $BIOS_bank/BIOS_Bank_$i.log
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
			cat $BMC_bank/BMC_Bank_fail_tmp_1.log  >> $name/BMC_Bank_fail.log
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
			cat $BIOS_bank/BIOS_Bank_fail_tmp_1.log  >> $name/BIOS_Bank_fail.log
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
version_path="$name/Version"
while true
do
redfishtool -r $ip -u $user -p $password -S Always raw GET /redfish/v1/UpdateService/FirmwareInventory/ | grep -i "/redfish/v1/UpdateService/FirmwareInventory/" | grep -i "BIOS\|BMC\|CPLD\|SWITCH"> $version_path/firmware_version_layer1.log
cat $version_path/firmware_version_layer1.log | grep "UpdateService" > /dev/null
if [ "$?" == 0 ]; then
	break
else
	echo -n -e "."
	sleep 1
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

}



Remote_Check_SEL(){
	###################################################################################################
if [ "$Check_SEL" == y ]; then
	echo
	echo
	echo "Check $name SEL"
	echo
	while true
	do        
	ipmitool  sel elist > $name/BMC_SEL/BMC_event_$i.log
	if [ "$?" == 0 ]; then
		cp $name/BMC_SEL/BMC_event_$i.log $name/BMC_SEL/Golden_Sample_SEL_bak.log
		break
	else
		sleep 1
	fi
	done
	
	###################################################################################################
	
	if [ "$i" == 1 ]; then
		
		cat $name/BMC_SEL/BMC_event_$i.log | awk -F " " '{print $1}' > $name/BMC_SEL/sel_number.log
		echo "" >> $name/BMC_SEL/BMC_event_$i.log
		echo "=============== Detail event analysis ===============" >> $name/BMC_SEL/BMC_event_$i.log
		echo "" >> $name/BMC_SEL/BMC_event_$i.log
		while read line
		do
			ipmitool  sel get 0x$line  >> $name/BMC_SEL/BMC_event_$i.log
		done < $name/BMC_SEL/sel_number.log
		rm -f $name/BMC_SEL/sel_number.log
		
		cat $name/BMC_SEL/BMC_event_$i.log
		cat $hang_folder/boot.log | grep -i new > /dev/null
		if [ "$?" == 0 ]; then
		#read -p "Please check the 1st loop SEL, if no question the SEL will be the Golden SEL Sample(y/n): " golden_sel
			golden_sel=y
			if [ "$golden_sel" == y ]; then
				echo $golden_sel > $name/chk_sel_sample.log
				cp $name/BMC_SEL/Golden_Sample_SEL_bak.log $name/BMC_SEL/Golden_Sample_SEL.log
			else
				exit
			fi
		else
			echo "Abnormal Boot event log in $hang_folder/Boot_error" 
		fi
	else
		echo " " >  $name/BMC_SEL/BMC_sel_fail_tmp.log
		echo "=============== "$i" ===============" >>  $name/BMC_SEL/BMC_sel_fail_tmp.log
		echo " " >>  $name/BMC_SEL/BMC_sel_fail_tmp.log
		echo "Event Status: " >  $name/BMC_SEL/BMC_sel_abnormal_tmp.log 
		while read line
		do
			sel_number=$(echo $line | awk -F "|" '{print $1}')
			sel_content_1=$(echo $line | awk -F "|" '{print $4}')
			sel_content_2=$(echo $line | awk -F "|" '{print $5}')
			
			grep "$sel_content_1" $name/BMC_SEL/Golden_Sample_SEL.log > /dev/null || grep "$sel_content_2" $name/BMC_SEL/Golden_Sample_SEL.log > /dev/null
			if [ "$?" != 0 ]; then
			echo "Abnormal event found" >>  $name/BMC_SEL/BMC_sel_abnormal_tmp.log
			#echo ""$sel_number" status=error" >>  BMC_SEL/BMC_sel_fail_tmp.log
			#echo " " >>  BMC_SEL/BMC_sel_fail_tmp.log
			#cat BMC_SEL/BMC_event_$i.log | grep "$sel_number" | grep "$sel_content"
			echo "$line" >>  $name/BMC_SEL/BMC_sel_fail_tmp.log
			fi
		done < $name/BMC_SEL/BMC_event_$i.log
		cat $name/BMC_SEL/BMC_sel_fail_tmp.log  >> $name/BMC_SEL/BMC_sel_fail.log
		grep -i abnormal $name/BMC_SEL/BMC_sel_abnormal_tmp.log > /dev/null
		if [ "$?" == 0 ]; then
			echo 
			echo -e ${RED}
			echo "Detected the extra event in SEL at loop: $i."
			echo
				cat $name/BMC_SEL/BMC_sel_fail_tmp.log
			echo
			echo -e ${GREEN}
		else
			echo 
			echo "There is no extra event in SEL."
			echo
			cat $name/BMC_SEL/BMC_event_$i.log
			echo
		fi
		rm -f $name/BMC_SEL/BMC_sel_abnormal_tmp_1.log
		
		cat $name/BMC_SEL/BMC_event_$i.log | awk -F " " '{print $1}' > $name/BMC_SEL/sel_number.log
		echo "" >> $name/BMC_SEL/BMC_event_$i.log
		echo "=============== Detail event analysis ===============" >> $name/BMC_SEL/BMC_event_$i.log
		echo "" >> $name/BMC_SEL/BMC_event_$i.log
		while read line
		do
			ipmitool  sel get 0x$line  >> $name/BMC_SEL/BMC_event_$i.log
		done < $name/BMC_SEL/sel_number.log
		rm -f $name/BMC_SEL/sel_number.log
	fi
	echo
	
else	
		
		echo
		echo "No Golden Sample SEL Checked" > $name/chk_sel_sample.log
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
./Get_Restful_storage_info_tmp.sh > $name/Restful/Storage_info_tmp.log
cat $name/Restful/Storage_info_tmp.log | tail -1 | jq > $name/Restful/Storage_info_$i.log
cp $name/Restful/Storage_info_$i.log $name/Restful/Storage_info_Golden_Sample.log



cat $line > Get_Restful_info_tmp.sh
cat restful_pcie_info.sh >> Get_Restful_info_tmp.sh
chmod 777 Get_Restful_info_tmp.sh
if [ -f "Get_Restful_pcie_info_tmp.sh" ]; then
	rm -f Get_Restful_pcie_info_tmp.sh
fi
cp Get_Restful_info_tmp.sh Get_Restful_pcie_info_tmp.sh
chmod 777 Get_Restful_pcie_info_tmp.sh
./Get_Restful_pcie_info_tmp.sh > $name/Restful/PCIe_info_tmp.log
cat $name/Restful/PCIe_info_tmp.log | tail -1 | jq > $name/Restful/PCIe_info_$i.log
cp $name/Restful/PCIe_info_$i.log $name/Restful/PCIe_info_Golden_Sample.log
echo
else

	
	./Get_Restful_storage_info_tmp.sh > $name/Restful/Storage_info_tmp.log
	cat $name/Restful/Storage_info_tmp.log | tail -1 | jq > $name/Restful/Storage_info_$i.log
	./Get_Restful_pcie_info_tmp.sh > $name/Restful/PCIe_info_tmp.log
	cat $name/Restful/PCIe_info_tmp.log | tail -1 | jq > $name/Restful/PCIe_info_$i.log
	echo

	#echo "=============== "$i" ===============" >  Restful/Restful_fail_tmp_1.log
	#echo " " >>  Restful/Restful_fail_tmp_1.log
##############################################################

if [ -f "$name/Restful/Storage_info_fail_tmp.log" ]; then
	rm -f $name/Restful/Storage_info_fail_tmp.log
fi
target_file="$name/Restful/Storage_info_$i.log"
sed -i 's/\]//g' $target_file
sed -i 's/\[//g' $target_file
sed -i 's/}//g' $target_file
sed -i 's/{//g' $target_file
while read line
do
#echo $line
if [ "$line" == "" ]; then
	continue
else	
	grep "$line" $name/Restful/Storage_info_Golden_Sample.log > /dev/null
	if [ "$?" == 1 ]; then
			
		echo "Storage: $line info error" >> $name/Restful/Storage_info_fail_tmp.log
		
	else
		continue
	fi
	
fi
done < $target_file
##############################################################
	if [ ! -f "$name/Restful/Storage_info_fail_tmp.log" ]; then
		#cat Restful/Storage_info_fail_tmp.log | grep -i error
		#if [ "$?" == 1 ]; then
		echo "Storage information check OK."
	else
		echo "Storage info compare failed"
		echo "=============== "$i" ===============" >> $name/Restful/Storage_fail.log
		cat $name/Restful/Storage_info_fail_tmp.log >> $name/Restful/Storage_fail.log
		echo " " >> $name/Restful/Storage_fail.log
		#echo "Detected Storage info error at loop: $boot."
		#cat "$pwd"BMC/Restful/Storage_fail.log >> "$pwd"Restful_Storage_fail.log
	fi
	echo

##############################################################

if [ -f "$name/Restful/PCIe_info_fail_tmp.log" ]; then
	rm -f $name/Restful/PCIe_info_fail_tmp.log
fi
target_file="$name/Restful/PCIe_info_$i.log"
sed -i 's/\]//g' $target_file
sed -i 's/\[//g' $target_file
sed -i 's/}//g' $target_file
sed -i 's/{//g' $target_file
while read line
do
#echo $line
if [ "$line" == "" ]; then
	continue
else	
	grep "$line" $name/Restful/PCIe_info_Golden_Sample.log > /dev/null
	if [ "$?" == 1 ]; then
			
		echo "PCIe: $line info error" >> $name/Restful/PCIe_info_fail_tmp.log
		
	else
		continue
	fi
	
fi
done < $target_file
##############################################################




	if [ ! -f "$name/Restful/PCIe_info_fail_tmp.log" ]; then
		#cat Restful/PCIe_info_fail_tmp.log | grep -i error
		#if [ "$?" == 1 ]; then
		echo "PCIe informtion check OK."
	else
		echo "PCIeDevice info compare failed"
		echo "=============== "$i" ===============" >> $name/Restful/PCIe_fail.log
		cat $name/Restful/PCIe_info_fail_tmp.log >> $name/Restful/PCIe_fail.log
		echo " " >> $name/Restful/PCIe_fail.log
		#echo "Detected PCIe info error at loop: $boot."
		#cat "$pwd"BMC/Restful/PCIe_fail.log >> "$pwd"Restful_PCIe_fail.log
	fi

fi
echo
fi
}


send_shutdown_event(){
echo
echo "Send test event to power off $name System"
echo
while true
do
ipmitool  raw 0x0a 0x44 0xff 0xff 0x02 0x00 0x00 0x00 0x00 0x87 0x00 0x04 0x20 0x87 0x03 0x51 0x54 0x43 > /dev/null
#echo 1
if [ "$?" == 0 ]; then
	echo "$name System will shutdown within 60 seconds."
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
ipmitool  raw 0x0a 0x44 0xff 0xff 0x02 0x00 0x00 0x00 0x00 0x87 0x00 0x04 0x20 0x87 0x03 0x51 0x54 0x43 > /dev/null
if [ "$?" == 0 ]; then
	echo "$name System System will reboot within 60 seconds."
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
echo "Wait for $name System power off."
echo
while true
do
ipmitool  chassis power status > $name/system_status.log
cat $name/system_status.log | grep -i off
if [ "$?" == 0 ]; then
	echo "$name System in power off mode"
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
	ipmitool  mc info 2>/dev/null 1 > $name/ready.log
	i_BMC=$(cat $name/ready.log | grep -i version -c)
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
	ipmitool  chassis policy always-off 
	if [ "$?" == 0 ]; then
		break
	else
		echo -n -e "."
		sleep 1
	fi
done
# ---------------------------------------------------
}
##############################################################################################
cat flow.txt | grep -i setting > /dev/null
if [ "$?" == 0 ]; then

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

for iconfig in $(cat target.txt)
do
#cat $iconfig
name=$(echo $iconfig | awk -F "." '{print $1}')


if [ -d "$name" ]; then
rm -r -f $name
fi
if [ -d local_main ]; then
rm -rf local_main
fi

mkdir -p {$name/Boot_error,$name/BMC_SEL,$name/BMC_Bank,$name/BIOS_Bank,$name/Version,$name/Restful,local_main}


done


path=$(pwd)
. $path/configuration
	if [ "$?" != 0 ]; then
		echo "There is no configuration file in $path/"	
			exit
	fi

hang_folder=$path/$name/Boot_error

###################################################################################################
#APC settings
if [ -f apc.py ]; then
	rm -f apc.py
fi

cp apc_v2.py apc.py

sed -i "s/i_user/$APC_user/g" apc.py
sed -i "s/i_passwd/$APC_password/g" apc.py

echo "Set the PDU parameters for Local AC cycle."
echo
read -p "AC off delay time: " AC_OFF
echo $AC_OFF > AC_OFF.time
read -p "AC on delay time: " AC_ON
echo $AC_ON > AC_ON.time
echo
while true
do
	python3 apc.py $APC_IP "$PDUPlug $AC_OFF" offdelay  2>/dev/null 1>APC
	cat APC | grep -i success > /dev/null
	if [ "$?" == 0 ]; then
		cat APC
		break
	else
		sleep 2
		echo -n -e "."
	fi
done
sleep 3
while true
do
	python3 apc.py $APC_IP "$PDUPlug $AC_ON" ondelay   2>/dev/null 1>APC
	cat APC | grep -i success > /dev/null
	if [ "$?" == 0 ]; then
		cat APC
		break
	else
		sleep 2
		echo -n -e "."
	fi
done
sleep 3

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
#Test_mode
Set_duration
#Set_BMC
Set_PDU
check_info
echo -e ${GREEN}


PDUConnection
#PDUPlugStatus

#echo "APC/PDU IP:$APC_IP"
#echo "APC/PDU User:$APC_user"
#echo "APC/PDU Password:$APC_password"
#echo "APC/PDU action port: $PDUPlug"
#echo "PSU AC Failure time: $ac_failure_time"


for line in $(cat target.txt)
do
. $line
name=$(echo $line | awk -F "." '{print $1}')
#send_shutdown_event
echo "new boot" > $hang_folder/boot.log
# ---------------------------------------------------
while true
do
	ipmitool  chassis policy always-on
	if [ "$?" == 0 ]; then
		break
	else
		echo -n -e "."
		sleep 1
	fi
done
# ---------------------------------------------------
echo $name | grep "1" > /dev/null
if [ "$?" == 0 ]; then
	echo  > /dev/null
else
	wait_system_off
fi
#for line in $(cat target.txt)
done 

while true
do
	python3 apc.py $APC_IP $PDUPlug status  2>/dev/null 1>APC
	cat APC | grep -i success > /dev/null
	if [ "$?" == 0 ]; then
		cat APC
		break
	else
		sleep 2
		echo -n -e "."
	fi
done

while true
do
	
	#echo "python3 apc.py $APC_IP $PDUPlug dlyreboot"
	python3 apc.py $APC_IP $PDUPlug dlyreboot  2>/dev/null 1>APC
	cat APC | grep -i success > /dev/null
	if [ "$?" == 0 ]; then
		
		cat APC
		
		break
	else
		sleep 2
		echo -n -e "."
	fi
done

echo "System will AC off within $AC_OFF seconds."
# ---------- record the time of start ---------------
echo $(($(date +%s)+$TESTTIME)) > /root/AC_FINISH_TIME

# ---------------------------------------------------
echo start > flow.txt
	if [ -f loop_count.txt ]; then
		rm -f loop_count.txt
	fi

echo

for line in $(cat target.txt) 
do
	. $line
	name=$(echo $line | awk -F "." '{print $1}')
	#echo $name
	echo "Clear $name SEL"
	while true
	do
			
		ipmitool  sel clear
		if [ "$?" == 0 ]; then
			break
		else
			echo -n -e "."
			sleep 1
		fi
	done
done
echo
echo
echo "Sled #1 will shutdown within 40 seconds."
i_off=0
while [ "$i_off" != 40 ]
do
sleep 1
echo -n -e "."
let "i_off=$i_off+1"
done
echo
echo
echo "Shutdown"
sleep 2
shutdown -h now
exit
fi
# -------------------------------- Start AC cycling ---------------------------------------- #
#for((i=1;i<=1100;i++))
#do
#======================================================================================================1	

path=$(pwd)
. $path/configuration
	if [ "$?" != 0 ]; then
		echo "There is no configuration file in $path/"	
			exit
	fi
echo 1 >> loop_count.txt
i=$(cat loop_count.txt | grep "1" -c)
	# ---------- check the testing time or cycles ----------
	## time base
	FTIME=`cat /root/AC_FINISH_TIME`
	NTIME=`date +%s`
	if [ "$NTIME" -ge "$FTIME" ];then
		echo -e ${NC}
		echo
		echo "AC cycling test has been finished."
		echo
		#PDUPlugOn
		echo setting > flow.txt
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
		exit 0
	fi
#======================================================================================================1
#======================================================================================================2
	## cycle base
	TESTMODE=$(cat Loop.conf | grep -i Test_run | awk -F "=" '{print $2}')
	CTC=$(cat Loop.conf | grep -i CYCLES | awk -F "=" '{print $2}')
	if [ "$i" -ge "$CTC" ];then
		echo -e ${NC}
		echo
		echo "AC cycling test has been finished."
		echo
		#PDUPlugOn
		echo setting > flow.txt
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
		exit 0
	fi
	# ------------------------------------------------------
#======================================================================================================2

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
	
	echo "Wait for $name BMC booting completed"
	echo
	while [ "$BMCPING" == "" ]  # 只要BMCPING的變數值為空白就執行迴圈
	do
		
		
		#res=$(($bt%10))
		#if [ "$res" == 0 ]; then
		#	echo -n -e "$bt"
		#else
			echo -n -e "."
		#fi
		let "bt = $bt + 1"
		sleep 1
	
		BMCPING=`ping $ip -c 1 | grep ttl`
		if [ "$bt" == "180" ]; then  #設置等待時間為180秒
			echo "No. $i testing cycle, cannot connect to BMC network.
			      Therefore, AC power off the UUT via remote side." >> $hang_folder/"$PJN"_AC_power_on_hang_$name.log
			while [ "$PDU1" == "Status: ON" ]
			do
				echo "Cannot connect to BMC network ，AC off the system."
				python3 apc.py $APC_IP $PDUPlug status
				sleep 1
				python3 apc.py $APC_IP $PDUPlug dlyreboot
				echo "System will AC off within 90 seconds."
			done
			BMCPING=1  #跳脫BMC迴圈
		fi
	done
	#for line in $(cat target.txt)
	done 
	echo
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
	#echo "BMC boots time: $BMC_boots_time seconds" 2>&1 | tee BMC_Boot_time_tmp.log
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
	i_BMC=0
	while [ "$i_BMC" = 0 ]
	do
	ipmitool  mc info 2>/dev/null 1 > ready.log
	i_BMC=$(cat ready.log | grep -i version -c)
	echo -n -e "."
	sleep 1
		if [ "$i_BMC" == 180 ]; then
			echo "No. $i testing cycle, BMC maybe hang up because of BMC has no any response within 180 seconds." >> $hang_folder/"$PJN"_BMC_hang_$name.log
			echo
				
		fi
	done
	echo
	cat ready.log | head -3
	echo
	
	# ---------- check the system is on or off --------------
	
	echo "$name Power status"	
	SystemPowerStatus
	if [ "$SystemStatus" == "Chassis Power is off" ];then
		echo "$name Power on"
		SystemPowerOn
		#sleep $ACONtoPOST
		#sleep $POSTtoOS
	fi
	# -------------------------------------------------------
	#for line in $(cat target.txt)
	done 
#======================================================================================================4
	echo
		date "+%Y-%m-%d %T" 2>&1 | tee OS_boot_time_start.log
	echo
#======================================================================================================5
	echo
	echo "Wait for booting into OS"
	echo
	while [ "$PDU1" == "$POS" ]  #當插座是通電狀態下就執行以下程式
	#while true
	do
		echo no > cfg_status.txt
		# 當開機狀態下達到600秒就強制斷電
		if [ "$ct" -gt "$wait_boot_time" ]; then
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
				
				ipmitool  sel list 2>&1 | tee -a $hang_folder/boot_sel_over10mins_$name-loop_$i.log
				sleep 2
				echo
				#echo "OS boot timeout, force AC OFF within 30 seconds."
				Remote_Check_version
				#echo "line-1171"
				Remote_Check_SEL
				ClearSEL
				echo "new boot" > $hang_folder/boot.log
				#for line in $(cat target.txt)
				done 
				while [ "$PDU1" == "$POS" ] 
				do
					python3 apc.py $APC_IP $PDUPlug status
					sleep 1
					python3 apc.py $APC_IP $PDUPlug dlyreboot
					echo "System will AC off within 90 seconds."
					sleep 10
					exit
				done
			fi
		# 未超過600秒執行以下scrpit
		else
			
			#ct=$((ct+10))  #10秒偵測一次PDU狀態
			for line in $(cat target.txt)
			do
			#echo "clearSEL: $line"
			. $line
			name=$(echo $line | awk -F "." '{print $1}')
			GetSELKeyWord
			#echo $name
			res=$(($ct%10))
			if [ "$res" == 0 ]; then
				echo -n -e "$ct"
			else
				echo -n -e "."
			fi
			let "ct = $ct + 1"
			sleep 1
				
			# 當系統進入OS發出event 3後執行下列程式 
			if [ "$SEL1" != "" ];then
				echo
				echo
					date "+%Y-%m-%d %T" 2>&1 | tee Event_time_end.log
				echo
				# -------------------------------------------------------
				OS_start=$(cat OS_boot_time_start.log)
				OS_end=$(cat Event_time_end.log)
				#echo "BMC boot start:$bmc_start"
				#echo "BMC end end:$bmc_end"
				OS_boots_time=$(($(date -d "$OS_end" +%s)-$(date -d "$OS_start" +%s))) 
				echo "OS boots and script executed time: $OS_boots_time seconds" 2>&1 | tee OS_Boot_time_tmp.log
				echo
				cat loop_cycle.log >> OS_Boot_time.log
				cat OS_Boot_time_tmp.log >> OS_Boot_time.log
				# -------------------------------------------------------
				echo $name check
				Record_resful_HW_device_scan
				#Remote_Check_BMC_BIOS_Bank
				Remote_Check_version
				echo "Getting the system logs..."
				sleep 5  
				dt=1
				SystemPowerStatus
				# 確認系統是否關機
				echo $name | grep "1" > /dev/null
				if [ "$?" == 0 ]; then
					echo $line >> sled_status.txt
				else
				
				echo
				echo "Shut down the OS now ."
				echo
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
					if [ "$dt" == "$shutdown_time" ]; then
						echo
						echo
							date
						echo
						echo "No. $i testing cycle, cannot shut dwon the OS within 5 mins. 
						      Therefore, AC power off the UUT via remote side." | tee -a $hang_folder/"$PJN"_AC_power_off_hang_$name.log
						ipmitool  sel list | tee -a $hang_folder/shutdown_over_5mins_SEL_$name-loop_$i.log
						sleep 2
						
						ipmitool  power off
						sleep 10
						SystemPowerStatus
						
					fi
				done
				
				echo
				echo $line >> sled_status.txt
				Remote_Check_SEL
				echo
				echo "Clear SEL"
				ClearSEL
				sleep 1
				fi
			fi
			#PDUPlugStatus
			#for line in $(cat target.txt)
			echo yes > cfg_status.txt
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
		#cat cfg_status.txt | grep yes > /dev/null
		#if [ "$?" == 0 ]; then
		#	break
		#fi
	done
	
	
sleep 1
while true
do
	python3 apc.py $APC_IP $PDUPlug status  2>&1 | tee APC
	cat APC | grep -i success > /dev/null
	if [ "$?" == 0 ]; then
		break
	else
		echo -n -e "."
	fi
done
	echo
	echo
while true
do
	
	python3 apc.py $APC_IP $PDUPlug dlyreboot  2>&1 | tee APC
	cat APC | grep -i success > /dev/null
	if [ "$?" == 0 ]; then
		break
	else
		echo -n -e "."
	fi
done

echo
echo
echo "System will AC off within $AC_OFF seconds."
echo
