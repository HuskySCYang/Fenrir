

#!/bin/bash
# Program:
# 		This script is used to control the UUT to perform the loop tests.
# version:
# 		1.0
# Date:
#		08/22/2019


##############################################################################################
go_SUTPATH(){
	cd $SUTPATH
}
	go_SUTPATH


#$SUTPATH

. $SUTPATH/configuration
	if [ "$?" != 0 ]; then

		echo "There is no configuration file in $path/"	
			exit
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
		ipmitool  sel list 2> /dev/null 1> $SUTPATH/$name/KeyWord.log
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
	cat $SUTPATH/$name/KeyWord.log | grep -i "OS Boot #0x87" > /dev/null
	if [ "$?" == 0 ]; then
		SEL1=`cat $SUTPATH/$name/KeyWord.log | grep -i "OS Boot #0x87"`
		#echo "loop_scripts executed completed." >  script.status
		#echo "OS done" > cat $SUTPATH/$name/OS.log
	fi
	cat $SUTPATH/$name/KeyWord.log | grep -i "Platform Security #0x87"  > /dev/null
	if [ "$?" == 0 ]; then
		SEL1=`cat $SUTPATH/$name/KeyWord.log | grep -i "Platform Security #0x87"`
		#echo "loop_scripts executed completed." >  script.status
		#echo "OS done" > cat $SUTPATH/$name/OS.log
	fi
	################################ debug-mode exit confition ################################ 
	cat "$name"/KeyWord.log | grep -i "OS Boot #0xf7" > /dev/null
	if [ "$?" == 0 ]; then
		echo
		echo
		echo "SUT detect the error oocurred in debug mode."
		echo
		echo "Stop the stress !!"
		echo
		gnome-terminal --hide-menubar --maximize -- bash -c "echo $name occurred error in debug mode ;echo -e '\033[0;31m';cat $SUTPATH/FAIL;echo -e '\033[0m';read" &
			exit
		
	fi

	cat "$name"/KeyWord.log | grep -i "Platform Security #0xf7"  > /dev/null
	if [ "$?" == 0 ]; then
		echo
		echo
		echo "SUT detect the error oocurred in debug mode."
		echo
		echo "Stop the stress !!"
		echo
			gnome-terminal --hide-menubar --maximize -- bash -c "echo $name occurred error in debug mode ;echo -e '\033[0;31m';cat $SUTPATH/FAIL;echo -e '\033[0m';read" &
			exit
		
	fi
	################################ debug-mode exit confition ################################ 

	sleep 1
	
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
	echo $Check_SEL > $SUTPATH/Check_SEL.txt
	read -p "Do you want to check the BMC and BIOS boot bank (y/n): " Check_Bank
	echo $Check_Bank > $SUTPATH/Check_Bank.txt
	read -p "Do you want to check the PCIe/Storage device by RESTful (y/n): " Check_Restful
	echo $Check_Restful > $SUTPATH/Check_Restful.txt
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
			echo 1000 > $SUTPATH/CTC.txt
		elif [ "$j"  == "24 hours" ];then
			TESTTIME=86400
			echo 1000 > $SUTPATH/CTC.txt
		elif [ "$j"  == "48 hours" ];then
			TESTTIME=172800
			echo 1000 > $SUTPATH/CTC.txt
		elif [ "$j"  == "60 hours" ];then
			TESTTIME=216000
			echo 1000 > $SUTPATH/CTC.txt
		elif [ "$j"  == "1000 cycles" ];then
			TESTTIME=9999999
			echo 1000 > $SUTPATH/CTC.txt
		elif [ "$j" == "Custom cycles" ];then
			read -p "Please input the test cycles: " CTC
			TESTTIME=9999999
			echo $CTC > $SUTPATH/CTC.txt
		fi
		break
	done	
}

function PDUPlugStatus(){ # To get the plug power status.
		PV=APC
	if [ "$PV" == "APC" ];then
		echo
		echo "PDU Port $PDUPlug status: "
		while true
		do
			python3 apc.py $APC_IP $PDUPlug status 2> /dev/null 1> $SUTPATH/APC.status
			cat $SUTPATH/APC.status | grep -i status
			if [ "$?" == 0 ]; then
				break
			else
				echo -n -e "."
				sleep 1
			fi
		done
		PDU1=`cat $SUTPATH/APC.status`
	else
		PDU1=`ipmitool   -I lanplus -H $APC_IP -U $user -P flex raw 0x3c 0x13 $PDUPlug` 
	fi
}

function PDUPlugOn(){
	if [ "$PV" == "APC" ];then
		echo
		echo "Enable PDU Port: $PDUPlug"
		while true
		do
			python3 apc.py $APC_IP $PDUPlug on 2> /dev/null 1> $SUTPATH/APC.status
			cat $SUTPATH/APC.status | grep -i on
			if [ "$?" == 0 ]; then
				break
			else
				echo -n -e "."
				sleep 1
			fi
		done
	else
		ipmitool   -I lanplus -H $APC_IP -U $user -P flex raw 0x3c 0x12 $PDUPlug 1
	fi
}

