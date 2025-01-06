#!/bin/bash

source Host_configuration


counter_sleep(){
echo
	date
echo
counter_off=1
while [ "$counter_off" != $1 ]
do
	echo -n -e "."
	sleep 1
	let "counter_off=$counter_off+1"
done

echo
	date
echo
}
#read -p "Select the stress method: 1:AC, 2: DC, 3: Reboot" stress
echo
echo
read -p "Input the stress cycles: "  cycles
echo
stress=AC
#AC================================================================================
if [ "$stress" = AC ]; then
	echo
	echo "Check the APC status"
	echo
	apc_retry=1
	while true
	do
		ping $APC_IP -c 5 2>&1 | tee ping_ACP.log
		cat ping_ACP.log | grep -i ttl -c | grep 5 > /dev/null
		if [ "$?" == 0 ]; then
			echo
			echo "Connect APC: $APC_IP successfully."
		        break
		else
			echo "Connect to APC retry: $apc_retry"
			if [ "$apc_retry" == 3 ]; then
				echo "Connect to APC fail..."
					exit
			fi
			let "apc_retry=$apc_retry+1"
		fi
	done

echo
Shutdown_SUT1(){

echo "Shutdown target SUT1"
SUT1_retry=1
while true
do
	$os_ssh1 "init 0"  2>&1 | tee os_ssh1.log
	sleep 2
	cat os_ssh1.log | grep -i "closed by remote host" > /dev/null 
	if [ "$?" == 0 ]; then
		echo > /dev/null
			break
	else
		echo "Shutdown SUT1 command retry: $SUT1_retry"
		if [ "$SUT1_retry" == 3 ]; then
			echo "Shutdown SUT1 command fail..."
			exit
		fi
		let "SUT1_retry=$SUT1_retry+1"
	fi
done
counter_sleep 30
}
#Shutdown_SUT1


Shutdown_SUT2(){
if [ "$os_ip2" != "" ]; then
	echo "Shutdown target SUT2"
	SUT2_retry=1
	while true
	do
		$os_ssh2 "init 0" | tee os_ssh2.log
		sleep 2
		cat os_ssh2.log | grep -i "closepython3 apc_old_v1.pyd by remote host" > /dev/null 
		if [ "$?" == 0 ]; then
			echo > /dev/null
				break
		else
			echo "Shutdown SUT2 command retry: $SUT2_retry"
			if [ "$SUT2_retry" == 3 ]; then
				echo "Shutdown SUT2 command fail..."
				exit
			fi
			let "SUT2_retry=$SUT2_retry+1"
		fi
	done
counter_sleep 30
fi

}

#Shutdown_SUT2
check_APC(){
echo
APC_Plug_retry=1
echo "PDU Port $APC_Plug status: "
while true
do
	python3 apc.py $APC_IP $APC_Plug status 2> /dev/null 1> APC.status
	 #python3 apc_old_v1_status.py $APC_IP $APC_Plug 2> /dev/null 1> APC.status
	#fence_apc -a $APC_IP -l $APC_user -p $APC_password -n $APC_Plug -o status 2> /dev/null 1> APC.status
	cat APC.status | grep -i on > /dev/null
	if [ "$?" == 0 ]; then
		cat APC.status
		break
	else
		echo -n -e "."
		sleep 3
		if [ "$APC_Plug_retry" == 30 ]; then
			echo "Fail to control APC, please check APC Username and Password.." 
			exit
		fi
		let "APC_Plug_retry=$APC_Plug_retry+1"
	fi
done
echo
}

for ((i=1; i<$(($cycles+1)); i++))
do
echo
echo ______________________________________"$i"______________________________________
echo
#echo "Wait for OS shutdown completed."
#echo 
#counter_sleep 60
echo "APC off port $APC_Plug"
echo  


