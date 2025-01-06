lspci -vvv > lspci_tmp.log
vpd_number=$(cat lspci_tmp.log | grep -i vital -c)

if [ "$vpd_number" == "0" ]; then
	echo "No VPD info in System."
else
cat lspci_tmp.log | grep -i vital -A 20 > vpd_target.log
echo 1 > tmp_1.log
echo 1 > temp1.log
	rm -f tmp*.log
	rm -f temp*.log
if [ -f final_vpd.log ]; then
	rm -f final_vpd.log
fi


iline=1
while read line
do	
	echo $line | grep -i vital >/dev/null
	if [ "$?" == 0 ]; then
		echo -ne $iline >> temp1.log
		#echo $line >> tmp_$iline.log
		let "iline=$iline+1"	
	else
		
		echo $line | grep -i -w End >/dev/null
		if [ "$?" == 0 ]; then
		echo -ne "," >> temp1.log 		
		echo  $iline >> temp1.log
		#echo $line >> tmp_$iline.log
		fi		
		let "iline=$iline+1"
		
		 
	fi 	

done < vpd_target.log

{
while read line
do
	echo
	sed -n "$line""p" vpd_target.log
	echo	

done < temp1.log
} 2>&1 | tee vpd_info.log
fi