function PDUPlugOff(){
	if [ "$PV" == "APC" ];then
		echo
		echo "Disable PDU Port: $PDUPlug"
		while true
		do
			python3 apc.py $APC_IP $PDUPlug off 2> /dev/null 1> $SUTPATH/APC.status
			cat $SUTPATH/APC.status | grep -i off
			if [ "$?" == 0 ]; then
				break
			else
				echo -n -e "."
				sleep 1
			fi
		done
	else
		ipmitool   -I lanplus -H $APC_IP -U $user -P flex raw 0x3c 0x12 $PDUPlug 0
	fi
}

function PDUConnection(){
	if [ "$PV" == "APC" ];then
		echo
		echo "Establish PDU session.."

		apc_connect=0
		while true
		do
		python3 apc.py $APC_IP $PDUPlug status  2>&1 | tee  $SUTPATH/PDUStatus.txt
		PDUStatus=$(cat $SUTPATH/PDUStatus.txt)
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
		ping $APC_IP -c 1 -t 5 > $SUTPATH/PDUStatus.log
		PDUStatus=$(cat $SUTPATH/PDUStatus.log | grep -i ttl -c)
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
	      ipmitool   -I lanplus -H $APC_IP -U $user -P flex raw 0x3c 0x12 $PDUPlug 0"
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
	echo "PSU AC Failure time: $ac_failure_time"
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
for iconfig in $(cat $SUTPATH/target.txt)
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
Check_Bank=$(cat $SUTPATH/Check_Bank.txt)

if [ "$Check_Bank" == "y" ]; then
	#echo
	BMC_bank="$SUTPATH/$name/BMC_Bank"
	BIOS_bank="$SUTPATH/$name/BIOS_Bank"
	while true
	do        
		#echo in: $ip
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
version_path="$SUTPATH/$name/Version"
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
##################################################################################################
Check_SEL=$(cat $SUTPATH/Check_SEL.txt)
if [ "$Check_SEL" == y ]; then
	echo
	echo
	echo "Check $name SEL"
	echo
	while true
	do        
	
	ipmitool  sel elist > $SUTPATH/$name/BMC_SEL/BMC_event_$i.log
	if [ "$?" == 0 ]; then
		cp $SUTPATH/$name/BMC_SEL/BMC_event_$i.log $SUTPATH/$name/BMC_SEL/Golden_Sample_SEL_bak.log
		break
	else
		sleep 1
	fi
	done
	
	###################################################################################################
	
	if [ "$i" == 1 ]; then
		
		cat $SUTPATH/$name/BMC_SEL/BMC_event_$i.log | awk -F " " '{print $1}' > $SUTPATH/$name/BMC_SEL/sel_number.log
		echo "" >> $SUTPATH/$name/BMC_SEL/BMC_event_$i.log
		echo "=============== Detail event analysis ===============" >> $SUTPATH/$name/BMC_SEL/BMC_event_$i.log
		echo "" >> $SUTPATH/$name/BMC_SEL/BMC_event_$i.log
		while read sel_line
		do
			ipmitool  sel get 0x$sel_line  >> $SUTPATH/$name/BMC_SEL/BMC_event_$i.log
		done < $SUTPATH/$name/BMC_SEL/sel_number.log
		rm -f $SUTPATH/$name/BMC_SEL/sel_number.log
		
		cat $SUTPATH/$name/BMC_SEL/BMC_event_$i.log
		#cat $SUTPATH/$name/Boot_error/boot.log | grep -i new > /dev/null
		#if [ "$?" == 0 ]; then
		#read -p "Please check the 1st loop SEL, if no question the SEL will be the Golden SEL Sample(y/n): " golden_sel
			#golden_sel=y
			#if [ "$golden_sel" == y ]; then
				#echo $golden_sel > $SUTPATH/$name/chk_sel_sample.log
		cp $SUTPATH/$name/BMC_SEL/Golden_Sample_SEL_bak.log $SUTPATH/$name/BMC_SEL/Golden_Sample_SEL.log
			#else
				
			#fi
		#else
			#echo "Abnormal Boot event log in $SUTPATH/$name/Boot_error/" 
		#fi
	else
		echo " " >  $SUTPATH/$name/BMC_SEL/BMC_sel_fail_tmp.log
		echo "=============== "$i" ===============" >>  $SUTPATH/$name/BMC_SEL/BMC_sel_fail_tmp.log
		echo " " >>  $SUTPATH/$name/BMC_SEL/BMC_sel_fail_tmp.log
		echo "Event Status: " >  $SUTPATH/$name/BMC_SEL/BMC_sel_abnormal_tmp.log 
		while read sel_line_check
		do
			sel_number=$(echo $sel_line_check | awk -F "|" '{print $1}')
			sel_content_1=$(echo $sel_line_check | awk -F "|" '{print $4}')
			sel_content_2=$(echo $sel_line_check | awk -F "|" '{print $5}')
			
			grep "$sel_content_1" $SUTPATH/$name/BMC_SEL/Golden_Sample_SEL.log > /dev/null || grep "$sel_content_2" $SUTPATH/$name/BMC_SEL/Golden_Sample_SEL.log > /dev/null
			if [ "$?" != 0 ]; then
			echo "Abnormal event found" >>  $SUTPATH/$name/BMC_SEL/BMC_sel_abnormal_tmp.log
			#echo ""$sel_number" status=error" >>  BMC_SEL/BMC_sel_fail_tmp.log
			#echo " " >>  BMC_SEL/BMC_sel_fail_tmp.log
			#cat BMC_SEL/BMC_event_$i.log | grep "$sel_number" | grep "$sel_content"
			echo "$sel_line_check" >>  $SUTPATH/$name/BMC_SEL/BMC_sel_fail_tmp.log
			fi
		done < $SUTPATH/$name/BMC_SEL/BMC_event_$i.log
		cat $SUTPATH/$name/BMC_SEL/BMC_sel_fail_tmp.log  >> $SUTPATH/$name/BMC_SEL/BMC_sel_fail.log
		grep -i abnormal $SUTPATH/$name/BMC_SEL/BMC_sel_abnormal_tmp.log > /dev/null
		if [ "$?" == 0 ]; then
			echo 
			echo -e ${RED}
			echo "Detected the extra event in SEL at loop: $i."
			echo
				cat $SUTPATH/$name/BMC_SEL/BMC_sel_fail_tmp.log
			echo
			echo -e ${GREEN}
		else
			echo 
			echo "There is no extra event in SEL."
			echo
			cat $SUTPATH/$name/BMC_SEL/BMC_event_$i.log
			echo
		fi
		rm -f $SUTPATH/$name/BMC_SEL/BMC_sel_abnormal_tmp_1.log
		
		cat $SUTPATH/$name/BMC_SEL/BMC_event_$i.log | awk -F " " '{print $1}' > $SUTPATH/$name/BMC_SEL/sel_number.log
		echo "" >> $SUTPATH/$name/BMC_SEL/BMC_event_$i.log
		echo "=============== Detail event analysis ===============" >> $SUTPATH/$name/BMC_SEL/BMC_event_$i.log
		echo "" >> $SUTPATH/$name/BMC_SEL/BMC_event_$i.log
		while read sel_line
		do
			ipmitool  sel get 0x$sel_line  >> $SUTPATH/$name/BMC_SEL/BMC_event_$i.log
		done < $SUTPATH/$name/BMC_SEL/sel_number.log
		rm -f $SUTPATH/$name/BMC_SEL/sel_number.log
	fi
	echo
	
else	
		
		echo
		echo "No Golden Sample SEL Checked" > $SUTPATH/$name/chk_sel_sample.log
		echo
fi
echo
	###################################################################################################
}

