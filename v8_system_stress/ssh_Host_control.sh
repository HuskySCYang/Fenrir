#!/bin/bash

source configuration


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
cat os_ssh2.log | grep -i "closed by remote host" > /dev/null 
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

echo
PDUPlug_retry=1
echo "PDU Port $PDUPlug status: "
while true
do
	#python3 apc.py $APC_IP $PDUPlug status 2> /dev/null 1> APC.status
	fence_apc -a $APC_IP -l $APC_user -p $APC_password -n $APC_Plug -o status 2> /dev/null 1> APC.status
	cat APC.status | grep -i Status > /dev/null
	if [ "$?" == 0 ]; then
		break
	else
		echo -n -e "."
		sleep 1
		if [ "$PDUPlug_retry" == 10 ]; then
			echo "Fail to control APC, please check APC Username and Password.." 
			exit
		fi
		let "PDUPlug_retry=$PDUPlug_retry+1"
	fi
done
echo


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
echo

APC_Plug_off=1
while true
do
	python3 apc.py $APC_IP $APC_Plug off 2> /dev/null 1> APC.status
	cat APC.status | grep -i off
	if [ "$?" == 0 ]; then
		break
	else
		echo -n -e "."
		sleep 1
		if [ "$APC_Plug_off" == 10 ]; then
			echo "Fail to control APC OFF, please check APC connection.." 
			exit
		fi
		let "PDUPlug_off=$APC_Plug_off+1"
	fi
done
echo


counter_sleep $ac_off_time

echo
echo "APC off port $APC_Plug"
echo  
echo

APC_Plug_on=1
while true
do
	python3 apc.py $APC_IP $APC_Plug on 2> /dev/null 1> APC.status
	cat APC.status | grep -i on
	if [ "$?" == 0 ]; then
		break
	else
		echo -n -e "."
		sleep 1
		if [ "$APC_Plug_on" == 10 ]; then
			echo "Fail to control APC ON, please check APC connection.." 
			exit
		fi
		let "PDUPlug_on=$APC_Plug_on+1"
	fi
done


echo
echo "Wait for target SUT booting done"
echo
counter_sleep 210
echo

echo "Check SUT1 status"
ssh1=1
while true
do
$os_ssh1 "cat /root/script.status" 2>/dev/null 1> os_ssh1.log
cat os_ssh1.log | grep -i done > /dev/null
if [ "$?" == 0 ]; then
	echo 
	echo
	echo "SUT1 AC cycle stress completed !!"
	echo
	      break
fi
cat os_ssh1.log | grep -i ok > /dev/null
if [ "$?" == 0 ]; then
	while true
	do
	$os_ssh1 "echo no > /root/script.status"
	if [ "$?" == 0 ]; then
		break
	fi
	done
	echo
	echo "SUT1 test done. Shutdown SUT1"
	echo
	Shutdown_SUT1
	break
else
	echo -n -e "." 
	sleep 1
	if [  "$ssh1" == 120 ]; then
		echo "SUT1 test interrupt......Check SUT1"
		exit
	fi
	let "ssh1=$ssh1+1"
fi
done


if [ "$os_ip2" != "" ]; then

echo "Check SUT2 status"
ssh2=1
while true
do
$os_ssh2 "cat /root/script.status" 2>/dev/null 1> os_ssh2.log
cat os_ssh2.log | grep -i done > /dev/null
if [ "$?" == 0 ]; then
	echo 
	echo
	echo "SUT2 AC cycle stress completed !!"
	echo
	     break
fi

cat os_ssh2.log | grep -i ok > /dev/null
if [ "$?" == 0 ]; then
	while true
	do
	$os_ssh2 "echo no > /root/script.status"
	if [ "$?" == 0 ]; then
		break
	fi
	done
	echo
	echo "SUT2 test done. Shutdown SUT2"
	echo
	Shutdown_SUT2
	break
else
	echo -n -e "." 
	sleep 1
	if [  "$ssh1" == 120 ]; then
		echo "SUT2 test interrupt......Check SUT2"
		exit
	fi
	let "ssh2=$ssh2+1"
fi
done
fi
echo
echo
done



fi


#DC=====================================================================================