APC_Plug_off=1
while true
do
	#fence_apc -a $APC_IP -l $APC_user -p $APC_password -n $APC_Plug -o off 2> /dev/null 1> APC.status
	#python3 apc.py $APC_IP $APC_Plug off 2> /dev/null 1> APC.status
	if [ "$APC_IP" == "192.168.2.12" ]; then
		python3 apc_old_v1.py $APC_Plug off 2> /dev/null 1> APC.status
		#python3 apc_old_v1_status.py $APC_IP $APC_Plug 2> /dev/null 1> APC.status
	else
		python3 apc.py $APC_IP $APC_Plug off 2> /dev/null 1> APC.status
	fi
	 
	cat APC.status | grep -i off
	if [ "$?" == 0 ]; then
		break
	else
		echo -n -e "."
		sleep 2
		if [ "$APC_Plug_off" == 30 ]; then
			echo "Fail to control APC OFF, please check APC connection.." 
			exit
		fi
		let "APC_Plug_off=$APC_Plug_off+1"
	fi
done
echo


counter_sleep $ac_off_time

echo
echo "APC on port $APC_Plug"
echo  

APC_Plug_on=1
while true
do
	#fence_apc -a $APC_IP -l $APC_user -p $APC_password -n $APC_Plug -o on 2> /dev/null 1> APC.status
	#python3 apc.py $APC_IP $APC_Plug on 2> /dev/null 1> APC.status
	if [ "$APC_IP" == "192.168.2.12" ]; then
		python3 apc_old_v1.py $APC_Plug on 2> /dev/null 1> APC.status
		#python3 apc_old_v1_status.py $APC_IP $APC_Plug 2> /dev/null 1> APC.status
	else
		python3 apc.py $APC_IP $APC_Plug on 2> /dev/null 1> APC.status
	fi
	cat APC.status | grep -i on
	if [ "$?" == 0 ]; then
		break
	else
		echo -n -e "."
		sleep 2
		if [ "$APC_Plug_on" == 30 ]; then
			echo "Fail to control APC ON, please check APC connection.." 
			exit
		fi
		let "APC_Plug_on=$APC_Plug_on+1"
	fi
done


echo
echo "Wait for target SUT booting done"
echo
counter_sleep 150


echo "Wait for SUT1 boot done"
ping_os_ip_1=1
while true
do
	ping $os_ip_1 -c 30 2> /dev/null 1> ping_os_1.log
	lan1=$(cat ping_os_1.log | grep -i ttl -c )
	if [ "$lan1" -gt 25 ]; then
		echo
			cat ping_os_1.log | head -5
		echo
		echo "Connect SUT1: $os_ip_1 successfully."
			if [ "$i == $cycles" ]; then
				echo
				echo "SUT1 AC cycle done"
				echo
			fi
		break
	else
		echo "Connect to SUT1 retry: $ping_os_ip_1"
		if [ "$ping_os_ip_1" == 100 ]; then
			echo "Connect to SUT1 fail..."
			exit
		fi
		sleep 3
		let "ping_os_ip_1=$ping_os_ip_1+1"
	fi
echo
	date
echo
done



if [ "$os_ip_2" != "" ]; then
	echo "Wait for SUT2 boot done"
	ping_os_ip_2=1
	while true
	do
		ping $os_ip_2 -c 30 2> /dev/null 1> ping_os_2.log
	lan2=$(cat ping_os_2.log | grep -i ttl -c )
	if [ "$lan2" -gt 25 ]; then
		echo
			cat ping_os_2.log | head -5
			echo
			echo "Connect SUT2: $os_ip_2 successfully."
				if [ "$i == $cycles" ]; then
				echo
				echo "SUT2 AC cycle done"
				echo
				
			fi
				break
		else
			echo "Connect to SUT2 retry: $ping_os_ip_2"
			if [ "$ping_os_ip_2" == 100 ]; then
				echo "Connect to SUT2 fail..."
					exit
			fi
			sleep 3
			let "ping_os_ip_2=$ping_os_ip_2+1"
		fi
	echo
		date
	echo
	done
fi

if [ "$i == $cycles" ]; then
	echo 
else

	echo
	echo "Ready to AC off"
	echo
fi

sleep 10


done

fi
#DC=====================================================================================

echo
echo "SUT AC cycle stress completed."
echo
