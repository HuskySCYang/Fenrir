port1=4
port2=7
APC_IP=192.168.2.12


mkdir APC_status

timer_sleep(){
echo
	date
echo
for ((timer1=0; timer1<$1; timer1++))
do 
echo -ne "."
sleep 1
done
echo
	date
echo
}



for ((i=0;i<300;i++))
do
echo ______________________"$i"______________________
echo
echo "Disable APC $port1"
echo
count=0
while true
do
python3 apc_old_v2.py $port1 off
echo
echo "Wait 20 seconds for PSU1 power off: $count"
echo
timer_sleep 20
python3 apc_old_v1_status.py $APC_IP $port1 2>&1 | tee APC_status/status_$port1-$i-off.log
cat APC_status/status_$port1-$i-off.log | grep -i "is OFF" > /dev/null
if [ "$?" == 0 ]; then 
	cat APC_status/status_$port1-$i-off.log
	break
else
	echo -ne "."
	sleep 5
	if [ "$count" == "20" ]; then
		echo
		echo "Can't control APC.."
		echo
			exit
	fi
	let "count=$count+1"
fi
done	

echo
echo
echo "Enable APC $port1"
echo

count=0
while true
do
python3 apc_old_v2.py $port1 on
echo
echo "Wait 20 seconds for PSU1 power on: $count"
echo
timer_sleep 20
python3 apc_old_v1_status.py $APC_IP $port1 2>&1 | tee APC_status/status_$port1-$i-on.log
cat APC_status/status_$port1-$i-on.log | grep -i "is ON" > /dev/null
if [ "$?" == 0 ]; then 
	cat APC_status/status_$port1-$i-on.log
	break
else
	echo -ne "."
	sleep 5
	if [ "$count" == "20" ]; then
		echo
		echo "Can't control APC.."
		echo
			exit
	fi
	let "count=$count+1"
fi
done	
echo

echo
echo "Disable APC $port2"
echo

timer_sleep 20
count=0
while true
do
python3 apc_old_v2.py $port2 off
echo
echo "Wait 20 seconds for PSU0 power off: $count"
echo
python3 apc_old_v1_status.py $APC_IP $port2 2>&1 | tee APC_status/status_$port2-$i-off.log
cat APC_status/status_$port2-$i-off.log | grep -i "is OFF" > /dev/null
if [ "$?" == 0 ]; then 
	cat APC_status/status_$port2-$i-off.log
	break
else
	echo -ne "."
	sleep 5
	if [ "$count" == "20" ]; then
		echo
		echo "Can't control APC.."
		echo
			exit
	fi
	let "count=$count+1"
fi
done	
echo
echo
echo "Enable APC $port2"
echo

timer_sleep 20
count=0
while true
do
python3 apc_old_v2.py $port2 on
echo
echo "Wait 20 seconds for PSU0 power on: $count"
echo
python3 apc_old_v1_status.py $APC_IP $port2 2>&1 | tee APC_status/status_$port2-$i-on.log
cat APC_status/status_$port2-$i-on.log | grep -i "is ON" > /dev/null
if [ "$?" == 0 ]; then 
	cat APC_status/status_$port2-$i-on.log
	break
else
	echo -ne "."
	sleep 5
	if [ "$count" == "20" ]; then
		echo
		echo "Can't control APC.."
		echo
			exit
	fi
	let "count=$count+1"
fi
done	
echo



done


