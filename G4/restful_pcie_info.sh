
restful_function(){
log_1=restful_tmp.log
tmp_1=session_csrf.sh
tmp_2=restful_tmp.sh
tmp_3=restful_fru_write.sh
echo "Get Session ID and CSRFToken"

res="curl -k -L -X POST 'https://$ip/api/session' -F 'username=$user' -F 'password=$password' -vvv"
echo $res
echo $res > $tmp_1 

chmod 777 $tmp_1

./$tmp_1 2>&1 | tee $log_1

echo
echo 
session=$(cat $log_1 | grep -i QSESSIONID= | awk -F "=" '{print $2}'| awk -F ";" '{print $1}')

echo QSESSIONID=$session


token=$(cat $log_1 | grep -i csrftoken  | awk -F ":" '{print $11}' | awk -F "\"" '{print $2}')
                

echo CSRFToken=$token
}

restful_function
	                               
res="curl -k -L -X GET 'https://$ip/api/host_inventory/host_interface_pcie_device_function_info' -H 'Content-Type: application/json' -H 'Cookie: QSESSIONID=$session' -H 'X-CSRFTOKEN: $token'"

echo $res > $tmp_2

chmod 777 $tmp_2

./$tmp_2
echo


#echo "FRU write"
#gg='"Chassis_Type:"Blade Enclosure"'
##--data-raw '{\"Chassis_Part_Number\": \"Husky474\"}'
#fru='{"Chassis_Part_Number":"12345678","Chassis_Serial_Number":"AA2101315","Board_Product_Name":"ASUS-QTC","Board_Serial_Number":"QTC-12345","Board_Part_Number":"ESBU-12345","Product_Name":"ASUS-ESBU-QTC","Product_Part_Number":"QTC-9876","Product_Version":"00002","Product_Serial_Number":"PAT-987","AssetTag":"3Q-9527"'
#res="curl -k -L -X PUT 'https://$ip/api/oem/fru' -H 'Content-Type: application/json' -H 'Cookie: QSESSIONID=$session' -H 'X-CSRFTOKEN: $token' --data-raw '{$fru}'"




#echo $res > $tmp3

#chmod 777 $tmp3

#./$tmp3
#echo