Record_resful_HW_device_scan(){
Check_Restful=$(cat $SUTPATH/Check_Restful.txt)
if [ "$Check_Restful" == "y" ]; then

#cat configuration > Get_Restful_info_tmp.sh
#cat Get_Restful_info.sh >> Get_Restful_info_tmp.sh
#chmod 777 Get_Restful_info_tmp.sh
#./Get_Restful_info_tmp.sh
if [ "$i" == 1 ]; then
	cat $line > $SUTPATH/Get_Restful_info_tmp.sh
	#cat configuration > Get_Restful_info_tmp.sh
	cat $SUTPATH/restful_storage_info.sh >> $SUTPATH/Get_Restful_info_tmp.sh
	chmod 777 $SUTPATH/Get_Restful_info_tmp.sh
	if [ -f "$SUTPATH/Get_Restful_storage_info_tmp.sh" ]; then
		rm -f $SUTPATH/Get_Restful_storage_info_tmp.sh
	fi
	cp $SUTPATH/Get_Restful_info_tmp.sh $SUTPATH/Get_Restful_storage_info_$name.sh
	chmod 777 $SUTPATH/Get_Restful_storage_info_$name.sh
	. $SUTPATH/Get_Restful_storage_info_$name.sh > $SUTPATH/$name/Restful/Storage_info_tmp.log
	cat $SUTPATH/$name/Restful/Storage_info_tmp.log | tail -1 | jq > $SUTPATH/$name/Restful/Storage_info_$i.log
	cp $SUTPATH/$name/Restful/Storage_info_$i.log $SUTPATH/$name/Restful/Storage_info_Golden_Sample.log

	cat $SUTPATH/$line > Get_Restful_info_tmp.sh
	cat $SUTPATH/restful_pcie_info.sh >> $SUTPATH/Get_Restful_info_tmp.sh
	chmod 777 Get_Restful_info_tmp.sh
	if [ -f "$SUTPATH/Get_Restful_pcie_info_tmp.sh" ]; then
		rm -f $SUTPATH/Get_Restful_pcie_info_tmp.sh
	fi
	cp $SUTPATH/Get_Restful_info_tmp.sh $SUTPATH/Get_Restful_pcie_info_$name.sh
	chmod 777 $SUTPATH/Get_Restful_pcie_info_$name.sh
	. $SUTPATH/Get_Restful_pcie_info_$name.sh > $SUTPATH/$name/Restful/PCIe_info_tmp.log
	cat $SUTPATH/$name/Restful/PCIe_info_tmp.log | tail -1 | jq > $SUTPATH/$name/Restful/PCIe_info_$i.log
	cp $SUTPATH/$name/Restful/PCIe_info_$i.log $SUTPATH/$name/Restful/PCIe_info_Golden_Sample.log
	echo
else

	
	. $SUTPATH/Get_Restful_storage_info_$name.sh > $SUTPATH/$name/Restful/Storage_info_tmp.log
	cat $SUTPATH/$name/Restful/Storage_info_tmp.log | tail -1 | jq > $SUTPATH/$name/Restful/Storage_info_$i.log
	. $SUTPATH/Get_Restful_pcie_info_$name.sh > $SUTPATH/$name/Restful/PCIe_info_tmp.log
	cat $SUTPATH/$name/Restful/PCIe_info_tmp.log | tail -1 | jq > $SUTPATH/$name/Restful/PCIe_info_$i.log
	echo

	#echo "=============== "$i" ===============" >  Restful/Restful_fail_tmp_1.log
	#echo " " >>  Restful/Restful_fail_tmp_1.log
##############################################################

if [ -f "$SUTPATH/$name/Restful/Storage_info_fail_tmp.log" ]; then
	rm -f $SUTPATH/$name/Restful/Storage_info_fail_tmp.log
fi
target_file="$SUTPATH/$name/Restful/Storage_info_$i.log"
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
	grep "$restful_storage" $SUTPATH/$name/Restful/Storage_info_Golden_Sample.log > /dev/null
	if [ "$?" == 1 ]; then
			
		echo "Storage: $restful_storage info error" >> $SUTPATH/$name/Restful/Storage_info_fail_tmp.log
		
	else
		continue
	fi
	
fi
done < $target_file
##############################################################
	if [ ! -f "$SUTPATH/$name/Restful/Storage_info_fail_tmp.log" ]; then
		#cat Restful/Storage_info_fail_tmp.log | grep -i error
		#if [ "$?" == 1 ]; then
		echo "Storage information check OK."
	else
		echo "Storage info compare failed"
		echo "=============== "$i" ===============" >> $SUTPATH/$name/Restful/Storage_fail.log
		cat $SUTPATH/$name/Restful/Storage_info_fail_tmp.log >> $SUTPATH/$name/Restful/Storage_fail.log
		echo " " >> $SUTPATH/$name/Restful/Storage_fail.log
		#echo "Detected Storage info error at loop: $boot."
		#cat "$pwd"BMC/Restful/Storage_fail.log >> "$pwd"Restful_Storage_fail.log
	fi
	echo

##############################################################

if [ -f "$SUTPATH/$name/Restful/PCIe_info_fail_tmp.log" ]; then
	rm -f $SUTPATH/$name/Restful/PCIe_info_fail_tmp.log
fi
target_file="$SUTPATH/$name/Restful/PCIe_info_$i.log"
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
	grep "$restful_pcie" $SUTPATH/$name/Restful/PCIe_info_Golden_Sample.log > /dev/null
	if [ "$?" == 1 ]; then
			
		echo "PCIe: $restful_pcie info error" >> $SUTPATH/$name/Restful/PCIe_info_fail_tmp.log
		
	else
		continue
	fi
	
fi
done < $target_file
##############################################################




	if [ ! -f "$SUTPATH/$name/Restful/PCIe_info_fail_tmp.log" ]; then
		#cat Restful/PCIe_info_fail_tmp.log | grep -i error
		#if [ "$?" == 1 ]; then
		echo "PCIe informtion check OK."
	else
		echo "PCIeDevice info compare failed"
		echo "=============== "$i" ===============" >> $SUTPATH/$name/Restful/PCIe_fail.log
		cat $SUTPATH/$name/Restful/PCIe_info_fail_tmp.log >> $SUTPATH/$name/Restful/PCIe_fail.log
		echo " " >> $SUTPATH/$name/Restful/PCIe_fail.log
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
ipmitool  chassis power status > $SUTPATH/$name/system_status.log
cat $SUTPATH/$name/system_status.log | grep -i off
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
local(){
cat $SUTPATH/flow.txt | grep -i setting > /dev/null
if [ "$?" == 0 ]; then

cat $SUTPATH/configuration | grep "sled=" > $SUTPATH/bmcs.txt
echo 1 > $SUTPATH/test.cfg
echo 1 > $SUTPATH/sled_status.txt
rm -f $SUTPATH/*.cfg
rm -f $SUTPATH/sled_status.txt
while read line
do
	number=$(echo $line | awk -F "=" '{print $2}')
#	echo $number
#	echo "cat configuration | grep "sled=$number" -A 3 > sled_$number.cfg"
	cat $SUTPATH/configuration | grep "sled=$number" -A 3 > sled_$number.cfg

done < $SUTPATH/bmcs.txt

ls $SUTPATH/*.cfg > $SUTPATH/target.txt

for iconfig in $(cat $SUTPATH/target.txt)
do
#cat $iconfig
name=$(echo $iconfig | awk -F "." '{print $1}')


if [ -d "$SUTPATH/$name" ]; then
rm -r -f $SUTPATH/$name
fi
mkdir -p {$SUTPATH/$name/Boot_error,$SUTPATH/$name/BMC_SEL,$SUTPATH/$name/BMC_Bank,$SUTPATH/$name/BIOS_Bank,$SUTPATH/$name/Version,$SUTPATH/$name/Restful}


done




###################################################################################################
APC_settings(){
if [ -f $SUTPATH/apc.py ]; then
	rm -f $SUTPATH/apc.py
fi

cp $SUTPATH/apc_v2.py $SUTPATH/apc.py

sed -i "s/i_user/$APC_user/g" $SUTPATH/apc.py
sed -i "s/i_passwd/$APC_password/g" $SUTPATH/apc.py
}

python3 apc.py $APC_IP "$PDUPlug $AC_OFF" offdelay 
python3 apc.py $APC_IP "$PDUPlug $AC_ON" ondelay 

###################################################################################################
if [ -f "$SUTPATH/"$PJN"_AC_power_on_time.log" ]; then
	rm -f $SUTPATH/"$PJN"_AC_power_on_time.log
fi

if [ -f "$SUTPATH/"$PJN"_DC_power_on_time.log" ]; then
	rm -f $SUTPATH/"$PJN"_DC_power_on_time.log
fi


if [ -f "$SUTPATH/BMC_Boot_time.log" ]; then
	rm -f $SUTPATH/BMC_Boot_time.log
fi

if [ -f "$SUTPATH/OS_Boot_time.log" ]; then
	rm -f $SUTPATH/OS_Boot_time.log
fi


cat $SUTPATH/configuration | grep "sled=" > $SUTPATH/bmcs.txt
echo 1 > $SUTPATH/test.cfg
rm -f $SUTPATH/*.cfg
echo 1 > $SUTPATH/sled_status.txt
rm -f $SUTPATH/sled_status.txt
while read line
do
	number=$(echo $line | awk -F "=" '{print $2}')
#	echo $number
#	echo "cat configuration | grep "sled=$number" -A 3 > sled_$number.cfg"
	cat $SUTPATH/configuration | grep "sled=$number" -A 3 > $SUTPATH/sled_$number.cfg

done < $SUTPATH/bmcs.txt

ls $SUTPATH/*.cfg > $SUTPATH/target.txt

## create the parameter
Colorful_script
Test_mode
Set_duration
Set_BMC
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


for line in $(cat $SUTPATH/target.txt)
do
. $line
name=$(echo $line | awk -F "." '{print $1}')
#send_shutdown_event
echo "new boot" > $SUTPATH/$name/Boot_error/boot.log
# ---------------------------------------------------
local_AC(){
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
}

# ---------------------------------------------------
echo $name | grep "1" > /dev/null
if [ "$?" == 0 ]; then
	echo  > /dev/nill
else
	wait_system_off
fi
#for line in $(cat target.txt)
done 

python3 $SUTPATH/apc.py $APC_IP $PDUPlug status
sleep 1
python3 $SUTPATH/apc.py $APC_IP $PDUPlug dlyreboot
echo
echo "System will AC off within 90 seconds."
echo
# ---------- record the time of start ---------------
echo $(($(date +%s)+$TESTTIME)) > /root/AC_FINISH_TIME

# ---------------------------------------------------
echo start > $SUTPATH/flow.txt
	if [ -f $SUTPATH/loop_count.txt ]; then
		rm -f $SUTPATH/loop_count.txt
	fi
exit	
fi
}
# -------------------------------- Start AC cycling ---------------------------------------- #
#for((i=1;i<=1100;i++))
#do
#======================================================================================================1	

. $SUTPATH/configuration
	if [ "$?" != 0 ]; then
		echo "There is no configuration file in $path/"	
			exit
	fi
if [ -f $SUTPATH/keyword.txt ]; then
	rm -f $SUTPATH/keyword.txt
fi

cp $SUTPATH/target.txt $SUTPATH/keyword.txt

if [ -f $SUTPATH/sled_status.txt ]; then
	rm -f $SUTPATH/sled_status.txt
fi

PDUPlugStatus
POS="Status: ON"
AC_OFF=$(cat AC_OFF.time)
AC_ON=$(cat AC_ON.time)

echo 1 >> $SUTPATH/loop_count.txt
i=$(cat $SUTPATH/loop_count.txt | grep "1" -c)
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
		echo setting > $SUTPATH/flow.txt
		for line in $(cat $SUTPATH/target.txt)
		do
			#echo $line
			. $line
			name=$(echo $line | awk -F "." '{print $1}')
			echo "Power on $name"
			finish_AC
		#for line in $(cat target.txt)
		done
		echo
		exit 0
	fi
#======================================================================================================1
#======================================================================================================2
	## cycle base
	CTC=$(cat $SUTPATH/CTC.txt)
	#echo $CTC
	#echo $i
	if [ "$i" -ge "$CTC" ];then
		echo -e ${NC}
		echo
		echo "AC cycling test has been finished."
		echo
		#PDUPlugOn
		echo setting > $SUTPATH/flow.txt
		for line in $(cat $SUTPATH/target.txt)
		do
			#echo $line
			. $line
			name=$(echo $line | awk -F "." '{print $1}')
			echo "Power on $name"
			finish_AC
		#for line in $(cat target.txt)
		done 
		echo		
		exit 0
	fi
	# ------------------------------------------------------
#======================================================================================================2

	echo
		date "+%Y-%m-%d %T" #2>&1 | tee BMC_boot_time_start.log
	echo
	echo
	echo "***** Power on UUT & Test No.$i *****" 2>&1 | tee $SUTPATH/loop_cycle.log
	echo
	echo "PDU power on."
	echo
	echo "No.$i" >> $SUTPATH/"$PJN"_AC_power_on_time.log ;date >> $SUTPATH/"$PJN"_AC_power_on_time.log  #記錄每次開機時間
#======================================================================================================3
	
	for line in $(cat $SUTPATH/target.txt)
	do
	#echo $line
	. $line
	name=$(echo $line | awk -F "." '{print $1}')
	ct=1
	bt=1
	# ---------- check the BMC network connection ----------
	BMCPING="LOCAL_AC" 
	
	echo "Wait for $name BMC booting completed"
	echo
	#PDUPlugStatus
	bmc_number=$(cat target.txt | wc -l)
	bmc_boot=$((60/$bmc_number))
	
	while [ "$BMCPING" == "" ]  # 只要BMCPING的變數值為空白就執行迴圈
	do
		
		
		res_bmc=$(($bt%10))
		if [ "$res_bmc" == 0 ]; then
			echo -n -e "$bt"
		else
			echo -n -e "."
		fi
		let "bt = $bt + 1"
		sleep 1
	
		BMCPING=`ping $ip -c 1 | grep ttl`
		if [ $bt -gt $bmc_boot ]; then  #設置等待時間為180秒
			echo
			PDUPlugStatus
			echo "No. $i testing cycle, cannot connect to BMC network.
			      Therefore, AC power off the UUT via remote side." >> $SUTPATH/$name/Boot_error/"$PJN"_AC_power_on_hang_$name.log
			echo		
			#echo $PDU1
			
			while [ "$PDU1" == "Status: ON" ]
			do
				echo
				echo "Cannot connect to BMC network ，AC off the system."
				echo				
				while true
				do
				python3 $SUTPATH/apc.py $APC_IP $PDUPlug status 2>/dev/null 1> $SUTPATH/APC
				cat $SUTPATH/APC | grep -i success > /dev/null
				if [ "$?" == 0 ]; then
					cat APC
					break
				else
					echo -n -e "."
				fi
				done
				sleep 1

				echo
				while true
				do
				python3 $SUTPATH/apc.py $APC_IP $PDUPlug dlyreboot  2>/dev/null 1> $SUTPATH/APC
				cat $SUTPATH/APC | grep -i success > /dev/null
				if [ "$?" == 0 ]; then
					cat APC
					break
				else
					echo -n -e "."
				fi
				done
				echo
				read -p "System will AC off within $AC_OFF seconds." AC_done
			
			done
			BMCPING=1  #跳脫BMC迴圈
		fi
	done
	#for line in $(cat target.txt)
	done 
	echo
#======================================================================================================3
	echo
		date "+%Y-%m-%d %T" #2>&1 | tee BMC_boot_time_end.log
	echo
	# -------------------------------------------------------
	#bmc_start=$(cat BMC_boot_time_start.log)
	#bmc_end=$(cat BMC_boot_time_end.log)
	#echo "BMC boot start:$bmc_start"
	#echo "BMC end end:$bmc_end"
	#BMC_boots_time=$(($(date -d "$bmc_end" +%s)-$(date -d "$bmc_start" +%s))) 
	#cat loop_cycle.log >> BMC_Boot_time.log
	#echo "BMC boots time: $BMC_boots_time seconds" 2>&1 | tee BMC_Boot_time_tmp.log
	#echo
	#cat BMC_Boot_time_tmp.log >> BMC_Boot_time.log
#======================================================================================================4
	for line in $(cat $SUTPATH/target.txt)
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
	ipmitool  mc info 2>/dev/null 1 > $SUTPATH/ready.log
	i_BMC=$(cat $SUTPATH/ready.log | grep -i version -c)
	echo -n -e "."
	sleep 1
		if [ $i_BMC -gt $bmc_boot ]; then
			echo "No. $i testing cycle, BMC maybe hang up because of BMC has no any response within 180 seconds." >> $SUTPATH/$name/Boot_error/"$PJN"_BMC_hang_$name.log
			echo
				
		fi
	done
	echo
	cat $SUTPATH/ready.log | head -3
	echo
	echo "$name Power status"
	# ---------- check the system is on or off --------------
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
		date "+%Y-%m-%d %T" #2>&1 | tee OS_boot_time_start.log
	echo
#======================================================================================================5
	
	#echo start > $SUTPATH/sled_status.txt
	echo
	echo "Wait for booting into OS"
	echo
	while [ "$PDU1" == "$POS" ]  #while-1
	#while true
	do
	
		echo no > $SUTPATH/cfg_status.txt
		# 當開機狀態下達到600秒就強制斷電
		if [ "$ct" -gt "$wait_boot_time" ]; then #if-1
			if [ "$TESTMODE" == "Debug test" ];then #if-2
				echo "No. $i testing cycle, the UUT test failed."
				exit 0
			else
				
				for line in $(cat $SUTPATH/target.txt) #for-1
				do
				echo "abnormal boot" > $SUTPATH/$name/Boot_error/boot.log
				. $line
				name=$(echo $line | awk -F "." '{print $1}')
				echo "No. $i testing cycle, the system cannot boot to OS within 10 mins. 
			      Therefore, AC power off the UUT via remote side." | tee -a $SUTPATH/$name/Boot_error/"$PJN"_AC_power_on_hang_$name.log
				
				ipmitool  sel list 2>&1 | tee -a $SUTPATH/$name/Boot_error/boot_sel_over10mins_$name-loop_$i.log
				sleep 2
				echo
				#echo "OS boot timeout, force AC OFF within 30 seconds."
				Remote_Check_version
				#echo "line-1171"
				Remote_Check_SEL
				ClearSEL
				echo "new boot" > $SUTPATH/$name/Boot_error/boot.log
				#for line in $(cat target.txt)
				done #for-1-donw
				while [ "$PDU1" == "$POS" ] #while-2
				do
					while true
					do
					python3 $SUTPATH/apc.py $APC_IP $PDUPlug status 2>/dev/null 1> $SUTPATH/APC
					cat $SUTPATH/APC | grep -i success > /dev/null
					if [ "$?" == 0 ]; then
						cat APC
						break
					else
						echo -n -e "."
					fi
					done
				sleep 1

				echo
					while true
					do
					python3 $SUTPATH/apc.py $APC_IP $PDUPlug dlyreboot  2>/dev/null 1> $SUTPATH/APC
					cat $SUTPATH/APC | grep -i success > /dev/null
					if [ "$?" == 0 ]; then
						cat APC
						break
					else
						echo -n -e "."
					fi
					done
					echo
				read -p "System will AC off within $AC_OFF seconds." AC_done
				sleep 10
				exit
				done #while-2-donw
			fi #fi-2
		# 未超過600秒執行以下scrpit
		else
			
			#ct=$((ct+10))  #10秒偵測一次PDU狀態
		cat keyword.txt | grep -i sled > /dev/null
		if [ "$?" == 0 ]; then #if-3
			for line in $(cat $SUTPATH/keyword.txt) #for-2
			do
			#echo "clearSEL: $line"
			. $line
			name=$(echo $line | awk -F "." '{print $1}')
			#echo -n -e $name check
			#cat $line
			#while true
			#do
			
			GetSELKeyWord
			#echo "debug-1"
			#echo $name
			res=$(($ct%10))
			if [ "$res" == 0 ]; then #if-4
				echo -n -e "$ct"
			else
				echo -n -e "."
			fi #if-4-fi
			let "ct = $ct + 1"
			sleep 1
			
			if [ "$SEL1" != "" ];then #if-5
				echo
					
				# -------------------------------------------------------
				Record_resful_HW_device_scan
				Remote_Check_BMC_BIOS_Bank
				Remote_Check_version
				echo
				echo "Getting the $name system logs..."
				echo				
				sleep 1  
				dt=1
				SystemPowerStatus
				# 確認系統是否關機
			echo $name | grep "1" > /dev/null
			if [ "$?" == 0 ]; then #if-6
		 		echo $line >> $SUTPATH/sled_status.txt
				echo
				echo "$name check done."
				echo
				sed -i "/$name/d" $SUTPATH/keyword.txt
			else
				cat $SUTPATH/AC.method | grep "1" > /dev/null
				if [ "$?" == 0 ]; then #if-7
					echo
					echo "Shut down the $name OS now ."
					echo
					echo $line >> $SUTPATH/sled_status.txt
					while [ "$SystemStatus" == "Chassis Power is on" ] #while-3
					do
						res=$(($dt%10))
						if [ "$res" == 0 ]; then #if-8
							echo -n -e "$dt"
						else
							echo -n -e "."
						fi     #fi-8
						let "dt = $dt + 1"
						sleep 1
						SystemPowerStatus
						if [ "$dt" == "$shutdown_time" ]; then #if-9
							echo
							echo
								date
							echo
							echo "No. $i testing cycle, cannot shut dwon the OS within 5 mins. 	
							      Therefore, AC power off the UUT via remote side." | tee -a $SUTPATH/$name/Boot_error/"$PJN"_AC_power_off_hang_$name.log
							ipmitool  sel list | tee -a $SUTPATH/$name/Boot_error/shutdown_over_5mins_SEL_$name-loop_$i.log
							sleep 2
						
							ipmitool  power off
							sleep 10
							SystemPowerStatus
						fi #fi-9
					done #while-3-done
					
					echo				
					Remote_Check_SEL
					echo	
					echo "Clear $name SEL"
					ClearSEL
					sleep 1
					sed -i "/$name/d" $SUTPATH/keyword.txt
				else
					echo "Wait for Force AC off.."
					sed -i "/$name/d" $SUTPATH/keyword.txt
					
				fi #fi-7

			fi #fi-6
			fi #if-5
			done #for-2-done
			else
				echo
				echo "All Sled Check done"
				echo
				break

			
			fi #if-3
			

			#PDUPlugStatus
			#for line in $(cat target.txt)
			#echo yes > $SUTPATH/cfg_status.txt
			
		
			
		fi #if-1	
			#sled_status_check(){			
			if [ -f $SUTPATH/sled_status.txt ]; then
			iline=1
			
			while read line
			do
				
				grep "$line" $SUTPATH/target.txt > /dev/null			
				if [ "$?" == 0 ]; then
					echo $iline > $SUTPATH/check.txt	
				fi
				
				let "iline=$iline+1"
			done < $SUTPATH/sled_status.txt
			cat $SUTPATH/target.txt | wc -l  > $SUTPATH/original.txt
			diff $SUTPATH/original.txt $SUTPATH/check.txt  > /dev/null
			if [ "$?" == 0 ]; then
				rm -f $SUTPATH/sled_status.txt
				break
			fi
			fi
			#}
			
		
		#cat cfg_status.txt | grep yes > /dev/null
		#if [ "$?" == 0 ]; then
		#	break
		#fi
	done #while-1

echo
echo "Remote Sleds check done"
echo
#ipmitool   sel clear
sleep 1
echo

while true
do
	python3 apc.py $APC_IP $PDUPlug dlyreboot  2>/dev/null 1>APC
	cat APC | grep -i success > /dev/null
	if [ "$?" == 0 ]; then
		cat APC
		sleep 2
		echo
		echo "Check APC status"
		echo
		python3 apc.py $APC_IP $PDUPlug status  2>/dev/null 1>APC
		cat APC | grep -i success > /dev/null
		if [ "$?" == 0 ]; then
			cat APC | grep -i "\*"
			if [ "$?" == 0 ]; then
				echo > /dev/null
				break
			fi
		fi 
	else
		echo -n -e "."
		sleep 2
	fi
done
echo
echo "System will AC off within $AC_OFF seconds."
echo
for line in $(cat $SUTPATH/target.txt) 
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

cat AC.method | grep "1" > /dev/null
if  [ "$?" == 0 ]; then
	echo
	echo "Sled #1 will shutdown within 30 seconds."
	echo
	i_off=0
	while [ "$i_off" != 30 ]
	do
		sleep 1
		echo -n -e "."
		let "i_off=$i_off+1"
	done
	echo "Shutdown"
	
else
	echo
	echo "Wait for APC force AC off"
	echo
fi
