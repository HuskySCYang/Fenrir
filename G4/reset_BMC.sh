action=$(cat Loop.conf | grep -i Test_method | awk -F "=" '{print $2}')
if [ "$action" != "AC" ]; then
echo
read -p "Would you want to reset BMC for redfish to initial PCIe and Storage devices: " redfish_scan

if [ "$redfish_scan" == y ]; then
	echo
	echo "Cold reset BMC to initial the PCIe and Storage devices of redfish."
	ipmitool raw 0x06 0x02
	echo
	BMC_ok=0
	while [ "$BMC_ok" != 120 ];
	do
	let "BMC_ok = $BMC_ok + 1"
	sleep 1
	echo -n -e "."
	done
	
	Check_BMC_accessing_OK(){
	echo
	#ipmicmd="ipmitool -I lanplus -H $ip -U $user -P $password "
	#echo $cmd
	i_BMC=0
	echo "Check BMC ready to aceess"
	while true
	do
		ipmitool raw 0x06 0x01 2>/dev/null
		if [ "$?" = 0 ]; then
			echo
			echo "BMC access successfully"
			echo
			#$ipmicmd chassis policy always-on
			break
		else
			sleep 1
			echo -n -e "."
			let "i_BMC=$i_BMC+1"
			if [ "$i_BMC" == 180 ]; then
				echo
				echo "BMC hang up"
				echo
					exit
			fi
		fi
	done
	echo
	}
Check_BMC_accessing_OK

redfish_service(){
	echo "Wait for redfish service ready."
	echo
	while true
	do
	sleep 1	
	redfishtool -r $ip -u $user -p $password -S Always raw GET /redfish/v1/ 2> /dev/null 1> redfish.log
	if [ "$?" == 0 ]; then
		break
	else
		echo -n -e "."
	fi
	done
	echo "redfish service is ready."

}
#redfish_service

fi
else
	echo 
fi


